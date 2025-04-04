## Prerequisites

Before proceeding, ensure the following are installed:

- **Git** (for Flutter SDK management)
- **Visual Studio Code** with the Flutter extension
- **Node.js** (required for Firebase CLI)
- **Dart SDK** (bundled with Flutter)

---

## 1. Flutter Installation

### 1.1 Download and Configure the Flutter SDK

1. Download the **latest stable Flutter SDK** from the official documentation:
[Flutter Installation Guide](https://docs.flutter.dev/get-started/install)
2. Extract the SDK to a directory (e.g., `C:\dev\flutter` or `~/dev/flutter` on macOS).
3. Add Flutter to your system PATH:

```bash
export PATH="$PATH:/path/to/flutter/bin"
```

4. Validate the installation:

```bash
flutter doctor
```

Resolve any missing dependencies (e.g., Android Studio, Xcode).

---

## 2. Google Cloud Project Setup

### 2.1 Create a GCP Organization and Billing Account

1. Navigate to the [GCP Console](https://console.cloud.google.com/) and create an organization.
2. Link a billing account to the organization.

### 2.2 Enable Required APIs

Activate the following APIs in the GCP Console:

- **Firebase**
- **Google Maps SDK for Android**

---

## 3. FlutterFire CLI Installation

### 3.1 Install Firebase Tools

```bash
npm install -g firebase-tools
firebase --version  # Verify installation
```


### 3.2 Configure [FlutterFire](https://firebase.google.com/docs/flutter/setup)

1. Activate the FlutterFire CLI globally:

```bash
dart pub global activate flutterfire_cli
```

2. Add the FlutterFire CLI to your PATH.

---

## 4. Firebase Project Configuration

### 4.1 Authenticate and Initialize Firebase

1. Log in to Firebase CLI:

```bash
firebase login
```

2. Link your Flutter project to Firebase:

```bash
flutterfire configure
```

Select your Firebase project and target platforms (Android/iOS).

### 4.2 Enable Authentication and Firestore

1. In the [Firebase Console](https://console.firebase.google.com/):
    - Navigate to **Authentication > Sign-in Methods** and enable **Google Sign-In**.
    - Navigate to **Firestore Database** and create a database in **production mode**.
2. Create collections:
    - **clubs**:
    ```json
    {
    "name": "string",
    "description": "string",
    "photoUrl": "string",
    "subscriber": "array"
    }
    ```
    - **events**:

    ```json
    {
    "name": "string",
    "description": "string",
    "photoUrl": "string",
    "organizerId": "string" (It will be id of a clubs document),
    "dateTime": "timestamp",
    "location": "string"
    }
    ```
3. Setup Composite Indexes on the Firestore 
    ```
    events	organizerId Ascending dateTime Ascending __name__ Ascending	Collection		
    ```


Use the Firebase Console’s **+ Start Collection** button.

---

## 5. Google Maps SDK Integration

### 5.1 Configure API Key

1. Obtain a **Google Maps API Key** from the [GCP Console](https://console.cloud.google.com/apis/credentials).
2. Create or modify [`secrets.properties`](https://developers.google.com/maps/documentation/android-sdk/secrets-gradle-plugin) in your project’s root directory:

```properties
MAPS_API_KEY=YOUR_API_KEY
```

---

## 5.2 Configure another API Key

1. Obtain a **Google Maps API Key** from the [GCP Console](https://console.cloud.google.com/apis/credentials).
2. Create a `.env` file similar to `.env.example`
2. Replace the above API key in `GOOGLE_API_KEY` inside the `.env` file.

# 6. RazorPay SDK Integration

1. Obtain a **RazorPay API** from the [RazorPay Console](https://easy.razorpay.com/).
2. Replace the above API key in `RAZORPAY_KEY` inside the `.env` file.

## 6. Build and Deploy

1. Validate all configurations:

```bash
flutter pub get
flutter run -v
```


---

For advanced configurations, refer to the official documentation:

- [Flutter Installation](https://docs.flutter.dev/get-started/install)
- [FlutterFire CLI](https://firebase.google.com/docs/flutter/setup)
