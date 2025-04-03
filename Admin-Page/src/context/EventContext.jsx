import { createContext, useState, useContext } from 'react'

const EventContext = createContext()

export function EventProvider({ children }) {
  const [events, setEvents] = useState([
    {
      id: 1,
      name: 'Tech Fest 2024',
      date: '2024-03-15',
      location: 'Main Auditorium',
      description: 'Annual technical festival',
      participants: 150
    }
  ])

  const addEvent = (newEvent) => {
    setEvents(prev => [...prev, { ...newEvent, id: prev.length + 1 }])
  }

  const updateEvent = (id, updatedEvent) => {
    setEvents(prev => prev.map(event => event.id === id ? {...updatedEvent, id} : event))
  }

  const deleteEvent = (id) => {
    setEvents(prev => prev.filter(event => event.id !== id))
  }

  return (
    <EventContext.Provider value={{ events, addEvent, updateEvent, deleteEvent }}>
      {children}
    </EventContext.Provider>
  )
}

export const useEventContext = () => useContext(EventContext)
