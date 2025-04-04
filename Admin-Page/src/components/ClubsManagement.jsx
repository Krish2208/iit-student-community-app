import { useState, useEffect } from 'react';
import { db, storage } from '../firebase';
import { collection, addDoc, onSnapshot, updateDoc, deleteDoc, doc, arrayUnion, arrayRemove } from 'firebase/firestore';
import { getAuth } from 'firebase/auth';
import { ref, uploadBytesResumable, getDownloadURL } from 'firebase/storage';

export default function ClubsManagement() {
  const [clubs, setClubs] = useState([]);
  const [newClub, setNewClub] = useState({
    name: '',
    description: '',
    photoUrl: '',
    bannerUrl: '',
    subscribers: [],
    photoFile: null,
    bannerFile: null
  });

  const [editingClubId, setEditingClubId] = useState(null);
  const [editedClub, setEditedClub] = useState({
    name: '',
    description: '',
    photoUrl: '',
    bannerUrl: '',
    subscribers: [],
    photoFile: null,
    bannerFile: null
  });

  const [uploadProgress, setUploadProgress] = useState(0);
  const [isUploading, setIsUploading] = useState(false);
  const auth = getAuth();

  // Firestore data subscription
  useEffect(() => {
    const unsubscribe = onSnapshot(collection(db, 'clubs'), (snapshot) => {
      const clubsData = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
        isSubscribed: doc.data().subscribers?.includes(auth.currentUser?.uid) || false
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
      
      await uploadTask;
      return await getDownloadURL(uploadTask.snapshot.ref);
    } catch (error) {
      console.error('Upload failed:', error);
      throw error;
    } finally {
      setIsUploading(false);
    }
  };

  // Add Club
  const handleAddClub = async (e) => {
    e.preventDefault();
    try {
      let photoUrl = '';
      let bannerUrl = '';
      
      // Upload photo if file exists
      if (newClub.photoFile) {
        photoUrl = await uploadFile(newClub.photoFile, 'club-photos');
      }

      // Upload banner if file exists
      if (newClub.bannerFile) {
        bannerUrl = await uploadFile(newClub.bannerFile, 'club-banners');
      }

      const clubData = {
        name: newClub.name.trim(),
        description: newClub.description.trim(),
        photoUrl: photoUrl || newClub.photoUrl,
        bannerUrl: bannerUrl || newClub.bannerUrl,
        subscribers: []
      };

      await addDoc(collection(db, 'clubs'), clubData);
      
      // Reset form
      setNewClub({ 
        name: '',
        description: '',
        photoUrl: '',
        bannerUrl: '',
        subscribers: [],
        photoFile: null,
        bannerFile: null
      });
      setUploadProgress(0);
    } catch (error) {
      alert(`Error adding club: ${error.message}`);
    }
  };

  // Edit Club - Initialize edit mode
  const handleEditClick = (club) => {
    setEditingClubId(club.id);
    setEditedClub({
      ...club,
      photoFile: null,
      bannerFile: null
    });
  };

  // Save Edited Club
  const handleSaveEdit = async () => {
    if (!editingClubId) return;

    try {
      let photoUrl = editedClub.photoUrl;
      let bannerUrl = editedClub.bannerUrl;
      
      // Upload new photo if file exists
      if (editedClub.photoFile) {
        photoUrl = await uploadFile(editedClub.photoFile, 'club-photos');
      }

      // Upload new banner if file exists
      if (editedClub.bannerFile) {
        bannerUrl = await uploadFile(editedClub.bannerFile, 'club-banners');
      }

      const updateData = {
        name: editedClub.name.trim(),
        description: editedClub.description.trim(),
        photoUrl,
        bannerUrl
      };

      const clubRef = doc(db, 'clubs', editingClubId);
      await updateDoc(clubRef, updateData);
      setEditingClubId(null);
    } catch (error) {
      alert(`Error updating club: ${error.message}`);
    }
  };

  // Cancel Editing
  const handleCancelEdit = () => {
    setEditingClubId(null);
  };

  // Delete Club
  const handleDeleteClub = async (clubId) => {
    if (window.confirm('Are you sure you want to delete this club?')) {
      try {
        await deleteDoc(doc(db, 'clubs', clubId));
      } catch (error) {
        alert(`Error deleting club: ${error.message}`);
      }
    }
  };

  // Toggle Subscription
  const handleToggleSubscription = async (clubId, currentSubscribers) => {
    const userId = auth.currentUser?.uid;
    if (!userId) return;

    try {
      const clubRef = doc(db, 'clubs', clubId);
      const isSubscribed = currentSubscribers.includes(userId);

      if (isSubscribed) {
        await updateDoc(clubRef, {
          subscribers: arrayRemove(userId)
        });
      } else {
        await updateDoc(clubRef, {
          subscribers: arrayUnion(userId)
        });
      }
    } catch (error) {
      alert(`Error updating subscription: ${error.message}`);
    }
  };

  return (
    <div>
      <h1 className="text-3xl font-bold text-college-primary mb-6">Clubs Management</h1>

      {/* Add Club Form */}
      <div className="bg-white p-6 rounded-lg shadow-sm mb-8">
        <h2 className="text-xl font-semibold mb-4">Register New Club</h2>
        <form onSubmit={handleAddClub} className="grid grid-cols-2 gap-4">
          <input
            type="text"
            placeholder="Club Name"
            className="p-2 border rounded"
            value={newClub.name}
            onChange={(e) => setNewClub({ ...newClub, name: e.target.value })}
            required
          />
          
          <div>
            <label className="block mb-1">Club Photo:</label>
            <input
              type="file"
              accept="image/*"
              className="p-2 border rounded w-full"
              onChange={(e) => setNewClub({ ...newClub, photoFile: e.target.files[0] })}
            />
            {newClub.photoUrl && !newClub.photoFile && (
              <p className="text-sm mt-1">Current: {newClub.photoUrl}</p>
            )}
          </div>

          <textarea
            placeholder="Description"
            className="p-2 border rounded col-span-2"
            rows="3"
            value={newClub.description}
            onChange={(e) => setNewClub({ ...newClub, description: e.target.value })}
          />

          <div>
            <label className="block mb-1">Banner Image:</label>
            <input
              type="file"
              accept="image/*"
              className="p-2 border rounded w-full"
              onChange={(e) => setNewClub({ ...newClub, bannerFile: e.target.files[0] })}
            />
            {newClub.bannerUrl && !newClub.bannerFile && (
              <p className="text-sm mt-1">Current: {newClub.bannerUrl}</p>
            )}
          </div>

          {isUploading && (
            <div className="col-span-2">
              <div className="w-full bg-gray-200 rounded-full h-2.5">
                <div 
                  className="bg-college-primary h-2.5 rounded-full" 
                  style={{ width: `${uploadProgress}%` }}
                ></div>
              </div>
              <p className="text-center mt-1">Uploading: {uploadProgress}%</p>
            </div>
          )}

          <button
            type="submit"
            className="col-span-2 bg-college-primary text-white py-2 px-4 rounded hover:bg-blue-900 disabled:opacity-50"
            disabled={isUploading}
          >
            {isUploading ? 'Uploading...' : 'Register Club'}
          </button>
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
            {clubs.map(club => (
              <tr key={club.id} className="border-b">
                <td className="px-6 py-4">
                  {editingClubId === club.id ? (
                    <input
                      type="text"
                      value={editedClub.name}
                      onChange={(e) => setEditedClub({...editedClub, name: e.target.value})}
                      className="p-1 border rounded w-full"
                      required
                    />
                  ) : (
                    club.name
                  )}
                </td>
                <td className="px-6 py-4">
                  {editingClubId === club.id ? (
                    <textarea
                      value={editedClub.description}
                      onChange={(e) => setEditedClub({...editedClub, description: e.target.value})}
                      className="p-1 border rounded w-full"
                    />
                  ) : (
                    club.description || 'No description'
                  )}
                </td>
                <td className="px-6 py-4">
                  {editingClubId === club.id ? (
                    <div>
                      {editedClub.photoUrl && !editedClub.photoFile && (
                        <img src={editedClub.photoUrl} alt="Current" className="h-10 w-10 rounded-full mb-2" />
                      )}
                      <input
                        type="file"
                        accept="image/*"
                        className="p-1 border rounded text-xs"
                        onChange={(e) => setEditedClub({...editedClub, photoFile: e.target.files[0]})}
                      />
                    </div>
                  ) : (
                    club.photoUrl ? (
                      <img src={club.photoUrl} alt="Club" className="h-10 w-10 rounded-full object-cover" />
                    ) : (
                      'No photo'
                    )
                  )}
                </td>
                <td className="px-6 py-4">
                  {editingClubId === club.id ? (
                    <div>
                      {editedClub.bannerUrl && !editedClub.bannerFile && (
                        <img src={editedClub.bannerUrl} alt="Current" className="h-10 w-20 mb-2" />
                      )}
                      <input
                        type="file"
                        accept="image/*"
                        className="p-1 border rounded text-xs"
                        onChange={(e) => setEditedClub({...editedClub, bannerFile: e.target.files[0]})}
                      />
                    </div>
                  ) : (
                    club.bannerUrl ? (
                      <img src={club.bannerUrl} alt="Banner" className="h-10 w-20 object-cover" />
                    ) : (
                      'No banner'
                    )
                  )}
                </td>
                <td className="px-6 py-4">
                  {club.subscribers?.length || 0}
                  {auth.currentUser && (
                    <button
                      onClick={() => handleToggleSubscription(club.id, club.subscribers || [])}
                      className={`ml-2 px-2 py-1 rounded text-xs ${club.isSubscribed ? 'bg-red-100 text-red-800' : 'bg-green-100 text-green-800'}`}
                    >
                      {club.isSubscribed ? 'Unsubscribe' : 'Subscribe'}
                    </button>
                  )}
                </td>
                <td className="px-6 py-4 space-x-2">
                  {editingClubId === club.id ? (
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