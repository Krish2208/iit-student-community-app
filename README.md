# IITI Student Community App

A Flutter-based platform for managing student clubs, events, and community engagement at IITI. Integrated with Firebase for real-time data and Google Cloud Platform for enterprise-grade infrastructure.

## 📅 Installation
### Prerequisites
- Flutter  
- Dart  
- Node.js  
- Firebase CLI  
- Google Cloud SDK  

Follow our detailed setup guide:  
1. [Flutter Installation Guide](./FlutterInstallationREADME.md)  
2. [Admin Page Installation Guide](./AdminPageInstallationREADME.md)  
3. [Cloud Functions Installation Guide](./CloudFunctionsInstallationREADME.md)  

## 🛠 Tech Stack
**Core Framework**  
- Flutter  
- Node.js  
- React.js  

**Backend Services**  
- Firebase Authentication  
- Cloud Firestore (NoSQL Database)  
- Firebase Storage  
- Firebase Cloud Messaging  
- Razorpay API  
- Google Maps SDK for Android/iOS  
- Google Places SDK  
- Google Geocode SDK
- Local Calendar Service (Google Calendar for Android, Apple Calendar for iOS)

## 📁 Code Structure
```
/app/iiti_student_community/lib
├── main.dart                                 # Application entry point
├── components/                               # Reusable UI components
│   ├── club_events.dart                      # Club-event association widget
│   ├── club_tile.dart                        # Individual club card component
│   ├── clubs_grid.dart                       # Grid layout for club display
│   ├── event_card.dart                       # Event display card
│   ├── events_list.dart                      # Scrollable events list
│   ├── location_picker.dart                  # Location selector widget
│   ├── map_view.dart                         # Google Maps integration
│   └── subscribed_event.dart                 # User-subscribed events UI
├── models/                                   # Data models
│   ├── club.dart                             # Club entity model
│   ├── discussion_board.dart                 # Discussion Board Post model
│   ├── event.dart                            # Event entity model
│   ├── places_suggestion.dart                # Location autocomplete results
│   ├── product.dart                          # Merchandise item model
│   ├── ride_request.dart                     # Ride-sharing request model
│   └── user.dart                             # User entity model
├── screens/                                  # Application views
│   ├── clubs_details_screen.dart             # Club-specific details
│   ├── discussion_board_screen.dart          # Discussion Post Screen
│   ├── event_details_screen.dart             # Event-specific details
│   ├── home_screen.dart                      # Primary dashboard
│   ├── login_screen.dart                     # Authentication interface
│   ├── map_view.dart                         # Google Maps integration
│   ├── product_details_screen.dart           # Product info view
│   ├── purchase_screen.dart                  # Purchase interface
│   └── ride_request_screen.dart              # Ride-sharing screen
├── screens/tabs/                             # Navigation tab components
│   ├── clubs_events.dart                     # Combined clubs/events view
│   ├── discussion_board_tab.dart             # Discussion Board tab
│   ├── home_tab.dart                         # Default landing tab
│   ├── merchandise_tab.dart                  # Shop tab for merchandise
│   ├── profile_tab.dart                      # User profile management
│   └── ride_sharing_tab.dart                 # Ride-sharing tab
├── services/                                 # Business logic layer
│   ├── auth_service.dart                     # Authentication workflows
│   ├── calendar_service.dart                 # Calendar-based event logic
│   └── notification_service.dart             # Push notification handler
└── wrappers/
    └── auth_wrapper.dart                     # Auth state management wrapper

/cloud_functions/functions
├── .eslintrc.js                              # Linting configuration
├── index.js                                  # Firebase Cloud Functions entry
├── package-lock.json                         # Package lock
└── package.json                              # Cloud Functions dependencies

/Admin-Page/src
├── App.css                                   # App styling
├── App.jsx                                   # App root component
├── firebase-config.js                        # Firebase environment config
├── firebase.js                               # Firebase initialization
├── index.css                                 # Global styling
├── main.jsx                                  # App entry point
├── components/
│   ├── ClubsManagement.jsx                   # Club management UI
│   ├── Dashboard.jsx                         # Admin dashboard
│   ├── EventManagement.jsx                   # Event management UI
│   ├── Login.jsx                             # Admin login
│   └── MerchandiseManagement.jsx             # Merchandise admin view
├── context/
│   ├── AppContext.jsx                        # App-wide state management
│   └── EventContext.jsx                      # Event-specific state handling
└── security/
    └── firestore.rules                       # Firestore access rules

```
