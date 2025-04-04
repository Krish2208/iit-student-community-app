# IITI Student Community App

A Flutter-based platform for managing student clubs, events, and community engagement at IITI. Integrated with Firebase for real-time data and Google Cloud Platform for enterprise-grade infrastructure.

## 📥 Installation
### Prerequisites
- Flutter
- Dart
- Firebase CLI
- Google Cloud SDK
- Node.js

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
- Google Maps SDK for Android/iOS  
- Razorpay API  
- Firebase Storage  
- Firebase Cloud Messaging  
- Google Places SDK  
- Google Geocode SDK  

## 📁 Code Structure
```
/cloud_functions/functions
├── index.js # Cloud functions entry point
├── utils/ # Helper utilities
│   ├── notifications.js # Push notifications logic
│   ├── payments.js # Razorpay API integration
│   └── database.js # Firestore queries
└── triggers/ # Firestore event triggers
    ├── onUserSignup.js # User sign-up trigger
    └── onClubCreation.js # Club creation trigger

/Admin-Page/src
├── components/ # React UI components
│   ├── Dashboard.js # Admin dashboard
│   ├── ClubsManagement.js # Club management UI
│   ├── EventsManagement.js # Events panel
│   └── UsersList.js # Registered users list
├── services/ # API calls & business logic
│   ├── authService.js # Authentication workflows
│   ├── eventService.js # Event CRUD operations
│   ├── paymentService.js # Razorpay integrations
│   └── notificationService.js # Firebase notifications
└── pages/ # Admin page views
    ├── HomePage.js # Admin home page
    ├── LoginPage.js # Authentication page
    ├── ClubPage.js # Manage individual clubs
    └── SettingsPage.js # Admin settings

/app/iiti_student_community/lib
├── main.dart # Application entry point
├── components/ # Reusable UI components
│   ├── club_events.dart # Club-event association widget
│   ├── clubs_grid.dart # Grid layout for club display
│   ├── club_tile.dart # Individual club card component
│   ├── event_card.dart # Event display card
│   ├── events_list.dart # Scrollable events list
│   └── subscribed_event.dart # User-subscribed events UI
├── models/ # Data models
│   ├── club.dart # Club entity model
│   └── event.dart # Event entity model
├── screens/ # Application views
│   ├── clubs_details_screen.dart # Club-specific details
│   ├── home_screen.dart # Primary dashboard
│   ├── login_screen.dart # Authentication interface
│   ├── map_view.dart # Google Maps integration
│   └── tabs/ # Navigation tab components
│       ├── clubs_events.dart # Combined clubs/events view
│       ├── home_tab.dart # Default landing tab
│       ├── notifications_tab.dart # User alerts
│       ├── profile_tab.dart # User profile management
│       └── settings_tab.dart # Application configuration
└── services/ # Business logic layer
    └── auth_service.dart # Authentication workflows
```
