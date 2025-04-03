import { useState, useEffect } from 'react';
import { db } from '../firebase';
import { collection, addDoc, onSnapshot, updateDoc, deleteDoc, doc } from 'firebase/firestore';

export default function MerchandiseManagement() {
  const [items, setItems] = useState([]);
  const [newItem, setNewItem] = useState({
    name: '',
    price: '',
    stock: '',
    status: 'available'
  });
  const [editingItemId, setEditingItemId] = useState(null);
  const [editedItem, setEditedItem] = useState({
    name: '',
    price: '',
    stock: '',
    status: 'available'
  });

  // Firestore data subscription
  useEffect(() => {
    const unsubscribe = onSnapshot(collection(db, 'merchandise'), (snapshot) => {
      const itemsData = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      setItems(itemsData);
    });
    return () => unsubscribe();
  }, []);

  // Add Item
  const handleAddItem = async (e) => {
    e.preventDefault();
    try {
      await addDoc(collection(db, 'merchandise'), {
        ...newItem,
        price: Number(newItem.price),
        stock: Number(newItem.stock)
      });
      setNewItem({ 
        name: '', 
        price: '', 
        stock: '', 
        status: 'available' 
      });
    } catch (error) {
      alert('Error adding item: ' + error.message);
    }
  };

  // Edit Item - Initialize edit mode
  const handleEditClick = (item) => {
    setEditingItemId(item.id);
    setEditedItem(item);
  };

  // Save Edited Item
  const handleSaveEdit = async () => {
    if (!editingItemId) return;

    try {
      const itemRef = doc(db, 'merchandise', editingItemId);
      await updateDoc(itemRef, {
        name: editedItem.name,
        price: Number(editedItem.price),
        stock: Number(editedItem.stock),
        status: editedItem.status
      });
      setEditingItemId(null);
    } catch (error) {
      alert('Error updating item: ' + error.message);
    }
  };

  // Cancel Editing
  const handleCancelEdit = () => {
    setEditingItemId(null);
  };

  // Delete Item
  const handleDeleteItem = async (itemId) => {
    try {
      await deleteDoc(doc(db, 'merchandise', itemId));
    } catch (error) {
      alert('Error deleting item: ' + error.message);
    }
  };

  return (
    <div>
      <h1 className="text-3xl font-bold text-college-primary mb-6">Merchandise Management</h1>

      {/* Add Item Form */}
      <div className="bg-white p-6 rounded-lg shadow-sm mb-8">
        <h2 className="text-xl font-semibold mb-4">Add New Item</h2>
        <form onSubmit={handleAddItem} className="grid grid-cols-3 gap-4">
          <input
            type="text"
            placeholder="Item Name"
            className="p-2 border rounded"
            value={newItem.name}
            onChange={(e) => setNewItem({ ...newItem, name: e.target.value })}
            required
          />
          <input
            type="number"
            placeholder="Price"
            className="p-2 border rounded"
            value={newItem.price}
            onChange={(e) => setNewItem({ ...newItem, price: e.target.value })}
            required
            min="1"
          />
          <input
            type="number"
            placeholder="Stock"
            className="p-2 border rounded"
            value={newItem.stock}
            onChange={(e) => setNewItem({ ...newItem, stock: e.target.value })}
            required
            min="0"
          />
          <select
            className="p-2 border rounded col-span-3"
            value={newItem.status}
            onChange={(e) => setNewItem({ ...newItem, status: e.target.value })}
            required
          >
            <option value="available">Available</option>
            <option value="out-of-stock">Out of Stock</option>
          </select>
          <button
            type="submit"
            className="col-span-3 bg-college-primary text-white py-2 px-4 rounded hover:bg-blue-900"
          >
            Add Item
          </button>
        </form>
      </div>

      {/* Merchandise Table */}
      <div className="bg-white rounded-lg shadow-sm overflow-hidden">
        <table className="w-full">
          <thead className="bg-college-secondary">
            <tr>
              <th className="px-6 py-3 text-left">Item Name</th>
              <th className="px-6 py-3 text-left">Price</th>
              <th className="px-6 py-3 text-left">Stock</th>
              <th className="px-6 py-3 text-left">Status</th>
              <th className="px-6 py-3 text-left">Actions</th>
            </tr>
          </thead>
          <tbody>
            {items.map(item => (
              <tr key={item.id} className="border-b">
                <td className="px-6 py-4">
                  {editingItemId === item.id ? (
                    <input
                      type="text"
                      value={editedItem.name}
                      onChange={(e) => setEditedItem({...editedItem, name: e.target.value})}
                      className="p-1 border rounded w-full"
                      required
                    />
                  ) : (
                    item.name
                  )}
                </td>
                <td className="px-6 py-4">
                  {editingItemId === item.id ? (
                    <input
                      type="number"
                      value={editedItem.price}
                      onChange={(e) => setEditedItem({...editedItem, price: e.target.value})}
                      className="p-1 border rounded w-full"
                      required
                      min="1"
                    />
                  ) : (
                    `₹${item.price}`
                  )}
                </td>
                <td className="px-6 py-4">
                  {editingItemId === item.id ? (
                    <input
                      type="number"
                      value={editedItem.stock}
                      onChange={(e) => setEditedItem({...editedItem, stock: e.target.value})}
                      className="p-1 border rounded w-full"
                      required
                      min="0"
                    />
                  ) : (
                    item.stock
                  )}
                </td>
                <td className="px-6 py-4">
                  {editingItemId === item.id ? (
                    <select
                      value={editedItem.status}
                      onChange={(e) => setEditedItem({...editedItem, status: e.target.value})}
                      className="p-1 border rounded"
                      required
                    >
                      <option value="available">Available</option>
                      <option value="out-of-stock">Out of Stock</option>
                    </select>
                  ) : (
                    <span className={`px-2 py-1 rounded ${item.status === 'available' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'}`}>
                      {item.status}
                    </span>
                  )}
                </td>
                <td className="px-6 py-4 space-x-2">
                  {editingItemId === item.id ? (
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
                        onClick={() => handleEditClick(item)}
                        className="text-blue-600 hover:text-blue-800"
                      >
                        Edit
                      </button>
                      <button 
                        onClick={() => handleDeleteItem(item.id)}
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