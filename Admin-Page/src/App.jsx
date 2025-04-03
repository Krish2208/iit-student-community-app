import React, { useState, useEffect } from "react";
import { HashRouter as Router, Routes, Route, NavLink } from "react-router-dom";
import { onAuthStateChanged, signInWithPopup, GoogleAuthProvider, signOut } from "firebase/auth";
import { auth } from "./firebase-config";
import Dashboard from "./components/Dashboard";
import EventManagement from "./components/EventManagement";
import MerchandiseManagement from "./components/MerchandiseManagement";
import UserManagement from "./components/UserManagement";
import ClubsManagement from "./components/ClubsManagement";
import logo from './assets/iit-indore-logo.png';
import './App.css';

export default function App() {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  // Handle Google Sign-In
  const handleGoogleSignIn = async () => {
    const provider = new GoogleAuthProvider();
    try {
      await signInWithPopup(auth, provider);
    } catch (error) {
      console.error("Error signing in with Google:", error);
    }
  };

  // Handle Logout
  const handleLogout = async () => {
    try {
      await signOut(auth);
    } catch (error) {
      console.error("Error signing out:", error);
    }
  };

  // Persist Authentication State
  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, (currentUser) => {
      setUser(currentUser);
      setLoading(false);
    });
    return () => unsubscribe();
  }, []);

  if (loading) {
    return <div className="flex items-center justify-center h-screen">Loading...</div>;
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {!user ? (
        <div className="flex flex-col items-center justify-center h-screen bg-gray-100">
          <h1 className="text-3xl font-bold mb-6">Admin Login</h1>
          <button
            onClick={handleGoogleSignIn}
            className="bg-blue-500 text-white px-6 py-2 rounded hover:bg-blue-600"
          >
            Sign in with Google
          </button>
        </div>
      ) : (
        <Router>
          {/* Header */}
          <header className="header">
            <div className="flex items-center justify-between px-8 py-4 bg-gray-800 text-white">
              <img src={logo} alt="IIT Indore Logo" className="h-12" />
              <h2 className="text-xl font-bold">College Admin Panel</h2>
              <button
                onClick={handleLogout}
                className="bg-red-500 px-4 py-2 rounded hover:bg-red-600"
              >
                Logout
              </button>
            </div>
          </header>

          {/* Layout */}
          <div className="flex mt-[64px]">
            {/* Sidebar */}
            <nav className="sidebar fixed left-0 top-[64px] h-full w-64 bg-white shadow-lg">
              <div className="p-4">
                <ul className="space-y-2">
                  <li>
                    <NavLink
                      to="/"
                      className={({ isActive }) =>
                        isActive
                          ? "block px-4 py-2 bg-gray-800 text-white rounded"
                          : "block px-4 py-2 hover:bg-gray-200 rounded"
                      }
                    >
                      Dashboard
                    </NavLink>
                  </li>
                  <li>
                    <NavLink
                      to="/events"
                      className={({ isActive }) =>
                        isActive
                          ? "block px-4 py-2 bg-gray-800 text-white rounded"
                          : "block px-4 py-2 hover:bg-gray-200 rounded"
                      }
                    >
                      Events
                    </NavLink>
                  </li>
                  <li>
                    <NavLink
                      to="/merchandise"
                      className={({ isActive }) =>
                        isActive
                          ? "block px-4 py-2 bg-gray-800 text-white rounded"
                          : "block px-4 py-2 hover:bg-gray-200 rounded"
                      }
                    >
                      Merchandise
                    </NavLink>
                  </li>
                  <li>
                    <NavLink
                      to="/clubs"
                      className={({ isActive }) =>
                        isActive
                          ? "block px-4 py-2 bg-gray-800 text-white rounded"
                          : "block px-4 py-2 hover:bg-gray-200 rounded"
                      }
                    >
                      Clubs
                    </NavLink>
                  </li>
                  <li>
                    <NavLink
                      to="/users"
                      className={({ isActive }) =>
                        isActive
                          ? "block px-4 py-2 bg-gray-800 text-white rounded"
                          : "block px-4 py-2 hover:bg-gray-200 rounded"
                      }
                    >
                      Users
                    </NavLink>
                  </li>
                </ul>
              </div>
            </nav>

            {/* Main Content */}
            <main className="ml-[260px] p-8 flex-grow bg-cover bg-center" style={{ backgroundImage: `url('./assets/campus1.jpg')` }}>
              <Routes>
                <Route path="/" element={<Dashboard />} />
                <Route path="/events" element={<EventManagement />} />
                <Route path="/merchandise" element={<MerchandiseManagement />} />
                <Route path="/clubs" element={<ClubsManagement />} />
                <Route path="/users" element={<UserManagement />} />
              </Routes>
            </main>
          </div>
        </Router>
      )}
    </div>
  );
}