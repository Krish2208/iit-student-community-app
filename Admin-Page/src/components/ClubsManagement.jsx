import { useState, useEffect } from 'react';
import { db } from '../firebase';
import { collection, addDoc, onSnapshot, updateDoc, deleteDoc, doc } from 'firebase/firestore';

export default function ClubsManagement() {
  const [clubs, setClubs] = useState([]);
  const [newClub, setNewClub] = useState({
    name: '',
    category: '',
    description: '',
    meetingSchedule: '',
    contactEmail: '',
    status: 'active'
  });

  const [editingClubId, setEditingClubId] = useState(null);
  const [editedClub, setEditedClub] = useState({
    name: '',
    category: '',
    description: '',
    meetingSchedule: '',
    contactEmail: '',
    status: 'active'
  });

  // Firestore data subscription
  useEffect(() => {
    const unsubscribe = onSnapshot(collection(db, 'clubs'), (snapshot) => {
      const clubsData = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      setClubs(clubsData);
    });
    return () => unsubscribe();
  }, []);

  // Add Club
  const handleAddClub = async (e) => {
    e.preventDefault();
    try {
      await addDoc(collection(db, 'clubs'), newClub);
      setNewClub({ 
        name: '', 
        category: '', 
        description: '', 
        meetingSchedule: '', 
        contactEmail: '',
        status: 'active'
      });
    } catch (error) {
      alert('Error adding club: ' + error.message);
    }
  };

  // Edit Club - Initialize edit mode
  const handleEditClick = (club) => {
    setEditingClubId(club.id);
    setEditedClub(club);
  };

  // Save Edited Club
  const handleSaveEdit = async () => {
    if (!editingClubId) return;

    try {
      const clubRef = doc(db, 'clubs', editingClubId);
      await updateDoc(clubRef, editedClub);
      setEditingClubId(null);
    } catch (error) {
      alert('Error updating club: ' + error.message);
    }
  };

  // Cancel Editing
  const handleCancelEdit = () => {
    setEditingClubId(null);
  };

  // Delete Club
  const handleDeleteClub = async (clubId) => {
    try {
      await deleteDoc(doc(db, 'clubs', clubId));
    } catch (error) {
      alert('Error deleting club: ' + error.message);
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
          <select
            className="p-2 border rounded"
            value={newClub.category}
            onChange={(e) => setNewClub({ ...newClub, category: e.target.value })}
            required
          >
            <option value="">Select Category</option>
            <option value="academic">Academic</option>
            <option value="cultural">Cultural</option>
            <option value="sports">Sports</option>
            <option value="technical">Technical</option>
            <option value="social">Social Service</option>
          </select>
          <textarea
            placeholder="Description (Purpose, Activities)"
            className="p-2 border rounded col-span-2"
            rows="3"
            value={newClub.description}
            onChange={(e) => setNewClub({ ...newClub, description: e.target.value })}
            required
          />
          <input
            type="text"
            placeholder="Meeting Schedule (e.g., Every Tuesday 4-5pm)"
            className="p-2 border rounded"
            value={newClub.meetingSchedule}
            onChange={(e) => setNewClub({ ...newClub, meetingSchedule: e.target.value })}
            required
          />
          <input
            type="email"
            placeholder="Contact Email"
            className="p-2 border rounded"
            value={newClub.contactEmail}
            onChange={(e) => setNewClub({ ...newClub, contactEmail: e.target.value })}
            required
          />
          <select
            className="p-2 border rounded col-span-2"
            value={newClub.status}
            onChange={(e) => setNewClub({ ...newClub, status: e.target.value })}
          >
            <option value="active">Active</option>
            <option value="inactive">Inactive</option>
          </select>
          <button
            type="submit"
            className="col-span-2 bg-college-primary text-white py-2 px-4 rounded hover:bg-blue-900"
          >
            Register Club
          </button>
        </form>
      </div>

      {/* Clubs Table */}
      <div className="bg-white rounded-lg shadow-sm overflow-hidden">
        <table className="w-full">
          <thead className="bg-college-secondary">
            <tr>
              <th className="px-6 py-3 text-left">Club Name</th>
              <th className="px-6 py-3 text-left">Category</th>
              <th className="px-6 py-3 text-left">Description</th>
              <th className="px-6 py-3 text-left">Schedule</th>
              <th className="px-6 py-3 text-left">Status</th>
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
                    <select
                      value={editedClub.category}
                      onChange={(e) => setEditedClub({...editedClub, category: e.target.value})}
                      className="p-1 border rounded"
                      required
                    >
                      <option value="academic">Academic</option>
                      <option value="cultural">Cultural</option>
                      <option value="sports">Sports</option>
                      <option value="technical">Technical</option>
                      <option value="social">Social Service</option>
                    </select>
                  ) : (
                    club.category
                  )}
                </td>
                <td className="px-6 py-4">
                  {editingClubId === club.id ? (
                    <textarea
                      value={editedClub.description}
                      onChange={(e) => setEditedClub({...editedClub, description: e.target.value})}
                      className="p-1 border rounded w-full"
                      required
                    />
                  ) : (
                    club.description
                  )}
                </td>
                <td className="px-6 py-4">
                  {editingClubId === club.id ? (
                    <input
                      type="text"
                      value={editedClub.meetingSchedule}
                      onChange={(e) => setEditedClub({...editedClub, meetingSchedule: e.target.value})}
                      className="p-1 border rounded w-full"
                      required
                    />
                  ) : (
                    club.meetingSchedule
                  )}
                </td>
                <td className="px-6 py-4">
                  {editingClubId === club.id ? (
                    <select
                      value={editedClub.status}
                      onChange={(e) => setEditedClub({...editedClub, status: e.target.value})}
                      className="p-1 border rounded"
                    >
                      <option value="active">Active</option>
                      <option value="inactive">Inactive</option>
                    </select>
                  ) : (
                    <span className={`px-2 py-1 rounded ${club.status === 'active' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'}`}>
                      {club.status}
                    </span>
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