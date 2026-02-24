# Athar (أثر) - Smart Lost & Found System

A Flutter mobile application for Hajj & Umrah pilgrims to report and find lost items.

## Features

### For Regular Users (Pilgrims)
- Report lost items with details and optional images
- Report found items with photos and location
- AI-powered image matching to find potential matches
- GPS tracking for location validation
- Search and filter through found items
- Real-time notifications for matches
- Directions to nearest Lost & Found centers

### For Employees (Lost & Found Center Staff)
- Submit reports on behalf of pilgrims
- View and manage all reports
- Update report status (Matched/Rejected)
- View action history

### For Administrators
- Dashboard with real-time statistics
- Charts showing reports by status
- View all reports submitted by centers
- Send maintenance notifications to all users

### For Managers
- Review and approve/reject elevated account requests
- Manage admin and employee account activations
- View decision history

## Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase
  - Firebase Authentication
  - Cloud Firestore
  - Firebase Storage
  - Firebase Cloud Messaging (FCM)
- **Maps**: Google Maps Flutter Plugin, Google Directions API
- **AI/ML**: TensorFlow Lite (for image feature extraction)
- **State Management**: Provider

## Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_constants.dart
│   │   └── app_colors.dart
│   ├── theme/
│   │   └── app_theme.dart
│   ├── localization/
│   │   └── app_localizations.dart
│   └── utils/
│       ├── validators.dart
│       └── helpers.dart
├── models/
│   ├── user_model.dart
│   ├── report_model.dart
│   ├── movement_history_model.dart
│   ├── elevated_request_model.dart
│   ├── notification_model.dart
│   ├── location_model.dart
│   ├── history_model.dart
│   └── login_log_model.dart
├── services/
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   ├── storage_service.dart
│   ├── gps_service.dart
│   ├── notification_service.dart
│   ├── ai_matching_service.dart
│   └── maps_service.dart
├── providers/
│   ├── auth_provider.dart
│   ├── locale_provider.dart
│   └── reports_provider.dart
├── screens/
│   ├── auth/
│   ├── regular_user/
│   ├── employee/
│   ├── admin/
│   ├── manager/
│   └── shared/
├── widgets/
│   ├── custom_text_field.dart
│   ├── custom_button.dart
│   ├── loading_widget.dart
│   ├── empty_state_widget.dart
│   └── report_card.dart
└── main.dart
```

## Setup Instructions

### Prerequisites
- Flutter SDK (>=3.0.0)
- Firebase CLI
- Android Studio / Xcode
- Google Cloud Console account (for Maps API)

### 1. Firebase Setup
1. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com)
2. Enable the following services:
   - Authentication (Email/Password)
   - Cloud Firestore
   - Firebase Storage
   - Cloud Messaging
3. Download `google-services.json` (Android) and place in `android/app/`
4. Download `GoogleService-Info.plist` (iOS) and place in `ios/Runner/`

### 2. Google Maps Setup
1. Enable the following APIs in Google Cloud Console:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Directions API
2. Create an API key and add it to:
   - `android/app/src/main/AndroidManifest.xml`:
     ```xml
     <meta-data
         android:name="com.google.android.geo.API_KEY"
         android:value="AIzaSyBogqnASso-oa85MSmbd3OdGCNSdpvI7oA"/>
     ```
   - `ios/Runner/AppDelegate.swift`:
     ```swift
     GMSServices.provideAPIKey("AIzaSyBogqnASso-oa85MSmbd3OdGCNSdpvI7oA")
     ```
3. Update the API key in `lib/services/maps_service.dart`

### 3. Install Dependencies
```bash
cd app
flutter pub get
```

### 4. Deploy Firestore Security Rules
```bash
firebase deploy --only firestore:rules
```

### 5. Run the App
```bash
flutter run
```

## Firestore Collections

| Collection | Description |
|------------|-------------|
| `users` | User profiles and authentication data |
| `reports` | Lost and found item reports |
| `movementHistory` | GPS tracking data for users |
| `elevatedAccountRequests` | Pending admin/employee account requests |
| `notifications` | In-app notifications |
| `locations` | Lost & Found center locations |
| `history` | Action logs for admins/employees |
| `loginLogs` | Login attempt records |

## User Roles

| Role | Activation | Capabilities |
|------|------------|--------------|
| Regular | Auto-activated | Report items, search, track |
| Employee | Manager approval | Submit on behalf, update status |
| Admin | Manager approval | Dashboard, analytics, notifications |
| Manager | Pre-configured | Approve/reject accounts |

## Localization

The app supports:
- English (en)
- Arabic (ar) - with RTL support

Default language is Arabic.

## AI Image Matching

The app uses TensorFlow Lite for on-device image feature extraction. The matching algorithm:
1. Extracts feature vectors from item images
2. Computes cosine similarity between vectors
3. Returns matches above the threshold (0.6)

**Note**: The current implementation uses placeholder/simulated AI. For production, integrate a real TFLite model (e.g., MobileNet) in `assets/models/`.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is developed for graduation purposes.

## Contact

For support, contact: support@athar.app
