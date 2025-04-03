import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App'
import { EventProvider } from './context/EventContext'
import './index.css'

class ErrorBoundary extends React.Component {
  state = { hasError: false }

  static getDerivedStateFromError() {
    return { hasError: true }
  }

  componentDidCatch(error, info) {
    console.error('Error caught:', error, info)
  }

  render() {
    if (this.state.hasError) {
      return <div className="error-fallback">Failed to load app</div>
    }
    return this.props.children
  }
}

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <ErrorBoundary>
      <EventProvider>
        <App />
      </EventProvider>
    </ErrorBoundary>
  </React.StrictMode>
)