import { initializeApp } from "firebase/app";
import { getAuth, GoogleAuthProvider } from "firebase/auth";
import { getFirestore } from "firebase/firestore"; // Add this

const firebaseConfig = {
  apiKey: "<YOUR-API-KEY>",
  authDomain: "iit-indore-student.firebaseapp.com",
  projectId: "iit-indore-student",
  storageBucket: "iit-indore-student.appspot.com",
  messagingSenderId: "<YOUR-MESSAGING-SENDER-ID>",
  appId: "<YOUR-APP-ID>",
  measurementId: "G-27QP57MMKX"
};

const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getFirestore(app); // Export Firestore
export const googleProvider = new GoogleAuthProvider();
