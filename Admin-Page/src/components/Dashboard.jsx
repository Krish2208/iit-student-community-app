import { useState, useEffect } from 'react';
import { db } from '../firebase';
import { collection, getDocs } from 'firebase/firestore';

export default function Dashboard() {
  const [events, setEvents] = useState([]);
  const [merchandise, setMerchandise] = useState([]);
  const [clubs, setClubs] = useState([]);
  const [loading, setLoading] = useState(true);

  // Fetch all data for dashboard
  useEffect(() => {
    const fetchData = async () => {
      try {
        const [eventsSnapshot, merchSnapshot, clubsSnapshot] = await Promise.all([
          getDocs(collection(db, 'events')),
          getDocs(collection(db, 'merchandise')),
          getDocs(collection(db, 'clubs')),
        ]);

        const eventsData = eventsSnapshot.docs.map(doc => ({ 
          id: doc.id, 
          ...doc.data(),
          // Convert Firestore Timestamp to Date if needed
          date: doc.data().date?.toDate ? doc.data().date.toDate() : new Date(doc.data().date)
        }));
        
        setEvents(eventsData);
        setMerchandise(merchSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
        setClubs(clubsSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
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

  // Filter events to only include future dates
  const upcomingEvents = events.filter(event => {
    const eventDate = new Date(event.date);
    const today = new Date();
    today.setHours(0, 0, 0, 0); // Reset time to midnight for accurate date comparison
    return eventDate >= today;
  });

  // Calculate statistics
  const stats = [
    { 
      title: 'Total Events', 
      value: events.length, 
      color: 'bg-blue-100 text-blue-800',
      icon: '📅'
    },
    { 
      title: 'Upcoming Events', 
      value: upcomingEvents.length,
      color: 'bg-green-100 text-green-800',
      icon: '📌'
    },
    { 
      title: 'Merchandise Items', 
      value: merchandise.length, 
      color: 'bg-purple-100 text-purple-800',
      icon: '👕'
    },
    { 
      title: 'Active Clubs', 
      value: clubs.length, 
      color: 'bg-yellow-100 text-yellow-800',
      icon: '🏛️'
    }
  ];

  // Recent activities data
  const recentActivities = [
    ...upcomingEvents.slice(0, 3).map(event => ({
      type: 'event',
      title: event.name,
      date: event.date.toLocaleDateString(),
      description: `At ${event.location}`
    })),
    ...merchandise.slice(0, 2).map(item => ({
      type: 'merchandise',
      title: item.name,
      date: 'Recently added',
      description: `₹${item.price}`
    })),
    ...clubs.slice(0, 2).map(club => ({
      type: 'club',
      title: club.name,
      date: 'Recently added',
      description: club.description?.substring(0, 50) + (club.description?.length > 50 ? '...' : '')
    }))
  ].sort((a, b) => new Date(b.date) - new Date(a.date)).slice(0, 5);

  return (
    <div className="space-y-8">
      <h1 className="text-3xl font-bold text-college-primary">Dashboard Overview</h1>
      
      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
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
        {/* Upcoming Events - Now only shows future events */}
        <div className="bg-white p-6 rounded-lg shadow-sm">
          <h2 className="text-xl font-semibold mb-4 flex items-center">
            <span className="mr-2">📅</span> Upcoming Events
          </h2>
          <div className="space-y-4">
            {upcomingEvents
              .sort((a, b) => new Date(a.date) - new Date(b.date))
              .slice(0, 3)
              .map(event => (
                <div key={event.id} className="border-b pb-3 last:border-0">
                  <h3 className="font-medium">{event.name}</h3>
                  <p className="text-sm text-gray-600">
                    {event.date.toLocaleDateString()} at {event.location}
                  </p>
                </div>
              ))}
            {upcomingEvents.length === 0 && (
              <p className="text-gray-500">No upcoming events scheduled</p>
            )}
          </div>
        </div>

        {/* Merchandise Items */}
        <div className="bg-white p-6 rounded-lg shadow-sm">
          <h2 className="text-xl font-semibold mb-4 flex items-center">
            <span className="mr-2">🛍️</span> Recent Merchandise
          </h2>
          <div className="space-y-4">
            {merchandise.slice(0, 3).map(item => (
              <div key={item.id} className="border-b pb-3 last:border-0">
                <div className="flex justify-between items-center">
                  <h3 className="font-medium">{item.name}</h3>
                  <span className="text-sm">₹{item.price}</span>
                </div>
                <p className="text-sm text-gray-600">{item.type}</p>
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
    </div>
  );
}