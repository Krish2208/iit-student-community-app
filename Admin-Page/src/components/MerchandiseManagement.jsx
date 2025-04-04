import { useState, useEffect } from 'react';
import { db, storage } from '../firebase';
import { collection, addDoc, onSnapshot, updateDoc, deleteDoc, doc } from 'firebase/firestore';
import { ref, uploadBytesResumable, getDownloadURL } from 'firebase/storage';

export default function MerchandiseManagement() {
  const [products, setProducts] = useState([]);
  const [newProduct, setNewProduct] = useState({
    name: '',
    type: '',
    sizesAvailable: '',
    lastDateToPurchase: '',
    description: '',
    colorsAvailable: '',
    images: '',
    clubId: '',
    clubName: '',
    customizationFields: '',
    price: '',
    imageFiles: []
  });

  const [editingProductId, setEditingProductId] = useState(null);
  const [editedProduct, setEditedProduct] = useState({
    name: '',
    type: '',
    sizesAvailable: '',
    lastDateToPurchase: '',
    description: '',
    colorsAvailable: '',
    images: '',
    clubId: '',
    clubName: '',
    customizationFields: '',
    price: '',
    imageFiles: []
  });

  const [uploadProgress, setUploadProgress] = useState(0);
  const [isUploading, setIsUploading] = useState(false);

  useEffect(() => {
    const unsubscribe = onSnapshot(collection(db, 'merchandise'), (snapshot) => {
      const productsData = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
        lastDateToPurchase: doc.data().lastDateToPurchase?.toDate()
      }));
      setProducts(productsData);
    });
    return () => unsubscribe();
  }, []);

  const uploadFile = async (file) => {
    if (!file) return null;
    try {
      setIsUploading(true);
      setUploadProgress(0);
      const storageRef = ref(storage, `merchandise/${Date.now()}-${file.name}`);
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

  const handleAddProduct = async (e) => {
    e.preventDefault();
    try {
      let imageUrls = [];
      if (newProduct.imageFiles.length > 0) {
        imageUrls = await Promise.all(
          newProduct.imageFiles.map(file => uploadFile(file))
        );
      }

      const existingUrls = newProduct.images.split(',').map(i => i.trim()).filter(i => i);
      const allImages = [...existingUrls, ...imageUrls];

      const productData = {
        name: newProduct.name.trim(),
        type: newProduct.type.trim(),
        sizesAvailable: newProduct.sizesAvailable.split(',').map(s => s.trim()).filter(s => s),
        lastDateToPurchase: newProduct.lastDateToPurchase ? new Date(newProduct.lastDateToPurchase) : new Date(),
        description: newProduct.description.trim(),
        colorsAvailable: newProduct.colorsAvailable.split(',').map(c => c.trim()).filter(c => c),
        images: allImages,
        clubId: newProduct.clubId.trim(),
        clubName: newProduct.clubName.trim(),
        customizationFields: Math.max(0, parseInt(newProduct.customizationFields)) || 0,
        price: Math.max(0, parseFloat(newProduct.price)) || 0
      };

      await addDoc(collection(db, 'merchandise'), productData);

      setNewProduct({
        name: '',
        type: '',
        sizesAvailable: '',
        lastDateToPurchase: '',
        description: '',
        colorsAvailable: '',
        images: '',
        clubId: '',
        clubName: '',
        customizationFields: '',
        price: '',
        imageFiles: []
      });
    } catch (error) {
      alert(`Error adding product: ${error.message}`);
    }
  };

  const handleEditClick = (product) => {
    setEditingProductId(product.id);
    setEditedProduct({
      ...product,
      lastDateToPurchase: product.lastDateToPurchase?.toISOString().split('T')[0] || '',
      sizesAvailable: product.sizesAvailable?.join(', ') || '',
      colorsAvailable: product.colorsAvailable?.join(', ') || '',
      images: product.images?.join(', ') || '',
      imageFiles: []
    });
  };

  const handleSaveEdit = async () => {
    if (!editingProductId) return;

    try {
      let newImageUrls = [];
      if (editedProduct.imageFiles.length > 0) {
        newImageUrls = await Promise.all(
          editedProduct.imageFiles.map(file => uploadFile(file))
        );
      }

      const existingUrls = editedProduct.images.split(',').map(i => i.trim()).filter(i => i);
      const allImages = [...existingUrls, ...newImageUrls];

      const updateData = {
        name: editedProduct.name.trim(),
        type: editedProduct.type.trim(),
        sizesAvailable: editedProduct.sizesAvailable.split(',').map(s => s.trim()).filter(s => s),
        lastDateToPurchase: new Date(editedProduct.lastDateToPurchase),
        description: editedProduct.description.trim(),
        colorsAvailable: editedProduct.colorsAvailable.split(',').map(c => c.trim()).filter(c => c),
        images: allImages,
        clubId: editedProduct.clubId.trim(),
        clubName: editedProduct.clubName.trim(),
        customizationFields: Math.max(0, parseInt(editedProduct.customizationFields)) || 0,
        price: Math.max(0, parseFloat(editedProduct.price)) || 0
      };

      const productRef = doc(db, 'merchandise', editingProductId);
      await updateDoc(productRef, updateData);
      setEditingProductId(null);
    } catch (error) {
      alert(`Error updating product: ${error.message}`);
    }
  };

  const handleCancelEdit = () => {
    setEditingProductId(null);
  };

  const handleDeleteProduct = async (productId) => {
    if (window.confirm('Are you sure you want to delete this product?')) {
      try {
        await deleteDoc(doc(db, 'merchandise', productId));
      } catch (error) {
        alert(`Error deleting product: ${error.message}`);
      }
    }
  };

  const handleFileChange = (e, isEditing = false) => {
    const files = Array.from(e.target.files);
    if (isEditing) {
      setEditedProduct(prev => ({ ...prev, imageFiles: files }));
    } else {
      setNewProduct(prev => ({ ...prev, imageFiles: files }));
    }
  };

  return (
    <div>
      <h1 className="text-3xl font-bold text-college-primary mb-6">Merchandise Management</h1>

      {/* Add Product Form */}
      <div className="bg-white p-6 rounded-lg shadow-sm mb-8">
        <h2 className="text-xl font-semibold mb-4">Add New Product</h2>
        <form onSubmit={handleAddProduct} className="grid grid-cols-3 gap-4">
          <input
            type="text"
            placeholder="Product Name"
            className="p-2 border rounded"
            value={newProduct.name}
            onChange={(e) => setNewProduct(prev => ({ ...prev, name: e.target.value }))}
            required
          />
          <input
            type="text"
            placeholder="Type (T-shirt, Hoodie, etc.)"
            className="p-2 border rounded"
            value={newProduct.type}
            onChange={(e) => setNewProduct(prev => ({ ...prev, type: e.target.value }))}
            required
          />
          <input
            type="number"
            placeholder="Price"
            className="p-2 border rounded"
            value={newProduct.price}
            onChange={(e) => setNewProduct(prev => ({ ...prev, price: e.target.value }))}
            required
            min="0"
            step="0.01"
          />
          <input
            type="text"
            placeholder="Sizes (comma separated)"
            className="p-2 border rounded"
            value={newProduct.sizesAvailable}
            onChange={(e) => setNewProduct(prev => ({ ...prev, sizesAvailable: e.target.value }))}
          />
          <input
            type="date"
            className="p-2 border rounded"
            value={newProduct.lastDateToPurchase}
            onChange={(e) => setNewProduct(prev => ({ ...prev, lastDateToPurchase: e.target.value }))}
            required
          />
          <input
            type="text"
            placeholder="Colors (comma separated)"
            className="p-2 border rounded"
            value={newProduct.colorsAvailable}
            onChange={(e) => setNewProduct(prev => ({ ...prev, colorsAvailable: e.target.value }))}
          />
          <div className="col-span-2">
            <input
              type="file"
              multiple
              accept="image/*"
              className="p-2 border rounded w-full"
              onChange={(e) => handleFileChange(e, false)}
            />
            <input
              type="text"
              placeholder="Existing Image URLs (comma separated)"
              className="p-2 border rounded w-full mt-2"
              value={newProduct.images}
              onChange={(e) => setNewProduct(prev => ({ ...prev, images: e.target.value }))}
            />
          </div>
          <input
            type="number"
            placeholder="Customization Fields"
            className="p-2 border rounded"
            value={newProduct.customizationFields}
            onChange={(e) => setNewProduct(prev => ({ ...prev, customizationFields: e.target.value }))}
            min="0"
          />
          <textarea
            placeholder="Description"
            className="p-2 border rounded col-span-3"
            value={newProduct.description}
            onChange={(e) => setNewProduct(prev => ({ ...prev, description: e.target.value }))}
            rows="3"
          />
          <input
            type="text"
            placeholder="Club ID"
            className="p-2 border rounded"
            value={newProduct.clubId}
            onChange={(e) => setNewProduct(prev => ({ ...prev, clubId: e.target.value }))}
          />
          <input
            type="text"
            placeholder="Club Name"
            className="p-2 border rounded"
            value={newProduct.clubName}
            onChange={(e) => setNewProduct(prev => ({ ...prev, clubName: e.target.value }))}
          />
          {isUploading && (
            <div className="col-span-3">
              <progress value={uploadProgress} max="100" className="w-full" />
              <p className="text-center">Uploading: {uploadProgress}%</p>
            </div>
          )}
          <button
            type="submit"
            className="col-span-3 bg-college-primary text-white py-2 px-4 rounded hover:bg-blue-900 disabled:opacity-50"
            disabled={isUploading}
          >
            {isUploading ? 'Uploading...' : 'Add Product'}
          </button>
        </form>
      </div>

      {/* Products Table */}
      <div className="bg-white rounded-lg shadow-sm overflow-hidden">
        <table className="w-full">
          <thead className="bg-college-secondary">
            <tr>
              <th className="px-6 py-3 text-left">Product Name</th>
              <th className="px-6 py-3 text-left">Type</th>
              <th className="px-6 py-3 text-left">Price</th>
              <th className="px-6 py-3 text-left">Sizes</th>
              <th className="px-6 py-3 text-left">Last Date</th>
              <th className="px-6 py-3 text-left">Actions</th>
            </tr>
          </thead>
          <tbody>
            {products.map(product => (
              <tr key={product.id} className="border-b">
                <td className="px-6 py-4">
                  {editingProductId === product.id ? (
                    <input
                      type="text"
                      value={editedProduct.name}
                      onChange={(e) => setEditedProduct(prev => ({ ...prev, name: e.target.value }))}
                      className="p-1 border rounded w-full"
                      required
                    />
                  ) : (
                    product.name
                  )}
                </td>
                <td className="px-6 py-4">
                  {editingProductId === product.id ? (
                    <input
                      type="text"
                      value={editedProduct.type}
                      onChange={(e) => setEditedProduct(prev => ({ ...prev, type: e.target.value }))}
                      className="p-1 border rounded w-full"
                      required
                    />
                  ) : (
                    product.type
                  )}
                </td>
                <td className="px-6 py-4">
                  {editingProductId === product.id ? (
                    <input
                      type="number"
                      value={editedProduct.price}
                      onChange={(e) => setEditedProduct(prev => ({ ...prev, price: e.target.value }))}
                      className="p-1 border rounded w-full"
                      required
                      min="0"
                      step="0.01"
                    />
                  ) : (
                    `₹${product.price.toFixed(2)}`
                  )}
                </td>
                <td className="px-6 py-4">
                  {editingProductId === product.id ? (
                    <input
                      type="text"
                      value={editedProduct.sizesAvailable}
                      onChange={(e) => setEditedProduct(prev => ({ ...prev, sizesAvailable: e.target.value }))}
                      className="p-1 border rounded w-full"
                    />
                  ) : (
                    product.sizesAvailable.join(', ')
                  )}
                </td>
                <td className="px-6 py-4">
                  {editingProductId === product.id ? (
                    <input
                      type="date"
                      value={editedProduct.lastDateToPurchase}
                      onChange={(e) => setEditedProduct(prev => ({ ...prev, lastDateToPurchase: e.target.value }))}
                      className="p-1 border rounded w-full"
                      required
                    />
                  ) : (
                    product.lastDateToPurchase?.toLocaleDateString()
                  )}
                </td>
                <td className="px-6 py-4 space-x-2">
                  {editingProductId === product.id ? (
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
                        onClick={() => handleEditClick(product)}
                        className="text-blue-600 hover:text-blue-800"
                      >
                        Edit
                      </button>
                      <button 
                        onClick={() => handleDeleteProduct(product.id)}
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