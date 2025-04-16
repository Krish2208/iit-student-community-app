## Prerequisites

Before proceeding, ensure the following are installed:

- **Git** (for Flutter SDK management)
- **Visual Studio Code** with the Flutter extension
- **Node.js** (required for Firebase CLI)
- **Firebase CLI** (for initializing and managing Firebase services)

---

## Environment Configuration
Create a `.env` file in the root directory of your project by copying the `.env.example` file. Replace `<YOUR_FIREBASE_API_KEY>`, `<YOUR_FIREBASE_MESSAGING_SENDER_ID>`, and `<YOUR_FIREBASE_APP_ID>` with your Firebase project credentials. Replace `<YOUR_MAPS_API_KEY>` with your Google Cloud Maps SDK API key.

## Installation Steps

1. Install Dependencies
Run the following command to install all required dependencies:
```
cd Admin-Page
npm install
```

2. Set Up Firebase
- Log in to Firebase using the CLI:
    ```
    firebase login
    ```
- Initialize Firebase services (Firestore, Storage, Authentication):
    ```
    firebase init firestore storage auth
    ```

## Development
1. Run build command `npm run build`
2. Run preview command `npm run preview`