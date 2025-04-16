import React, { useState, useEffect } from "react";
import { db } from "../firebase";
import {
  collection,
  addDoc,
  onSnapshot,
  updateDoc,
  deleteDoc,
  doc,
  GeoPoint,
} from "firebase/firestore";
import { getAuth } from "firebase/auth";
import { ref, uploadBytesResumable, getDownloadURL } from "firebase/storage";
import { storage } from "../firebase";
import { GoogleMap, Marker, useJsApiLoader } from "@react-google-maps/api";

export default function EventManagement() {
  const [events, setEvents] = useState([]);
  const [clubs, setClubs] = useState([]);
  const [formData, setFormData] = useState({
    name: "",
    description: "",
    organizerId: "",
    organizingBody: "",
    location: "",
    dateTime: "",
    posterFile: null,
    posterUrl: "",
    coordinates: { lat: "", lng: "" },
    attendees: [],
    removePoster: false,
  });

  // Set IIT Indore coordinates as default
  const IIT_INDORE_COORDS = { lat: 22.5203, lng: 75.9207 };

  // Load Google Maps API
  const { isLoaded } = useJsApiLoader({
    id: "google-map-script",
    googleMapsApiKey: import.meta.env.VITE_MAPS_API_KEY,
  });

  const [map, setMap] = useState(null);
  const [selectedLocation, setSelectedLocation] = useState(null);

  const [isEditing, setIsEditing] = useState(false);
  const [currentEventId, setCurrentEventId] = useState(null);
  const [uploadProgress, setUploadProgress] = useState(0);
  const [isUploading, setIsUploading] = useState(false);

  const auth = getAuth();

  // Fetch clubs for the dropdown
  useEffect(() => {
    const unsubscribe = onSnapshot(collection(db, "clubs"), (snapshot) => {
      const clubsData = snapshot.docs.map((doc) => ({
        id: doc.id,
        name: doc.data().name,
      }));
      setClubs(clubsData);
    });
    return () => unsubscribe();
  }, []);

  // Firestore data subscription for events
  useEffect(() => {
    const unsubscribe = onSnapshot(collection(db, "events"), (snapshot) => {
      const eventsData = snapshot.docs.map((doc) => {
        const data = doc.data();
        return {
          id: doc.id,
          ...data,
          dateTime: data.dateTime?.toDate(),
          coordinates: data.coordinates
            ? new GeoPoint(
                data.coordinates.latitude,
                data.coordinates.longitude
              )
            : null,
        };
      });
      setEvents(eventsData);
    });
    return () => unsubscribe();
  }, []);

  const onMapLoad = React.useCallback((map) => {
    setMap(map);
  }, []);

  // Handle map click to set marker
  const onMapClick = React.useCallback((e) => {
    const lat = e.latLng.lat();
    const lng = e.latLng.lng();

    setSelectedLocation({ lat, lng });

    // Update form data with new coordinates
    setFormData((prev) => ({
      ...prev,
      coordinates: {
        lat: lat.toString(),
        lng: lng.toString(),
      },
    }));
  }, []);

  // Clear map when unmounting
  const onUnmount = React.useCallback(() => {
    setMap(null);
  }, []);

  // Handle organizing body change
  const handleOrganizingBodyChange = (e) => {
    const selectedClubId = e.target.value;
    setFormData({
      ...formData,
      organizerId: selectedClubId,
      organizingBody: selectedClubId,
    });
  };

  // Handle file upload
  const uploadFile = async (file) => {
    if (!file) return null;

    try {
      setIsUploading(true);
      setUploadProgress(0);

      // 1. Create storage reference
      const storageRef = ref(
        storage,
        `event-posters/${Date.now()}-${file.name}`
      );

      // 2. Start upload
      const uploadTask = uploadBytesResumable(storageRef, file);

      // 3. Track progress
      uploadTask.on(
        "state_changed",
        (snapshot) => {
          const progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
          setUploadProgress(Math.round(progress));
        },
        (error) => {
          console.error("Upload error:", error);
          throw error;
        }
      );

      // 4. Wait for upload to complete
      await uploadTask;

      // 5. Get download URL
      return await getDownloadURL(uploadTask.snapshot.ref);
    } catch (error) {
      console.error("Upload failed:", error);
      throw error;
    } finally {
      setIsUploading(false);
    }
  };

  // Handle form submission (both add and edit)
  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      let posterUrl = formData.posterUrl;

      // Upload poster if file exists
      if (formData.posterFile) {
        posterUrl = await uploadFile(formData.posterFile);
      } else if (formData.removePoster) {
        posterUrl = "";
      }

      const eventData = {
        name: formData.name,
        description: formData.description,
        organizerId: formData.organizerId,
        location: formData.location,
        dateTime: new Date(formData.dateTime),
        posterUrl,
      };

      if (formData.coordinates.lat != "" && formData.coordinates.lng != "") {
        eventData.coordinates = new GeoPoint(
          parseFloat(formData.coordinates.lat),
          parseFloat(formData.coordinates.lng)
        );
      }

      if (isEditing && currentEventId) {
        // Update existing event
        await updateDoc(doc(db, "events", currentEventId), eventData);
      } else {
        // Create new event
        if (!eventData.organizerId) {
          eventData.organizerId = auth.currentUser?.uid || "";
        }
        eventData.attendees = [];
        await addDoc(collection(db, "events"), eventData);
      }

      // Reset form
      resetForm();
    } catch (error) {
      console.error(`Error ${isEditing ? "updating" : "adding"} event:`, error);
      alert(
        `Error ${isEditing ? "updating" : "adding"} event: ${error.message}`
      );
    }
  };

  // Initialize edit mode
  const handleEditClick = (event) => {
    setIsEditing(true);
    setCurrentEventId(event.id);

    // Format dateTime for datetime-local input
    const formattedDateTime = event.dateTime
      ? new Date(event.dateTime).toISOString().slice(0, 16)
      : "";

    // If event has coordinates, set the selected location
    if (event.coordinates) {
      setSelectedLocation({
        lat: event.coordinates.latitude,
        lng: event.coordinates.longitude,
      });
    } else {
      setSelectedLocation(null);
    }

    // Set form data with event details
    setFormData({
      name: event.name || "",
      description: event.description || "",
      organizerId: event.organizerId || "",
      organizingBody: event.organizerId || "",
      location: event.location || "",
      dateTime: formattedDateTime,
      posterFile: null,
      posterUrl: event.posterUrl || "",
      removePoster: false,
      coordinates: {
        lat: event.coordinates?.latitude.toString() || "",
        lng: event.coordinates?.longitude.toString() || "",
      },
      attendees: event.attendees || [],
    });

    // Scroll to form
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  // Reset form and exit edit mode
  const resetForm = () => {
    setFormData({
      name: "",
      description: "",
      organizerId: "",
      organizingBody: "",
      location: "",
      dateTime: "",
      posterFile: null,
      posterUrl: "",
      coordinates: { lat: "", lng: "" },
      attendees: [],
      removePoster: false,
    });
    setIsEditing(false);
    setCurrentEventId(null);
    setUploadProgress(0);
    setSelectedLocation(null);
  };

  const handleRemovePoster = () => {
    setFormData({
      ...formData,
      posterUrl: "",
      removePoster: true,
    });
  };

  // Delete Event
  const handleDeleteEvent = async (eventId) => {
    if (window.confirm("Are you sure you want to delete this event?")) {
      try {
        await deleteDoc(doc(db, "events", eventId));

        // If deleting the event that's being edited, reset the form
        if (currentEventId === eventId) {
          resetForm();
        }
      } catch (error) {
        alert("Error deleting event: " + error.message);
      }
    }
  };

  return (
    <div>
      <h1 className="text-3xl font-bold text-college-primary mb-6">
        Event Management
      </h1>

      {/* Event Form */}
      <div className="bg-white p-6 rounded-lg shadow-sm mb-8">
        <h2 className="text-xl font-semibold mb-4">
          {isEditing ? "Edit Event" : "Create New Event"}
        </h2>
        <form onSubmit={handleSubmit} className="grid grid-cols-2 gap-4">
          <input
            type="text"
            placeholder="Event Name"
            className="p-2 border rounded"
            value={formData.name}
            onChange={(e) => setFormData({ ...formData, name: e.target.value })}
            required
          />
          <input
            type="datetime-local"
            className="p-2 border rounded"
            value={formData.dateTime}
            onChange={(e) =>
              setFormData({ ...formData, dateTime: e.target.value })
            }
            required
          />
          <input
            type="text"
            placeholder="Location"
            className="p-2 border rounded"
            value={formData.location}
            onChange={(e) =>
              setFormData({ ...formData, location: e.target.value })
            }
            required
          />
          <select
            className="p-2 border rounded"
            value={formData.organizingBody}
            onChange={handleOrganizingBodyChange}
            required
          >
            <option value="">Select Organizing Body</option>
            {clubs.map((club) => (
              <option key={club.id} value={club.id}>
                {club.name}
              </option>
            ))}
          </select>

          <div className="col-span-2">
            <label className="block mb-1">Event Poster:</label>
            {formData.posterUrl && (
              <div className="mb-2">
                <div className="flex items-center justify-between">
                  <img
                    src={formData.posterUrl}
                    alt="Current poster"
                    className="h-20 object-cover mb-2"
                  />
                  <button
                    type="button"
                    onClick={handleRemovePoster}
                    className="text-red-600 hover:text-red-800 ml-2 bg-gray-100 rounded-full p-1 w-8 h-8 flex items-center justify-center"
                  >
                    ×
                  </button>
                </div>
                <p className="text-sm text-gray-500">Current poster</p>
              </div>
            )}
            <input
              type="file"
              accept="image/*"
              className="p-2 border rounded w-full"
              onChange={(e) =>
                setFormData({
                  ...formData,
                  posterFile: e.target.files[0],
                })
              }
            />
            {isUploading && (
              <div className="w-full bg-gray-200 rounded-full h-2.5 mt-2">
                <div
                  className="bg-college-primary h-2.5 rounded-full"
                  style={{ width: `${uploadProgress}%` }}
                ></div>
              </div>
            )}
          </div>

          <div className="col-span-2">
            <label className="block text-sm font-medium mb-2">
              Location on Map:
            </label>

            {isLoaded ? (
              <div className="h-64 w-full mb-4 border rounded overflow-hidden">
                <GoogleMap
                  mapContainerStyle={{ width: "100%", height: "100%" }}
                  center={selectedLocation || IIT_INDORE_COORDS}
                  zoom={selectedLocation ? 15 : 13}
                  onClick={onMapClick}
                  onLoad={onMapLoad}
                  onUnmount={onUnmount}
                >
                  {selectedLocation && (
                    <Marker
                      position={selectedLocation}
                      draggable={true}
                      onDragEnd={(e) => {
                        const lat = e.latLng.lat();
                        const lng = e.latLng.lng();
                        setSelectedLocation({ lat, lng });
                        setFormData((prev) => ({
                          ...prev,
                          coordinates: {
                            lat: lat.toString(),
                            lng: lng.toString(),
                          },
                        }));
                      }}
                    />
                  )}
                </GoogleMap>
              </div>
            ) : (
              <div className="h-64 w-full flex items-center justify-center bg-gray-100 border rounded">
                Loading Map...
              </div>
            )}

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-xs text-gray-500 mb-1">
                  Latitude:
                </label>
                <input
                  type="text"
                  placeholder="Latitude"
                  className="p-2 border rounded w-full bg-gray-50"
                  value={formData.coordinates.lat}
                  onChange={(e) =>
                    setFormData({
                      ...formData,
                      coordinates: {
                        ...formData.coordinates,
                        lat: e.target.value,
                      },
                    })
                  }
                  readOnly
                />
              </div>
              <div>
                <label className="block text-xs text-gray-500 mb-1">
                  Longitude:
                </label>
                <input
                  type="text"
                  placeholder="Longitude"
                  className="p-2 border rounded w-full bg-gray-50"
                  value={formData.coordinates.lng}
                  onChange={(e) =>
                    setFormData({
                      ...formData,
                      coordinates: {
                        ...formData.coordinates,
                        lng: e.target.value,
                      },
                    })
                  }
                  readOnly
                />
              </div>
            </div>

            <div className="mt-2 text-sm">
              <button
                type="button"
                className="text-blue-600 underline"
                onClick={() => {
                  setSelectedLocation(IIT_INDORE_COORDS);
                  setFormData((prev) => ({
                    ...prev,
                    coordinates: {
                      lat: IIT_INDORE_COORDS.lat.toString(),
                      lng: IIT_INDORE_COORDS.lng.toString(),
                    },
                  }));
                }}
              >
                Reset to IIT Indore
              </button>
            </div>
          </div>

          <textarea
            placeholder="Description"
            className="p-2 border rounded col-span-2"
            rows="3"
            value={formData.description}
            onChange={(e) =>
              setFormData({ ...formData, description: e.target.value })
            }
          />
          <div className="col-span-2 flex space-x-4">
            <button
              type="submit"
              className="bg-college-primary text-white py-2 px-4 rounded hover:bg-blue-900 flex-grow"
              disabled={isUploading}
            >
              {isUploading
                ? "Uploading..."
                : isEditing
                ? "Save Event"
                : "Create Event"}
            </button>
            {isEditing && (
              <button
                type="button"
                onClick={resetForm}
                className="bg-gray-500 text-white py-2 px-4 rounded hover:bg-gray-600"
              >
                Cancel
              </button>
            )}
          </div>
        </form>
      </div>

      {/* Events Table */}
      <div className="bg-white rounded-lg shadow-sm overflow-hidden">
        <table className="w-full">
          <thead className="bg-college-secondary">
            <tr>
              <th className="px-6 py-3 text-left">Event Name</th>
              <th className="px-6 py-3 text-left">Date & Time</th>
              <th className="px-6 py-3 text-left">Location</th>
              <th className="px-6 py-3 text-left">Organizer</th>
              <th className="px-6 py-3 text-left">Poster</th>
              <th className="px-6 py-3 text-left">Attendees</th>
              <th className="px-6 py-3 text-left">Actions</th>
            </tr>
          </thead>
          <tbody>
            {events.map((event) => {
              const organizer = clubs.find((club) => club.id === event.organizerId);
              return (
                <tr key={event.id} className="border-b">
                  <td className="px-6 py-4">{event.name}</td>
                  <td className="px-6 py-4">
                    {event.dateTime?.toLocaleString()}
                  </td>
                  <td className="px-6 py-4">{event.location}</td>
                  <td className="px-6 py-4">{organizer?.name || "Unknown"}</td>
                  <td className="px-6 py-4">
                    {event.posterUrl ? (
                      <img
                        src={event.posterUrl}
                        alt="Event poster"
                        className="h-10 w-10 object-cover"
                      />
                    ) : (
                      "No poster"
                    )}
                  </td>
                  <td className="px-6 py-4">{event.attendees?.length || 0}</td>
                  <td className="px-6 py-4 space-x-2">
                    <button
                      onClick={() => handleEditClick(event)}
                      className="text-blue-600 hover:text-blue-800"
                    >
                      Edit
                    </button>
                    <button
                      onClick={() => handleDeleteEvent(event.id)}
                      className="text-red-600 hover:text-red-800"
                    >
                      Delete
                    </button>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}