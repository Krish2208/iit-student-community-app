import { useState, useEffect } from "react";
import { db, storage } from "../firebase";
import {
  collection,
  addDoc,
  onSnapshot,
  updateDoc,
  deleteDoc,
  doc,
} from "firebase/firestore";
import { ref, uploadBytesResumable, getDownloadURL } from "firebase/storage";

export default function MerchandiseManagement() {
  const [products, setProducts] = useState([]);
  const [formData, setFormData] = useState({
    name: "",
    type: "",
    sizesAvailable: "",
    lastDateToPurchase: "",
    description: "",
    colorsAvailable: "",
    images: "",
    clubId: "",
    clubName: "",
    customizationFields: "",
    price: "",
    imageFiles: [],
  });

  const [isEditing, setIsEditing] = useState(false);
  const [currentProductId, setCurrentProductId] = useState(null);
  const [uploadProgress, setUploadProgress] = useState(0);
  const [isUploading, setIsUploading] = useState(false);

  useEffect(() => {
    const unsubscribe = onSnapshot(
      collection(db, "merchandise"),
      (snapshot) => {
        const productsData = snapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
          lastDateToPurchase: doc.data().lastDateToPurchase?.toDate(),
        }));
        setProducts(productsData);
      }
    );
    return () => unsubscribe();
  }, []);

  const uploadFile = async (file) => {
    if (!file) return null;
    try {
      setIsUploading(true);
      setUploadProgress(0);
      const storageRef = ref(storage, `merchandise/${Date.now()}-${file.name}`);
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

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      let imageUrls = [];
      if (formData.imageFiles.length > 0) {
        imageUrls = await Promise.all(
          formData.imageFiles.map((file) => uploadFile(file))
        );
      }

      const existingUrls = formData.images
        .split(",")
        .map((i) => i.trim())
        .filter((i) => i);
      const allImages = [...existingUrls, ...imageUrls];

      const productData = {
        name: formData.name.trim(),
        type: formData.type.trim(),
        sizesAvailable: formData.sizesAvailable
          .split(",")
          .map((s) => s.trim())
          .filter((s) => s),
        lastDateToPurchase: formData.lastDateToPurchase
          ? new Date(formData.lastDateToPurchase)
          : new Date(),
        description: formData.description.trim(),
        colorsAvailable: formData.colorsAvailable
          .split(",")
          .map((c) => c.trim())
          .filter((c) => c),
        images: allImages,
        clubId: formData.clubId.trim(),
        clubName: formData.clubName.trim(),
        customizationFields:
          Math.max(0, parseInt(formData.customizationFields)) || 0,
        price: Math.max(0, parseFloat(formData.price)) || 0,
      };

      if (isEditing && currentProductId) {
        // Update existing product
        const productRef = doc(db, "merchandise", currentProductId);
        await updateDoc(productRef, productData);
      } else {
        // Add new product
        await addDoc(collection(db, "merchandise"), productData);
      }

      // Reset form
      resetForm();
    } catch (error) {
      alert(
        `Error ${isEditing ? "updating" : "adding"} product: ${error.message}`
      );
    }
  };

  const handleEditClick = (product) => {
    setIsEditing(true);
    setCurrentProductId(product.id);

    // Format the date for date input
    const formattedDate = product.lastDateToPurchase
      ? product.lastDateToPurchase.toISOString().split("T")[0]
      : "";

    // Set form data with product details
    setFormData({
      name: product.name || "",
      type: product.type || "",
      sizesAvailable: product.sizesAvailable?.join(", ") || "",
      lastDateToPurchase: formattedDate,
      description: product.description || "",
      colorsAvailable: product.colorsAvailable?.join(", ") || "",
      images: product.images?.join(", ") || "",
      clubId: product.clubId || "",
      clubName: product.clubName || "",
      customizationFields: product.customizationFields || "",
      price: product.price || "",
      imageFiles: [],
    });

    // Scroll to form
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  const resetForm = () => {
    setFormData({
      name: "",
      type: "",
      sizesAvailable: "",
      lastDateToPurchase: "",
      description: "",
      colorsAvailable: "",
      images: "",
      clubId: "",
      clubName: "",
      customizationFields: "",
      price: "",
      imageFiles: [],
    });
    setIsEditing(false);
    setCurrentProductId(null);
    setUploadProgress(0);
  };

  const handleDeleteProduct = async (productId) => {
    if (window.confirm("Are you sure you want to delete this product?")) {
      try {
        await deleteDoc(doc(db, "merchandise", productId));

        // If deleting the product that's being edited, reset the form
        if (currentProductId === productId) {
          resetForm();
        }
      } catch (error) {
        alert(`Error deleting product: ${error.message}`);
      }
    }
  };

  const handleFileChange = (e) => {
    const files = Array.from(e.target.files);
    setFormData((prev) => ({ ...prev, imageFiles: files }));
  };

  return (
    <div>
      <h1 className="text-3xl font-bold text-college-primary mb-6">
        Merchandise Management
      </h1>

      {/* Product Form */}
      <div className="bg-white p-6 rounded-lg shadow-sm mb-8">
        <h2 className="text-xl font-semibold mb-4">
          {isEditing ? "Edit Product" : "Add New Product"}
        </h2>
        <form
          onSubmit={handleSubmit}
          className="grid grid-cols-1 md:grid-cols-3 gap-4"
        >
          {/* Basic Info */}
          <div className="col-span-1">
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Product Name
            </label>
            <input
              type="text"
              className="p-2 border rounded w-full"
              value={formData.name}
              onChange={(e) =>
                setFormData((prev) => ({ ...prev, name: e.target.value }))
              }
              required
            />
          </div>

          <div className="col-span-1">
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Type
            </label>
            <input
              type="text"
              className="p-2 border rounded w-full"
              placeholder="T-shirt, Hoodie, etc."
              value={formData.type}
              onChange={(e) =>
                setFormData((prev) => ({ ...prev, type: e.target.value }))
              }
              required
            />
          </div>

          <div className="col-span-1">
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Price (₹)
            </label>
            <input
              type="number"
              className="p-2 border rounded w-full"
              value={formData.price}
              onChange={(e) =>
                setFormData((prev) => ({ ...prev, price: e.target.value }))
              }
              required
              min="0"
              step="0.01"
            />
          </div>

          {/* Product Options */}
          <div className="col-span-1">
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Available Sizes
            </label>
            <input
              type="text"
              className="p-2 border rounded w-full"
              placeholder="S, M, L, XL (comma separated)"
              value={formData.sizesAvailable}
              onChange={(e) =>
                setFormData((prev) => ({
                  ...prev,
                  sizesAvailable: e.target.value,
                }))
              }
            />
          </div>

          <div className="col-span-1">
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Available Colors
            </label>
            <input
              type="text"
              className="p-2 border rounded w-full"
              placeholder="Red, Blue, Green (comma separated)"
              value={formData.colorsAvailable}
              onChange={(e) =>
                setFormData((prev) => ({
                  ...prev,
                  colorsAvailable: e.target.value,
                }))
              }
            />
          </div>

          <div className="col-span-1">
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Last Date To Purchase
            </label>
            <input
              type="date"
              className="p-2 border rounded w-full"
              value={formData.lastDateToPurchase}
              onChange={(e) =>
                setFormData((prev) => ({
                  ...prev,
                  lastDateToPurchase: e.target.value,
                }))
              }
              required
            />
          </div>

          {/* Club Info */}
          <div className="col-span-1">
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Club ID
            </label>
            <input
              type="text"
              className="p-2 border rounded w-full"
              value={formData.clubId}
              onChange={(e) =>
                setFormData((prev) => ({ ...prev, clubId: e.target.value }))
              }
            />
          </div>

          <div className="col-span-1">
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Club Name
            </label>
            <input
              type="text"
              className="p-2 border rounded w-full"
              value={formData.clubName}
              onChange={(e) =>
                setFormData((prev) => ({ ...prev, clubName: e.target.value }))
              }
            />
          </div>

          <div className="col-span-1">
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Customization Fields
            </label>
            <input
              type="number"
              className="p-2 border rounded w-full"
              value={formData.customizationFields}
              onChange={(e) =>
                setFormData((prev) => ({
                  ...prev,
                  customizationFields: e.target.value,
                }))
              }
              min="0"
            />
          </div>

          {/* Description */}
          <div className="col-span-3">
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Description
            </label>
            <textarea
              className="p-2 border rounded w-full"
              value={formData.description}
              onChange={(e) =>
                setFormData((prev) => ({
                  ...prev,
                  description: e.target.value,
                }))
              }
              rows="3"
            />
          </div>

          {/* Images */}
          <div className="col-span-3">
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Product Images
            </label>

            {formData.images && (
              <div className="mb-2">
                <div className="flex flex-wrap gap-2 mb-2">
                  {formData.images.split(",").map((url, index) => {
                    const trimmedUrl = url.trim();
                    if (trimmedUrl) {
                      return (
                        <img
                          key={index}
                          src={trimmedUrl}
                          alt={`Product image ${index + 1}`}
                          className="h-20 w-20 object-cover border rounded"
                        />
                      );
                    }
                    return null;
                  })}
                </div>
                <p className="text-sm text-gray-500">Current images</p>
              </div>
            )}

            <input
              type="file"
              multiple
              accept="image/*"
              className="p-2 border rounded w-full"
              onChange={handleFileChange}
            />

            <input
              type="text"
              placeholder="Existing Image URLs (comma separated)"
              className="p-2 border rounded w-full mt-2"
              value={formData.images}
              onChange={(e) =>
                setFormData((prev) => ({ ...prev, images: e.target.value }))
              }
            />

            {isUploading && (
              <div className="w-full bg-gray-200 rounded-full h-2.5 mt-2">
                <div
                  className="bg-college-primary h-2.5 rounded-full"
                  style={{ width: `${uploadProgress}%` }}
                ></div>
                <p className="text-sm text-center">
                  Uploading: {uploadProgress}%
                </p>
              </div>
            )}
          </div>

          {/* Form Actions */}
          <div className="col-span-3 flex space-x-4 mt-2">
            <button
              type="submit"
              className="bg-college-primary text-white py-2 px-4 rounded hover:bg-blue-900 flex-grow"
              disabled={isUploading}
            >
              {isUploading
                ? "Uploading..."
                : isEditing
                ? "Save Product"
                : "Add Product"}
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
            {products.map((product) => (
              <tr key={product.id} className="border-b">
                <td className="px-6 py-4">{product.name}</td>
                <td className="px-6 py-4">{product.type}</td>
                <td className="px-6 py-4">₹{product.price.toFixed(2)}</td>
                <td className="px-6 py-4">
                  {product.sizesAvailable.join(", ")}
                </td>
                <td className="px-6 py-4">
                  {product.lastDateToPurchase?.toLocaleDateString()}
                </td>
                <td className="px-6 py-4 space-x-2">
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
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
