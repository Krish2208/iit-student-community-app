import { initializeApp } from "firebase/app";
import { getAuth, GoogleAuthProvider } from "firebase/auth";
import { getFirestore } from "firebase/firestore"; // Add this

const firebaseConfig = {
  apiKey: "AIzaSyBArirzumw8JOSfNK-GL9KTR2iObUUGE2A",
  authDomain: "iit-indore-student.firebaseapp.com",
  projectId: "iit-indore-student",
  storageBucket: "iit-indore-student.appspot.com",
  messagingSenderId: "490374910464",
  appId: "1:490374910464:web:88939bb5239a3d7b6efee5",
  measurementId: "G-27QP57MMKX"
};

const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getFirestore(app); // Export Firestore
export const googleProvider = new GoogleAuthProvider();
