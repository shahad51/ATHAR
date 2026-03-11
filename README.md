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

## Core Features - Technical Details

### 1. GPS Tracking System

The GPS tracking system is a cornerstone feature that helps validate user locations and build movement history for pilgrims during Hajj/Umrah.

#### How It Works:
1. **Permission Management**: 
   - Requests location permissions using `permission_handler`
   - Checks if location services are enabled
   - Guides users to settings if permissions are permanently denied

2. **Real-time Tracking**:
   - Uses `geolocator` package with high accuracy mode
   - Streams position updates with 100-meter distance filter (reduces battery drain)
   - Automatically saves location entries to Firestore

3. **Smart Location Recognition**:
   - Detects proximity to known Hajj sites (Mina, Arafat, Muzdalifah, Masjid Al-Haram, Jamarat)
   - Uses 2km radius for site detection
   - Calculates distance using Haversine formula via `Geolocator.distanceBetween()`

4. **Data Storage**:
   - Creates `MovementHistoryModel` with location entries
   - Each entry includes: location name, lat/lng coordinates, timestamp, transport method
   - Stores in Firestore `movementHistory` collection indexed by userId

5. **Manual Entry Fallback**:
   - If GPS permission denied, users can manually enter visited locations
   - Marked with `isManualEntry: true` flag

**Key Files**:
- `lib/services/gps_service.dart` - Core GPS logic
- `lib/models/movement_history_model.dart` - Data structure
- `lib/screens/regular_user/gps_tracking_screen.dart` - UI

---

### 2. AI Image Matching System

The AI-powered image matching is the second cornerstone that helps match lost items with found items using computer vision.

#### How It Works:

**Model**: EfficientNet-Lite0 (TensorFlow Lite)
- **Size**: 18.5 MB (FP32 version)
- **Input**: 224x224 RGB images
- **Output**: 1000-dimensional feature vector
- **Accuracy**: 75.1% on ImageNet
- **Optimized for**: Mobile devices (12ms CPU latency on Pixel 4)

#### Processing Pipeline:

1. **Image Upload & Feature Extraction**:
   ```
   User uploads image → Resize to 224x224 → Normalize [0,1]
   → Run through EfficientNet-Lite0 → Extract 1000-dim vector
   → L2 normalize → Store in Firestore with report
   ```

2. **Image Preprocessing**:
   - Decodes image using `image` package
   - Resizes to 224x224 pixels (model input size)
   - Converts to float array with RGB channels
   - Normalizes pixel values to [0, 1] range

3. **Feature Vector Extraction**:
   - Runs image through TFLite interpreter
   - Outputs 1000-dimensional feature vector (classification logits)
   - Applies L2 normalization for better similarity comparison
   - Stores normalized vector in Firestore `reports` collection

4. **Matching Algorithm**:
   - When user searches with image, extracts query feature vector
   - Compares against all found item vectors using **Cosine Similarity**:
     ```
     similarity = (A · B) / (||A|| × ||B||)
     ```
   - Filters matches above threshold (default: 0.7 = 70% similarity)
   - Sorts results by confidence score (descending)

5. **Search Flow**:
   ```
   Query image → Extract features → Compare with all found items
   → Calculate cosine similarity → Filter by threshold
   → Sort by confidence → Return top matches
   ```

#### Why EfficientNet-Lite0?
- **Mobile-optimized**: Removed squeeze-excite layers, uses ReLU6 instead of Swish
- **Fast inference**: 12ms on mobile CPU
- **Small size**: 4.7M parameters vs 25M+ in standard models
- **Good accuracy**: 75.1% while being lightweight
- **Better than alternatives**: Outperforms MobileNetV2 and ResNet-50 at similar latency

#### Threshold Configuration:
- Located in `lib/core/constants/app_constants.dart`
- `aiMatchThreshold: 0.7` (70% similarity required)
- Adjustable based on precision/recall requirements

**Key Files**:
- `lib/services/ai_matching_service.dart` - AI logic and TFLite integration
- `assets/models/image_embedding_model.tflite` - EfficientNet-Lite0 model
- `lib/providers/reports_provider.dart` - Orchestrates matching flow
- `lib/screens/regular_user/search_screen.dart` - Search UI

#### Dependencies:
- `tflite_flutter: ^0.10.4` - TFLite runtime
- `image: ^4.1.7` - Image preprocessing

---

## Performance Considerations

**GPS Tracking**:
- Distance filter (100m) reduces unnecessary updates
- Background tracking supported via foreground service
- Minimal battery impact with optimized settings

**AI Matching**:
- On-device inference (no server calls)
- ~12-50ms per image on modern devices
- Feature vectors cached in Firestore (no re-computation)
- Efficient cosine similarity (O(n) where n = vector dimension)

---

## Exception Handling

The app implements comprehensive exception handling for three critical scenarios:

### 1. Lost Phone Scenario

**Problem**: User cannot access the app if their phone is the lost item.

**Solutions Implemented**:
- ✅ **Employee Reporting**: Lost & Found center employees can create reports on behalf of users
- ✅ **Reference ID System**: Each report gets a unique, user-friendly Reference ID (format: `ATH-YYYY-XXXXXX`)
- ✅ **Public Tracking**: Users can track reports without login using the Reference ID
- ✅ **Reference ID Display**: Employees receive the Reference ID after submission to provide to the user

**How to Use**:
1. User visits Lost & Found center
2. Employee creates report via `EmployeeAddReportScreen`
3. System generates Reference ID (e.g., `ATH-2024-123456`)
4. Employee provides Reference ID to user
5. User can track report from login screen → "Track Report with Reference ID"

**Key Files**:
- `lib/screens/employee/employee_add_report_screen.dart` - Employee report submission
- `lib/screens/shared/track_report_screen.dart` - Public tracking interface
- `lib/core/utils/helpers.dart` - Reference ID generator

---

### 2. Location Permission Denied

**Problem**: User denies GPS permission, reducing app functionality.

**Solutions Implemented**:
- ✅ **Manual Entry Fallback**: Users can manually enter visited locations
- ✅ **Warning Messages**: Clear warnings displayed when permission denied
- ✅ **Continued Functionality**: Reporting remains available with reduced accuracy
- ✅ **Permission Banner**: Persistent banner shows when GPS disabled

**Warning Message**:
> "Matching accuracy and nearby center suggestions will be reduced until location access is enabled."

**How It Works**:
1. User denies GPS permission
2. System shows warning dialog with manual entry option
3. `GpsPermissionBanner` displays in report screens
4. User can enter locations manually via `GpsTrackingDialog`
5. Manual entries marked with `isManualEntry: true` flag

**Key Files**:
- `lib/screens/regular_user/gps_tracking_dialog.dart` - GPS setup with manual fallback
- `lib/widgets/gps_permission_banner.dart` - Warning banner component
- `lib/services/gps_service.dart` - Permission handling

---

### 3. Location Permission Changed Later

**Problem**: User grants permission initially, then revokes it from device settings.

**Solutions Implemented**:
- ✅ **Automatic Detection**: `PermissionMonitor` detects permission changes using `AppLifecycleState`
- ✅ **Data Preservation**: Previously stored GPS data remains in Firestore
- ✅ **Warning Dialog**: Shows when permission revoked after app resume
- ✅ **Continued Service**: App remains functional with manual entry

**How It Works**:
1. `PermissionMonitor` observes app lifecycle state
2. When app resumes, checks current permission status
3. If permission changed from granted → denied:
   - Shows warning dialog
   - Notifies user of reduced functionality
   - Preserves existing location data
4. User can continue using app with manual entry

**Key Files**:
- `lib/widgets/permission_monitor.dart` - Lifecycle-based permission monitoring
- `lib/services/gps_service.dart` - Permission checking

---

## Exception Handling Summary

| Scenario | Solution | User Experience |
|----------|----------|-----------------|
| Lost Phone | Reference ID tracking | Can track report from any device without login |
| Permission Denied | Manual entry + warnings | Can still use app with reduced accuracy |
| Permission Revoked | Auto-detection + warnings | Data preserved, manual entry available |

All three scenarios ensure the app remains functional and user-friendly even in exceptional circumstances.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is developed for graduation purposes.

## Contact

For support, contact: support@athar.app
