import { useState, useEffect } from "react";
import { db, storage } from "../firebase";
import {
  collection,
  addDoc,
  onSnapshot,
  updateDoc,
  deleteDoc,
  doc,
  arrayUnion,
  arrayRemove,
} from "firebase/firestore";
import { getAuth } from "firebase/auth";
import { ref, uploadBytesResumable, getDownloadURL } from "firebase/storage";

export default function ClubsManagement() {
  const [clubs, setClubs] = useState([]);
  // Add to formData state initialization
  const [formData, setFormData] = useState({
    name: "",
    description: "",
    photoUrl: "",
    bannerUrl: "",
    photoFile: null,
    bannerFile: null,
    removePhoto: false, // Add this line
    removeBanner: false, // Add this line
  });

  const [isEditing, setIsEditing] = useState(false);
  const [currentClubId, setCurrentClubId] = useState(null);
  const [uploadProgress, setUploadProgress] = useState(0);
  const [isUploading, setIsUploading] = useState(false);
  const auth = getAuth();

  // Firestore data subscription
  useEffect(() => {
    const unsubscribe = onSnapshot(collection(db, "clubs"), (snapshot) => {
      const clubsData = snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
        isSubscribed:
          doc.data().subscribers?.includes(auth.currentUser?.uid) || false,
      }));
      setClubs(clubsData);
    });
    return () => unsubscribe();
  }, [auth.currentUser?.uid]);

  // Handle file upload
  const uploadFile = async (file, path) => {
    if (!file) return null;

    try {
      setIsUploading(true);
      setUploadProgress(0);

      const storageRef = ref(storage, `${path}/${Date.now()}-${file.name}`);
      const uploadTask = uploadBytesResumable(storageRef, file);

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

      await uploadTask;
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
      let photoUrl = formData.photoUrl;
      let bannerUrl = formData.bannerUrl;

      // Upload photo if file exists
      if (formData.photoFile) {
        photoUrl = await uploadFile(formData.photoFile, "club-photos");
      } else if (formData.removePhoto) {
        photoUrl = ""; // Clear the photo URL if removal flag is set
      }

      // Upload banner if file exists
      if (formData.bannerFile) {
        bannerUrl = await uploadFile(formData.bannerFile, "club-banners");
      } else if (formData.removeBanner) {
        bannerUrl = ""; // Clear the banner URL if removal flag is set
      }

      const clubData = {
        name: formData.name.trim(),
        description: formData.description.trim(),
        photoUrl,
        bannerUrl,
      };

      if (isEditing && currentClubId) {
        // Update existing club
        await updateDoc(doc(db, "clubs", currentClubId), clubData);
      } else {
        // Create new club
        clubData.subscribers = [];
        await addDoc(collection(db, "clubs"), clubData);
      }

      // Reset form
      resetForm();
    } catch (error) {
      alert(
        `Error ${isEditing ? "updating" : "adding"} club: ${error.message}`
      );
    }
  };

  // Initialize edit mode
  const handleEditClick = (club) => {
    setIsEditing(true);
    setCurrentClubId(club.id);

    // Set form data with club details
    setFormData({
      name: club.name || "",
      description: club.description || "",
      photoUrl: club.photoUrl || "",
      bannerUrl: club.bannerUrl || "",
      photoFile: null,
      bannerFile: null,
      removePhoto: false,
      removeBanner: false,
    });

    // Scroll to form
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  // Reset form and exit edit mode
  const resetForm = () => {
    setFormData({
      name: "",
      description: "",
      photoUrl: "",
      bannerUrl: "",
      photoFile: null,
      bannerFile: null,
      removePhoto: false,
      removeBanner: false,
    });
    setIsEditing(false);
    setCurrentClubId(null);
    setUploadProgress(0);
  };

  const handleRemovePhoto = () => {
    setFormData({
      ...formData,
      photoUrl: "",
      removePhoto: true,
    });
  };

  const handleRemoveBanner = () => {
    setFormData({
      ...formData,
      bannerUrl: "",
      removeBanner: true,
    });
  };

  // Delete Club
  const handleDeleteClub = async (clubId) => {
    if (window.confirm("Are you sure you want to delete this club?")) {
      try {
        await deleteDoc(doc(db, "clubs", clubId));

        // If deleting the club that's being edited, reset the form
        if (currentClubId === clubId) {
          resetForm();
        }
      } catch (error) {
        alert(`Error deleting club: ${error.message}`);
      }
    }
  };

  return (
    <div>
      <h1 className="text-3xl font-bold text-college-primary mb-6">
        Clubs Management
      </h1>

      {/* Club Form */}
      <div className="bg-white p-6 rounded-lg shadow-sm mb-8">
        <h2 className="text-xl font-semibold mb-4">
          {isEditing ? "Edit Club" : "Register New Club"}
        </h2>
        <form
          onSubmit={handleSubmit}
          className="grid grid-cols-1 md:grid-cols-2 gap-4"
        >
          <div className="md:col-span-2">
            <label className="block mb-1 font-medium">Club Name:</label>
            <input
              type="text"
              placeholder="Club Name"
              className="p-2 border rounded w-full"
              value={formData.name}
              onChange={(e) =>
                setFormData({ ...formData, name: e.target.value })
              }
              required
            />
          </div>

          <div className="md:col-span-2">
            <label className="block mb-1 font-medium">Description:</label>
            <textarea
              placeholder="Description"
              className="p-2 border rounded w-full"
              rows="3"
              value={formData.description}
              onChange={(e) =>
                setFormData({ ...formData, description: e.target.value })
              }
            />
          </div>

          {/* Club Photo section */}
          <div>
            <label className="block mb-1 font-medium">Club Photo:</label>
            {formData.photoUrl && (
              <div className="mb-2">
                <div className="flex items-center justify-between">
                  <img
                    src={formData.photoUrl}
                    alt="Current photo"
                    className="h-16 w-16 object-cover rounded-full mb-2"
                  />
                  <button
                    type="button"
                    onClick={handleRemovePhoto}
                    className="text-red-600 hover:text-red-800 ml-2 bg-gray-100 rounded-full p-1 w-8 h-8 flex items-center justify-center"
                  >
                    ×
                  </button>
                </div>
                <p className="text-sm text-gray-500">Current photo</p>
              </div>
            )}
            <input
              type="file"
              accept="image/*"
              className="p-2 border rounded w-full"
              onChange={(e) =>
                setFormData({ ...formData, photoFile: e.target.files[0] })
              }
            />
          </div>

          {/* Banner Image section */}
          <div>
            <label className="block mb-1 font-medium">Banner Image:</label>
            {formData.bannerUrl && (
              <div className="mb-2">
                <div className="flex items-center justify-between">
                  <img
                    src={formData.bannerUrl}
                    alt="Current banner"
                    className="h-16 w-full object-cover mb-2"
                  />
                  <button
                    type="button"
                    onClick={handleRemoveBanner}
                    className="text-red-600 hover:text-red-800 ml-2 bg-gray-100 rounded-full p-1 w-8 h-8 flex items-center justify-center"
                  >
                    ×
                  </button>
                </div>
                <p className="text-sm text-gray-500">Current banner</p>
              </div>
            )}
            <input
              type="file"
              accept="image/*"
              className="p-2 border rounded w-full"
              onChange={(e) =>
                setFormData({ ...formData, bannerFile: e.target.files[0] })
              }
            />
          </div>

          {isUploading && (
            <div className="md:col-span-2">
              <div className="w-full bg-gray-200 rounded-full h-2.5">
                <div
                  className="bg-college-primary h-2.5 rounded-full"
                  style={{ width: `${uploadProgress}%` }}
                ></div>
              </div>
              <p className="text-center mt-1">Uploading: {uploadProgress}%</p>
            </div>
          )}

          <div className="md:col-span-2 flex space-x-4">
            <button
              type="submit"
              className="bg-college-primary text-white py-2 px-4 rounded hover:bg-blue-900 flex-grow disabled:opacity-50"
              disabled={isUploading}
            >
              {isUploading
                ? "Uploading..."
                : isEditing
                ? "Save Club"
                : "Register Club"}
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

      {/* Clubs Table */}
      <div className="bg-white rounded-lg shadow-sm overflow-hidden">
        <table className="w-full">
          <thead className="bg-college-secondary">
            <tr>
              <th className="px-6 py-3 text-left">Club Name</th>
              <th className="px-6 py-3 text-left">Description</th>
              <th className="px-6 py-3 text-left">Photo</th>
              <th className="px-6 py-3 text-left">Banner</th>
              <th className="px-6 py-3 text-left">Subscribers</th>
              <th className="px-6 py-3 text-left">Actions</th>
            </tr>
          </thead>
          <tbody>
            {clubs.map((club) => (
              <tr key={club.id} className="border-b">
                <td className="px-6 py-4">{club.name}</td>
                <td className="px-6 py-4">
                  {club.description || "No description"}
                </td>
                <td className="px-6 py-4">
                  {club.photoUrl ? (
                    <img
                      src={club.photoUrl}
                      alt="Club"
                      className="h-10 w-10 rounded-full object-cover"
                    />
                  ) : (
                    "No photo"
                  )}
                </td>
                <td className="px-6 py-4">
                  {club.bannerUrl ? (
                    <img
                      src={club.bannerUrl}
                      alt="Banner"
                      className="h-10 w-20 object-cover"
                    />
                  ) : (
                    "No banner"
                  )}
                </td>
                <td className="px-6 py-4">{club.subscribers?.length || 0}</td>
                <td className="px-6 py-4 space-x-2">
                  <button
                    onClick={() => handleEditClick(club)}
                    className="text-blue-600 hover:text-blue-800"
                  >
                    Edit
                  </button>
                  <button
                    onClick={() => handleDeleteClub(club.id)}
                    className="text-red-600 hover:text-red-800"
                  >
                    Delete
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
