# IITI Student Community App

A Flutter-based platform for managing student clubs, events, and community engagement at IITI. Integrated with Firebase for real-time data and Google Cloud Platform for enterprise-grade infrastructure.

## 📥 Installation
### Prerequisites
- Flutter 
- Dart
- Firebase CLI
- Google Cloud SDK

Follow our detailed setup guide:  
1. [Flutter Installation Guide](./FlutterInstallationREADME.md)
2. [Admin Page Installation Guide](./AdminPageInstallationREADME.md)
3. [Cloud Functions Installation Guide](./CloudFunctionsInstallationREADME.md)

## 🛠 Tech Stack
**Core Framework**  
- Flutter

**Backend Services**  
- Firebase Authentication  
- Cloud Firestore (NoSQL Database)  
- Google Maps SDK for Android/iOS

## 📁 Code Structure
```
/app/iiti_student_community/lib
├── main.dart                      # Application entry point
├── components/                   # Reusable UI components
│   ├── club_events.dart           # Club-event association widget
│   ├── clubs_grid.dart            # Grid layout for club display
│   ├── club_tile.dart             # Individual club card component
│   ├── event_card.dart            # Event display card
│   ├── events_list.dart           # Scrollable events list
│   └── subscribed_event.dart      # User-subscribed events UI
├── models/                       # Data models
│   ├── club.dart                  # Club entity model
│   ├── event.dart                 # Event entity model
│   └── discussion_board.dart      # Discussion board model
├── screens/                      # Application views
│   ├── clubs_details_screen.dart  # Club-specific details
│   ├── discussion_board_screen.dart  # Discussion board
│   ├── home_screen.dart           # Primary dashboard (now includes discussion board tab)
│   ├── login_screen.dart          # Authentication interface
│   ├── map_view.dart              # Google Maps integration
│   └── tabs/                     # Navigation tab components
│       ├── clubs_events.dart      # Combined clubs/events view
│       ├── home_tab.dart          # Default landing tab
│       ├── notifications_tab.dart # User alerts
│       ├── profile_tab.dart       # User profile management
│       ├── settings_tab.dart      # Application configuration
│       ├── ride_sharing_tab.dart  # Ride sharing feature tab
│       ├── merchandise_tab.dart   # Club merchandise view
│       └── discussion_board_tab.dart # Discussion board tab
├── services/                     # Business logic layer
│   └── auth_service.dart          # Authentication workflows
```

