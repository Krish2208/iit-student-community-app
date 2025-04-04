import { useState, useEffect } from 'react';
import { db } from '../firebase';  // Only import db from firebase.js
import { 
  collection, 
  addDoc, 
  onSnapshot, 
  updateDoc, 
  deleteDoc, 
  doc, 
  arrayUnion, 
  arrayRemove,
  GeoPoint
} from 'firebase/firestore';
import { getAuth } from 'firebase/auth';

// CORRECT STORAGE IMPORTS:
import { 
  ref, 
  uploadBytesResumable,  // This comes from storage
  getDownloadURL 
} from 'firebase/storage';
import { storage } from '../firebase';  // Import storage instance

export default function EventManagement() {
  const [events, setEvents] = useState([]);
  const [newEvent, setNewEvent] = useState({
    name: '',
    description: '',
    organizerId: '',
    location: '',
    dateTime: '',
    posterFile: null,
    coordinates: { lat: '', lng: '' },
    attendees: []
  });

  const [editingEventId, setEditingEventId] = useState(null);
  const [editedEvent, setEditedEvent] = useState({
    name: '',
    description: '',
    organizerId: '',
    location: '',
    dateTime: '',
    posterFile: null,
    posterUrl: '',
    coordinates: { lat: '', lng: '' },
    attendees: []
  });

  const [uploadProgress, setUploadProgress] = useState(0);
  const [isUploading, setIsUploading] = useState(false);

  const auth = getAuth();

  // Firestore data subscription
  useEffect(() => {
    const unsubscribe = onSnapshot(collection(db, 'events'), (snapshot) => {
      const eventsData = snapshot.docs.map(doc => {
        const data = doc.data();
        return {
          id: doc.id,
          ...data,
          dateTime: data.dateTime?.toDate(),
          coordinates: data.coordinates 
            ? { 
                lat: data.coordinates.latitude, 
                lng: data.coordinates.longitude 
              }
            : null
        };
      });
      setEvents(eventsData);
    });
    return () => unsubscribe();
  }, []);

  // Handle file upload
  const uploadFile = async (file) => {
    if (!file) return null;
  
    try {
      setIsUploading(true);
      setUploadProgress(0);
      
      // 1. Create storage reference
      const storageRef = ref(storage, `event-posters/${Date.now()}-${file.name}`);
      
      // 2. Start upload
      const uploadTask = uploadBytesResumable(storageRef, file);
      
      // 3. Track progress
      uploadTask.on('state_changed',
        (snapshot) => {
          const progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
          setUploadProgress(Math.round(progress));
        },
        (error) => {
          console.error('Upload error:', error);
          throw error;
        }
      );
      
      // 4. Wait for upload to complete
      await uploadTask;
      
      // 5. Get download URL
      return await getDownloadURL(uploadTask.snapshot.ref);
      
    } catch (error) {
      console.error('Upload failed:', error);
      throw error;
    } finally {
      setIsUploading(false);
    }
  };

  // Add Event
  const handleAddEvent = async (e) => {
    e.preventDefault();
    try {
      let posterUrl = '';
      
      // Upload poster if file exists
      if (newEvent.posterFile) {
        posterUrl = await uploadFile(newEvent.posterFile);
      }

      // Validate coordinates
      const hasCoordinates = newEvent.coordinates.lat && newEvent.coordinates.lng;
      const coordinates = hasCoordinates
        ? new GeoPoint(
            Number(newEvent.coordinates.lat),
            Number(newEvent.coordinates.lng)
          )
        : null;

      const eventData = {
        name: newEvent.name,
        description: newEvent.description,
        organizerId: auth.currentUser?.uid || '',
        location: newEvent.location,
        dateTime: new Date(newEvent.dateTime),
        posterUrl,
        coordinates,
        attendees: []
      };

      await addDoc(collection(db, 'events'), eventData);
      
      // Reset form
      setNewEvent({ 
        name: '',
        description: '',
        organizerId: '',
        location: '',
        dateTime: '',
        posterFile: null,
        coordinates: { lat: '', lng: '' },
        attendees: []
      });
      setUploadProgress(0);
    } catch (error) {
      console.error('Error adding event:', error);
      alert(`Error adding event: ${error.message}`);
    }
  };

  // Edit Event - Initialize edit mode
  const handleEditClick = (event) => {
    setEditingEventId(event.id);
    setEditedEvent({
      ...event,
      dateTime: event.dateTime?.toISOString().slice(0, 16), // Format for datetime-local input
      coordinates: event.coordinates || { lat: '', lng: '' },
      posterFile: null,
      posterUrl: event.posterUrl || ''
    });
  };

  // Save Edited Event
  const handleSaveEdit = async () => {
    if (!editingEventId) return;
  
    try {
      let posterUrl = editedEvent.posterUrl;
      
      // Upload new poster if file exists
      if (editedEvent.posterFile) {
        posterUrl = await uploadFile(editedEvent.posterFile);
      }
  
      // Validate all required fields
      const updateData = {
        name: editedEvent.name || '', // Fallback to empty string if undefined
        description: editedEvent.description || '', // Fallback to empty string
        location: editedEvent.location || '',
        dateTime: editedEvent.dateTime ? new Date(editedEvent.dateTime) : new Date(),
        posterUrl: posterUrl || '',
        coordinates: editedEvent.coordinates || null
      };
  
      // Remove undefined fields
      Object.keys(updateData).forEach(key => {
        if (updateData[key] === undefined) {
          delete updateData[key];
        }
      });
  
      const eventRef = doc(db, 'events', editingEventId);
      await updateDoc(eventRef, updateData);
      
      setEditingEventId(null);
    } catch (error) {
      console.error('Error updating event:', error);
      alert(`Error updating event: ${error.message}`);
    }
  };

  // Cancel Editing
  const handleCancelEdit = () => {
    setEditingEventId(null);
  };

  // Delete Event
  const handleDeleteEvent = async (eventId) => {
    try {
      await deleteDoc(doc(db, 'events', eventId));
    } catch (error) {
      alert('Error deleting event: ' + error.message);
    }
  };

  // Toggle Attendance
  const handleToggleAttendance = async (eventId, currentAttendees) => {
    const userId = auth.currentUser?.uid;
    if (!userId) return;

    try {
      const eventRef = doc(db, 'events', eventId);
      const isAttending = currentAttendees.includes(userId);

      if (isAttending) {
        await updateDoc(eventRef, {
          attendees: arrayRemove(userId)
        });
      } else {
        await updateDoc(eventRef, {
          attendees: arrayUnion(userId)
        });
      }
    } catch (error) {
      alert('Error updating attendance: ' + error.message);
    }
  };

  return (
    <div>
      <h1 className="text-3xl font-bold text-college-primary mb-6">Event Management</h1>

      {/* Add Event Form */}
      <div className="bg-white p-6 rounded-lg shadow-sm mb-8">
        <h2 className="text-xl font-semibold mb-4">Create New Event</h2>
        <form onSubmit={handleAddEvent} className="grid grid-cols-2 gap-4">
          <input
            type="text"
            placeholder="Event Name"
            className="p-2 border rounded"
            value={newEvent.name}
            onChange={(e) => setNewEvent({ ...newEvent, name: e.target.value })}
            required
          />
          <input
            type="datetime-local"
            className="p-2 border rounded"
            value={newEvent.dateTime}
            onChange={(e) => setNewEvent({ ...newEvent, dateTime: e.target.value })}
            required
          />
          <input
            type="text"
            placeholder="Location"
            className="p-2 border rounded"
            value={newEvent.location}
            onChange={(e) => setNewEvent({ ...newEvent, location: e.target.value })}
            required
          />
          <div className="col-span-2">
            <label className="block mb-1">Event Poster:</label>
            <input
              type="file"
              accept="image/*"
              className="p-2 border rounded w-full"
              onChange={(e) => setNewEvent({ 
                ...newEvent, 
                posterFile: e.target.files[0] 
              })}
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
          <div className="col-span-2 grid grid-cols-2 gap-4">
            <input
              type="number"
              placeholder="Latitude"
              className="p-2 border rounded"
              value={newEvent.coordinates.lat}
              onChange={(e) => setNewEvent({ 
                ...newEvent, 
                coordinates: { ...newEvent.coordinates, lat: e.target.value } 
              })}
              step="any"
            />
            <input
              type="number"
              placeholder="Longitude"
              className="p-2 border rounded"
              value={newEvent.coordinates.lng}
              onChange={(e) => setNewEvent({ 
                ...newEvent, 
                coordinates: { ...newEvent.coordinates, lng: e.target.value } 
              })}
              step="any"
            />
          </div>
          <textarea
            placeholder="Description"
            className="p-2 border rounded col-span-2"
            rows="3"
            value={newEvent.description}
            onChange={(e) => setNewEvent({ ...newEvent, description: e.target.value })}
          />
          <button
            type="submit"
            className="col-span-2 bg-college-primary text-white py-2 px-4 rounded hover:bg-blue-900"
            disabled={isUploading}
          >
            {isUploading ? 'Uploading...' : 'Create Event'}
          </button>
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
              <th className="px-6 py-3 text-left">Poster</th>
              <th className="px-6 py-3 text-left">Attendees</th>
              <th className="px-6 py-3 text-left">Actions</th>
            </tr>
          </thead>
          <tbody>
            {events.map((event) => (
              <tr key={event.id} className="border-b">
                <td className="px-6 py-4">
                  {editingEventId === event.id ? (
                    <input
                      type="text"
                      value={editedEvent.name}
                      onChange={(e) => setEditedEvent({...editedEvent, name: e.target.value})}
                      className="p-1 border rounded w-full"
                      required
                    />
                  ) : (
                    event.name
                  )}
                </td>
                <td className="px-6 py-4">
                  {editingEventId === event.id ? (
                    <input
                      type="datetime-local"
                      value={editedEvent.dateTime}
                      onChange={(e) => setEditedEvent({...editedEvent, dateTime: e.target.value})}
                      className="p-1 border rounded"
                      required
                    />
                  ) : (
                    event.dateTime?.toLocaleString()
                  )}
                </td>
                <td className="px-6 py-4">
                  {editingEventId === event.id ? (
                    <input
                      type="text"
                      value={editedEvent.location}
                      onChange={(e) => setEditedEvent({...editedEvent, location: e.target.value})}
                      className="p-1 border rounded w-full"
                      required
                    />
                  ) : (
                    event.location
                  )}
                </td>
                <td className="px-6 py-4">
                  {editingEventId === event.id ? (
                    <div>
                      {editedEvent.posterUrl && (
                        <img 
                          src={editedEvent.posterUrl} 
                          alt="Current poster" 
                          className="h-10 w-10 object-cover mb-2"
                        />
                      )}
                      <input
                        type="file"
                        accept="image/*"
                        className="p-1 border rounded text-xs"
                        onChange={(e) => setEditedEvent({
                          ...editedEvent,
                          posterFile: e.target.files[0]
                        })}
                      />
                    </div>
                  ) : (
                    event.posterUrl ? (
                      <img src={event.posterUrl} alt="Event poster" className="h-10 w-10 object-cover" />
                    ) : (
                      'No poster'
                    )
                  )}
                </td>
                <td className="px-6 py-4">
                  {event.attendees?.length || 0}
                  {auth.currentUser && (
                    <button
                      onClick={() => handleToggleAttendance(event.id, event.attendees || [])}
                      className={`ml-2 px-2 py-1 rounded text-xs ${
                        event.attendees?.includes(auth.currentUser.uid) 
                          ? 'bg-red-100 text-red-800' 
                          : 'bg-green-100 text-green-800'
                      }`}
                    >
                      {event.attendees?.includes(auth.currentUser.uid) ? 'Leave' : 'Join'}
                    </button>
                  )}
                </td>
                <td className="px-6 py-4 space-x-2">
                  {editingEventId === event.id ? (
                    <>
                      <button
                        onClick={handleSaveEdit}
                        className="text-green-600 hover:text-green-800"
                      >
                        Save
                      </button>
                      <button
                        onClick={handleCancelEdit}
                        className="text-gray-600 hover:text-gray-800"
                      >
                        Cancel
                      </button>
                    </>
                  ) : (
                    <>
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
                    </>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}