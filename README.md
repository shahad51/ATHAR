<div align="center">

# ATHAR
### AI-Powered Lost & Found System for Hajj and Umrah

Smart Lost & Found platform that leverages Artificial Intelligence, GPS tracking, and image matching to help pilgrims recover lost belongings efficiently.

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28)
![TensorFlow Lite](https://img.shields.io/badge/TensorFlow-Lite-orange)
![License](https://img.shields.io/badge/License-Educational-green)

</div>

---

# 📖 Overview

ATHAR is an intelligent Lost & Found mobile application designed specifically for pilgrims performing **Hajj and Umrah**.

Traditional lost-and-found procedures often require manual searching through multiple centers, making the recovery process slow and frustrating.

ATHAR enhances this experience by combining:

- 🤖 AI-powered image matching
- 📍 GPS movement tracking
- 🔔 Real-time notifications
- 🌍 Multilingual support
- 🏢 Integration with Lost & Found Centers

The system enables users to report lost or found items while automatically suggesting potential matches based on image similarity and contextual information.

---

# ✨ Key Features

### 👤 User Features

- Secure Authentication
- Report Lost Items
- Report Found Items
- AI Image Matching
- GPS Route Tracking
- View Matching Results
- Receive Notifications
- Search & Filter Reports
- Multilingual Interface

---

### 🏢 Lost & Found Center

- Review Reports
- Verify Submitted Items
- Update Report Status
- Confirm Matches
- Notify Users

---

### 🛡️ Administrator

- User Management
- Center Management
- Dashboard & Analytics
- System Monitoring
- Reports Overview

---

# 🧠 AI Matching System

ATHAR uses Artificial Intelligence to compare uploaded item images.

The matching process includes:

- Image Feature Extraction
- Cosine Similarity Comparison
- Rule-Based Matching
- Confidence Score Calculation

When image similarity is insufficient, the system applies additional filters such as:

- Item Category
- Item Color
- Estimated Location
- Time of Report

---

# 📍 GPS Tracking

The application continuously records the user's movement (with permission).

When a lost item is reported:

- The system retrieves the user's movement history.
- The user selects the approximate loss location.
- Matching is prioritized based on nearby found items.

This significantly improves matching accuracy.

---

# 🛠️ Technologies Used

## Mobile Development

- Flutter
- Dart

## Backend

- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Firebase Cloud Messaging

## Artificial Intelligence

- TensorFlow Lite
- EfficientNet
- Cosine Similarity

## Maps & Location

- Google Maps
- Geolocator
- Geocoding

## State Management

- Provider

---

# 📱 Application Modules

- Authentication
- GPS Tracking
- Lost Reports
- Found Reports
- AI Matching
- Notifications
- Dashboards
- Center Management
- Admin Panel

---

# 📂 Project Structure

```
lib/
│
├── models/
├── services/
├── providers/
├── screens/
├── widgets/
├── utils/
├── ai/
├── firebase/
└── main.dart
```

---

# 🚀 How to Run

## 1. Clone the repository

```bash
git clone https://github.com/YourUsername/ATHAR.git
```

## 2. Install dependencies

```bash
flutter pub get
```

## 3. Configure Firebase

Create and add:

- google-services.json
- GoogleService-Info.plist

Then enable:

- Authentication
- Firestore
- Storage
- Cloud Messaging

---

## 4. Run the application

```bash
flutter run
```

---

# 📊 System Workflow

1. User logs in.
2. GPS tracking starts (with permission).
3. User submits a Lost or Found report.
4. Images are analyzed using AI.
5. Matching algorithm searches for similar reports.
6. Matching results are displayed.
7. Center verifies the match.
8. User receives a notification.

---

# 📸 Screenshots

> Add application screenshots here.

| Login | Home | Lost Report | AI Match |
|-------|------|------------|----------|
| Image | Image | Image | Image |

---

# 🔮 Future Improvements

- OCR for reading serial numbers.
- QR Code integration.
- Smart chatbot assistant.
- Offline reporting.
- Predictive matching using Deep Learning.
- Integration with Nusuk services.

---

# 👥 Team

- **Shahad Majed Al-Osaimi**
- **Ghala Majed Al-Jaid**
- **Suha Suleiman Al-Khattabi**

Supervisor:

**Dr. Hanan Mohammed Hayat**

---

# 🎓 Academic Project

Bachelor Graduation Project

Software Engineering Department

Umm Al-Qura University
