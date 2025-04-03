import { useState, useEffect } from 'react';
import { db } from '../firebase';
import { collection, addDoc, onSnapshot, updateDoc, deleteDoc, doc } from 'firebase/firestore';

export default function UserManagement() {
  const [users, setUsers] = useState([]);
  const [newUser, setNewUser] = useState({ email: '', role: '' });
  const [editingUserId, setEditingUserId] = useState(null);
  const [editedUser, setEditedUser] = useState({ email: '', role: '' });

  // Firestore data subscription
  useEffect(() => {
    const unsubscribe = onSnapshot(collection(db, 'users'), (snapshot) => {
      const usersData = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      setUsers(usersData);
    });
    return () => unsubscribe();
  }, []);

  // Add User
  const handleAddUser = async () => {
    if (newUser.email.trim() && newUser.role.trim()) {
      try {
        await addDoc(collection(db, 'users'), {
          email: newUser.email,
          role: newUser.role
        });
        setNewUser({ email: '', role: '' });
      } catch (error) {
        alert('Error adding user: ' + error.message);
      }
    } else {
      alert('Please fill in all fields.');
    }
  };

  // Edit User - Initialize edit mode
  const handleEditClick = (user) => {
    setEditingUserId(user.id);
    setEditedUser({ email: user.email, role: user.role });
  };

  // Save Edited User
  const handleSaveClick = async () => {
    if (!editingUserId) return;

    try {
      const userRef = doc(db, 'users', editingUserId);
      await updateDoc(userRef, {
        email: editedUser.email,
        role: editedUser.role
      });
      setEditingUserId(null);
      setEditedUser({ email: '', role: '' });
    } catch (error) {
      alert('Error updating user: ' + error.message);
    }
  };

  // Cancel Editing
  const handleCancelClick = () => {
    setEditingUserId(null);
    setEditedUser({ email: '', role: '' });
  };

  // Delete User
  const handleDeleteClick = async (userId) => {
    try {
      const userRef = doc(db, 'users', userId);
      await deleteDoc(userRef);
    } catch (error) {
      alert('Error deleting user: ' + error.message);
    }
  };


  return (
    <div>
      <h1 className="text-3xl font-bold text-college-primary mb-6">User Management</h1>

      {/* Add User Form */}
      <div className="bg-white p-6 rounded-lg shadow-sm mb-8">
        <h2 className="text-xl font-semibold mb-4">Add New User</h2>
        <form className="grid grid-cols-3 gap-4">
          <input
            type="email"
            placeholder="Email"
            value={newUser.email}
            onChange={(e) => setNewUser({ ...newUser, email: e.target.value })}
            className="p-2 border rounded"
          />
          <select
            value={newUser.role}
            onChange={(e) => setNewUser({ ...newUser, role: e.target.value })}
            className="p-2 border rounded"
          >
            <option value="">Select Role</option>
            <option value="admin">Admin</option>
            <option value="student">Student</option>
          </select>
          <button
            type="button"
            onClick={handleAddUser}
            className="bg-college-primary text-white py-2 px-4 rounded hover:bg-blue-900"
          >
            Add User
          </button>
        </form>
      </div>

      {/* Users Table */}
      <div className="bg-white rounded-lg shadow-sm overflow-hidden">
        <table className="w-full">
          <thead className="bg-college-secondary">
            <tr>
              <th className="px-6 py-3 text-left">Email</th>
              <th className="px-6 py-3 text-left">Role</th>
              <th className="px-6 py-3 text-left">Actions</th>
            </tr>
          </thead>
          <tbody>
            {users.map((user) => (
              <tr key={user.id} className="border-b">
                {/* Render Editable Fields if Editing */}
                {editingUserId === user.id ? (
                  <>
                    <td className="px-6 py-4">
                      <input
                        type="email"
                        value={editedUser.email}
                        onChange={(e) =>
                          setEditedUser({ ...editedUser, email: e.target.value })
                        }
                        className="p-2 border rounded w-full"
                      />
                    </td>
                    <td className="px-6 py-4">
                      <select
                        value={editedUser.role}
                        onChange={(e) =>
                          setEditedUser({ ...editedUser, role: e.target.value })
                        }
                        className="p-2 border rounded w-full"
                      >
                        <option value="admin">Admin</option>
                        <option value="student">Student</option>
                      </select>
                    </td>
                    <td className="px-6 py-4 space-x-2">
                      <button
                        onClick={handleSaveClick}
                        className="text-green-600 hover:text-green-800"
                      >
                        Save
                      </button>
                      <button
                        onClick={handleCancelClick}
                        className="text-gray-600 hover:text-gray-800"
                      >
                        Cancel
                      </button>
                    </td>
                  </>
                ) : (
                  <>
                    {/* Render Static Fields if Not Editing */}
                    <td className="px-6 py-4">{user.email}</td>
                    <td className="px-6 py-4">{user.role}</td>
                    <td className="px-6 py-4 space-x-2">
                      <button
                        onClick={() => handleEditClick(user)}
                        className="text-blue-600 hover:text-blue-800"
                      >
                        Edit
                      </button>
                      <button
                        onClick={() => handleDeleteClick(user.id)}
                        className="text-red-600 hover:text-red-800"
                      >
                        Delete
                      </button>
                    </td>
                  </>
                )}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}