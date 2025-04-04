## Prerequisites

Before proceeding, ensure the following are installed:

- **Git** (for Flutter SDK management)
- **Visual Studio Code** with the Flutter extension
- **Node.js** (required for Firebase CLI)
- **Firebase CLI** (for initializing and managing Firebase services)

---

## Installation Steps

1. Install Dependencies
Run the following command to install all required dependencies:
```
cd cloud_functions/functions
npm install
```

2. Set Up Firebase
- Log in to Firebase using the CLI:
    ```
    firebase login
    ```
- Initialize Firebase services (Firestore, Functions):
    ```
    firebase init firestore functions
    ```

## Deploy
1. Run `firebase deploy --only functions`