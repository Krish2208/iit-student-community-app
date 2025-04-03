import { createContext, useState, useContext } from 'react'

const AppContext = createContext()

export function AppProvider({ children }) {
  const [stats, setStats] = useState({
    totalEvents: 24,
    merchandiseItems: 156,
    activeUsers: 1234,
    totalRevenue: 54320
  })

  const updateStats = (newStats) => {
    setStats(prev => ({ ...prev, ...newStats }))
  }

  return (
    <AppContext.Provider value={{ stats, updateStats }}>
      {children}
    </AppContext.Provider>
  )
}

export const useAppContext = () => useContext(AppContext)
