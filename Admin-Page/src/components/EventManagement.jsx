import { useState, useEffect } from 'react';
import { db } from '../firebase';
import { collection, addDoc, onSnapshot, updateDoc, deleteDoc, doc } from 'firebase/firestore';

export default function EventManagement() {
  const [events, setEvents] = useState([]);
  const [newEvent, setNewEvent] = useState({
    name: '',
    date: '',
    location: '',
    description: '',
    participants: ''
  });
  const [editingEventId, setEditingEventId] = useState(null);
  const [editedEvent, setEditedEvent] = useState({
    name: '',
    date: '',
    location: '',
    description: '',
    participants: ''
  });

  // Firestore data subscription
  useEffect(() => {
    const unsubscribe = onSnapshot(collection(db, 'events'), (snapshot) => {
      const eventsData = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      setEvents(eventsData);
    });
    return () => unsubscribe();
  }, []);

  // Add Event
  const handleAddEvent = async (e) => {
    e.preventDefault();
    try {
      await addDoc(collection(db, 'events'), {
        ...newEvent,
        participants: Number(newEvent.participants)
      });
      setNewEvent({ 
        name: '', 
        date: '', 
        location: '', 
        description: '', 
        participants: '' 
      });
    } catch (error) {
      alert('Error adding event: ' + error.message);
    }
  };

  // Edit Event - Initialize edit mode
  const handleEditClick = (event) => {
    setEditingEventId(event.id);
    setEditedEvent(event);
  };

  // Save Edited Event
  const handleSaveEdit = async () => {
    if (!editingEventId) return;

    try {
      const eventRef = doc(db, 'events', editingEventId);
      await updateDoc(eventRef, {
        name: editedEvent.name,
        date: editedEvent.date,
        location: editedEvent.location,
        description: editedEvent.description,
        participants: Number(editedEvent.participants)
      });
      setEditingEventId(null);
    } catch (error) {
      alert('Error updating event: ' + error.message);
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
            type="date"
            className="p-2 border rounded"
            value={newEvent.date}
            onChange={(e) => setNewEvent({ ...newEvent, date: e.target.value })}
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
          <input
            type="number"
            placeholder="Participants"
            className="p-2 border rounded"
            value={newEvent.participants}
            onChange={(e) => setNewEvent({ ...newEvent, participants: e.target.value })}
            required
            min="1"
          />
          <textarea
            placeholder="Description"
            className="p-2 border rounded col-span-2"
            value={newEvent.description}
            onChange={(e) => setNewEvent({ ...newEvent, description: e.target.value })}
            required
          />
          <button
            type="submit"
            className="col-span-2 bg-college-primary text-white py-2 px-4 rounded hover:bg-blue-900"
          >
            Add Event
          </button>
        </form>
      </div>

      {/* Events Table */}
      <div className="bg-white rounded-lg shadow-sm overflow-hidden">
        <table className="w-full">
          <thead className="bg-college-secondary">
            <tr>
              <th className="px-6 py-3 text-left">Event Name</th>
              <th className="px-6 py-3 text-left">Date</th>
              <th className="px-6 py-3 text-left">Location</th>
              <th className="px-6 py-3 text-left">Participants</th>
              <th className="px-6 py-3 text-left">Description</th>
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
                      onChange={(e) =>
                        setEditedEvent({ ...editedEvent, name: e.target.value })
                      }
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
                      type="date"
                      value={editedEvent.date}
                      onChange={(e) =>
                        setEditedEvent({ ...editedEvent, date: e.target.value })
                      }
                      className="p-1 border rounded"
                      required
                    />
                  ) : (
                    event.date
                  )}
                </td>
                <td className="px-6 py-4">
                  {editingEventId === event.id ? (
                    <input
                      type="text"
                      value={editedEvent.location}
                      onChange={(e) =>
                        setEditedEvent({ ...editedEvent, location: e.target.value })
                      }
                      className="p-1 border rounded w-full"
                      required
                    />
                  ) : (
                    event.location
                  )}
                </td>
                <td className="px-6 py-4">
                  {editingEventId === event.id ? (
                    <input
                      type="number"
                      value={editedEvent.participants}
                      onChange={(e) =>
                        setEditedEvent({ ...editedEvent, participants: e.target.value })
                      }
                      className="p-1 border rounded"
                      required
                      min="1"
                    />
                  ) : (
                    event.participants
                  )}
                </td>
                <td className="px-6 py-4">
                  {editingEventId === event.id ? (
                    <textarea
                      value={editedEvent.description}
                      onChange={(e) =>
                        setEditedEvent({ ...editedEvent, description: e.target.value })
                      }
                      className="p-1 border rounded w-full"
                      required
                    />
                  ) : (
                    event.description
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