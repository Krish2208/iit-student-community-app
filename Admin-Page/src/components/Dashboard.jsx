import { useState, useEffect } from 'react';
import { db } from '../firebase';
import { collection, getDocs } from 'firebase/firestore';

export default function Dashboard() {
  const [events, setEvents] = useState([]);
  const [merchandise, setMerchandise] = useState([]);
  const [clubs, setClubs] = useState([]);
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);

  // Fetch all data for dashboard
  useEffect(() => {
    const fetchData = async () => {
      try {
        const [eventsSnapshot, merchSnapshot, clubsSnapshot, usersSnapshot] = await Promise.all([
          getDocs(collection(db, 'events')),
          getDocs(collection(db, 'merchandise')),
          getDocs(collection(db, 'clubs')),
          getDocs(collection(db, 'users'))
        ]);

        setEvents(eventsSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
        setMerchandise(merchSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
        setClubs(clubsSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
        setUsers(usersSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
      } catch (error) {
        console.error("Error fetching dashboard data:", error);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  if (loading) {
    return <div className="flex justify-center items-center h-64">Loading dashboard data...</div>;
  }

  // Calculate statistics
  const stats = [
    { 
      title: 'Total Events', 
      value: events.length, 
      color: 'bg-blue-100 text-blue-800',
      icon: '📅'
    },
    { 
      title: 'Event Participants', 
      value: events.reduce((sum, event) => sum + (Number(event.participants) || 0), 0), 
      color: 'bg-green-100 text-green-800',
      icon: '👥'
    },
    { 
      title: 'Merchandise Items', 
      value: merchandise.length, 
      color: 'bg-purple-100 text-purple-800',
      icon: '👕'
    },
    { 
      title: 'Active Clubs', 
      value: clubs.filter(club => club.status === 'active').length, 
      color: 'bg-yellow-100 text-yellow-800',
      icon: '🏛️'
    },
    { 
      title: 'Total Users', 
      value: users.length, 
      color: 'bg-red-100 text-red-800',
      icon: '👤'
    },
    { 
      title: 'Admin Users', 
      value: users.filter(user => user.role === 'admin').length, 
      color: 'bg-indigo-100 text-indigo-800',
      icon: '🔒'
    }
  ];

  // Recent activities data
  const recentActivities = [
    ...events.slice(0, 3).map(event => ({
      type: 'event',
      title: event.name,
      date: event.date,
      description: `Scheduled for ${event.location} with ${event.participants} participants`
    })),
    ...merchandise.slice(0, 2).map(item => ({
      type: 'merchandise',
      title: item.name,
      date: 'Recently added',
      description: `${item.stock} in stock at ₹${item.price} each`
    })),
    ...clubs.slice(0, 2).map(club => ({
      type: 'club',
      title: club.name,
      date: 'Active',
      description: `Meets ${club.meetingSchedule} - ${club.category} club`
    }))
  ].sort((a, b) => new Date(b.date) - new Date(a.date)).slice(0, 5);

  return (
    <div className="space-y-8">
      <h1 className="text-3xl font-bold text-college-primary">Dashboard Overview</h1>
      
      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6 gap-4">
        {stats.map((stat, index) => (
          <div key={index} className={`p-4 rounded-lg shadow ${stat.color}`}>
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium">{stat.title}</p>
                <p className="text-2xl font-bold">{stat.value}</p>
              </div>
              <span className="text-2xl">{stat.icon}</span>
            </div>
          </div>
        ))}
      </div>

      {/* Quick Overview Sections */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Upcoming Events */}
        <div className="bg-white p-6 rounded-lg shadow-sm">
          <h2 className="text-xl font-semibold mb-4 flex items-center">
            <span className="mr-2">📅</span> Upcoming Events
          </h2>
          <div className="space-y-4">
            {events.slice(0, 3).map(event => (
              <div key={event.id} className="border-b pb-3 last:border-0">
                <h3 className="font-medium">{event.name}</h3>
                <p className="text-sm text-gray-600">{event.date} at {event.location}</p>
                <p className="text-sm">{event.participants} participants</p>
              </div>
            ))}
            {events.length === 0 && <p className="text-gray-500">No upcoming events</p>}
          </div>
        </div>

        {/* Merchandise Status */}
        <div className="bg-white p-6 rounded-lg shadow-sm">
          <h2 className="text-xl font-semibold mb-4 flex items-center">
            <span className="mr-2">🛍️</span> Merchandise Status
          </h2>
          <div className="space-y-4">
            {merchandise.slice(0, 3).map(item => (
              <div key={item.id} className="border-b pb-3 last:border-0">
                <div className="flex justify-between items-center">
                  <h3 className="font-medium">{item.name}</h3>
                  <span className={`px-2 py-1 text-xs rounded-full ${
                    item.status === 'available' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
                  }`}>
                    {item.status}
                  </span>
                </div>
                <p className="text-sm">₹{item.price} • {item.stock} in stock</p>
              </div>
            ))}
            {merchandise.length === 0 && <p className="text-gray-500">No merchandise items</p>}
          </div>
        </div>
      </div>

      {/* Recent Activities */}
      <div className="bg-white p-6 rounded-lg shadow-sm">
        <h2 className="text-xl font-semibold mb-4 flex items-center">
          <span className="mr-2">🔄</span> Recent Activities
        </h2>
        <div className="space-y-4">
          {recentActivities.map((activity, index) => (
            <div key={index} className="border-l-4 border-blue-500 pl-4 py-2">
              <div className="flex justify-between items-start">
                <div>
                  <h3 className="font-medium">{activity.title}</h3>
                  <p className="text-sm text-gray-600">{activity.description}</p>
                </div>
                <span className="text-xs bg-gray-100 px-2 py-1 rounded">
                  {activity.type} • {activity.date}
                </span>
              </div>
            </div>
          ))}
          {recentActivities.length === 0 && <p className="text-gray-500">No recent activities</p>}
        </div>
      </div>

      {/* Active Clubs */}
      <div className="bg-white p-6 rounded-lg shadow-sm">
        <h2 className="text-xl font-semibold mb-4 flex items-center">
          <span className="mr-2">🏛️</span> Active Clubs
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {clubs.filter(club => club.status === 'active').slice(0, 6).map(club => (
            <div key={club.id} className="border rounded-lg p-4 hover:shadow-md transition-shadow">
              <h3 className="font-medium">{club.name}</h3>
              <p className="text-sm text-gray-600 capitalize">{club.category}</p>
              <p className="text-sm mt-2">{club.description.substring(0, 80)}...</p>
              <p className="text-xs text-gray-500 mt-2">Meets: {club.meetingSchedule}</p>
            </div>
          ))}
          {clubs.filter(club => club.status === 'active').length === 0 && (
            <p className="text-gray-500">No active clubs</p>
          )}
        </div>
      </div>
    </div>
  );
}