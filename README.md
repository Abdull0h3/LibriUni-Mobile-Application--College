# 📚 LibriUni - College Library Management System

<div align="center">
  <img src="assets/libriuni_logo_combination.png" alt="LibriUni Logo" width="200"/>
  
  [![Flutter](https://img.shields.io/badge/Flutter-3.7+-02569B?logo=flutter)](https://flutter.dev)
  [![Firebase](https://img.shields.io/badge/Firebase-Enabled-orange?logo=firebase)](https://firebase.google.com)
  [![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
  
  **A modern, comprehensive library management mobile application built with Flutter for universities and colleges.**
</div>

---

## 🎯 Overview

LibriUni is a feature-rich, cross-platform mobile application designed to revolutionize library management in educational institutions. Built with Flutter and powered by Firebase, it provides a seamless experience for students, library staff, and administrators to manage books, room bookings, fines, and communications—all in one place.

### Why LibriUni?

Traditional library systems are often outdated, desktop-bound, and lack modern user experiences. LibriUni addresses these challenges by:

- **📱 Mobile-First Design**: Access library services anywhere, anytime from your smartphone
- **👥 Role-Based Access**: Tailored interfaces for students, staff, and administrators
- **⚡ Real-Time Updates**: Instant notifications for due dates, room bookings, and library news
- **🔍 Smart Search**: Quickly find books with advanced filtering and search capabilities
- **📊 Data-Driven Insights**: Analytics dashboard for administrators to track library usage
- **🌙 Modern UX**: Beautiful, intuitive interface with dark mode support

---

## ✨ Key Features

### 👨‍🎓 For Students
- **Book Management**
  - Search and browse the library catalog with filters
  - View detailed book information including availability status
  - Borrow and reserve books digitally
  - Track borrowed books and due dates
  - Receive reminders for upcoming returns

- **Study Room Booking**
  - Browse available study rooms
  - Book rooms for individual or group study sessions
  - View and manage room reservations
  - Get notifications for booking confirmations

- **Digital Communication**
  - Real-time chat with library staff
  - Receive important library notifications
  - Stay updated with news and events

- **Account Management**
  - View borrowing history
  - Check outstanding fines
  - Update profile information
  - QR code for quick identification

### 👨‍💼 For Library Staff
- **Book Management**
  - Add, edit, and remove books from the catalog
  - Scan QR codes for quick book checkout/return
  - Track borrowed items and manage loans
  - Search and filter catalog efficiently

- **Fine Management**
  - View all outstanding fines
  - Record fine payments
  - Track fine history by student
  - Generate fine reports

- **Room Management**
  - Monitor room bookings
  - Approve or cancel reservations
  - Manage room availability

- **User Support**
  - Respond to student queries via chat
  - View user information
  - Send notifications to users

- **Content Management**
  - Post library news and announcements
  - Update event information

### 🔑 For Administrators
- **Complete System Control**
  - Manage all books, rooms, and users
  - Add and configure library staff accounts
  - Bulk import/export data

- **Analytics Dashboard**
  - Track book borrowing trends
  - Monitor room booking statistics
  - View user engagement metrics
  - Generate usage reports with charts

- **User Management**
  - Add, edit, and remove users
  - Manage user roles (student/staff)
  - View user activity logs

- **System Configuration**
  - Configure library policies
  - Set borrowing limits and rules
  - Manage notification templates

---

## 🛠️ Technology Stack

### Frontend
- **Flutter 3.7+** - Cross-platform mobile framework
- **Dart** - Programming language
- **Provider** - State management
- **Go Router** - Navigation and routing

### Backend & Services
- **Firebase Authentication** - Secure user authentication
- **Cloud Firestore** - Real-time NoSQL database
- **Firebase Storage** - Cloud storage for images and documents
- **Firebase Cloud Messaging** - Push notifications (ready to integrate)

### Key Packages
- `fl_chart` - Beautiful charts for analytics
- `mobile_scanner` - QR code scanning functionality
- `cached_network_image` - Optimized image loading
- `qr_flutter` - QR code generation
- `image_picker` - Upload profile pictures and book covers
- `intl` - Internationalization and date formatting

---


## 🚀 Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:
- **Flutter SDK** (3.7 or higher) - [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Dart SDK** (comes with Flutter)
- **Android Studio** or **VS Code** with Flutter extensions
- **Git**
- **Firebase CLI** (for Firebase configuration)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/LibriUni-Mobile-Application--College.git
   cd LibriUni-Mobile-Application--College/s1
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com)
   - Add Android and/or iOS apps to your Firebase project
   - Download `google-services.json` (Android) and place it in `android/app/`
   - Download `GoogleService-Info.plist` (iOS) and place it in `ios/Runner/`
   - Enable Firebase Authentication (Email/Password)
   - Create a Cloud Firestore database
   - Set up Firebase Storage
   - Configure Firebase security rules (see `firebase.json`)

4. **Update Firebase Configuration**
   ```bash
   # Run Flutter Firebase configuration
   flutterfire configure
   ```

5. **Seed Sample Data (Optional)**
   
   To populate your database with sample data for testing:
   - Open `lib/main.dart`
   - Set `seedData = true` in the main function
   - Run the app once, then set it back to `false`

6. **Run the application**
   ```bash
   # For Android
   flutter run
   
   # For iOS (Mac only)
   flutter run -d ios
   
   # For Web
   flutter run -d chrome
   ```

---

## 📂 Project Structure

```
s1/
├── lib/
│   ├── constants/           # App-wide constants (colors, themes)
│   ├── models/              # Data models
│   │   ├── book_model.dart
│   │   ├── user_model.dart
│   │   ├── loan_model.dart
│   │   ├── fine_model.dart
│   │   ├── room_booking.dart
│   │   └── ...
│   ├── providers/           # State management (Provider pattern)
│   │   ├── auth_provider.dart
│   │   ├── book_provider.dart
│   │   ├── user_provider.dart
│   │   └── ...
│   ├── screens/             # UI screens organized by role
│   │   ├── admin/           # Administrator screens
│   │   ├── staff/           # Library staff screens
│   │   ├── student/         # Student screens
│   │   └── auth/            # Authentication screens
│   ├── services/            # Backend service layer
│   │   ├── auth_service.dart
│   │   ├── book_service.dart
│   │   ├── firestore_service.dart
│   │   └── ...
│   ├── widgets/             # Reusable UI components
│   ├── routes/              # Navigation configuration
│   │   └── app_router.dart
│   ├── utils/               # Helper functions and utilities
│   ├── firebase_options.dart
│   └── main.dart            # Application entry point
├── assets/                  # Images, fonts, and other assets
├── android/                 # Android-specific configuration
├── ios/                     # iOS-specific configuration
├── web/                     # Web-specific configuration
└── pubspec.yaml             # Project dependencies
```

---



## 🔧 Configuration

### Firebase Security Rules

Ensure your Firestore security rules are properly configured:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User documents
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId || 
                     get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Books collection
    match /books/{bookId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                     get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'staff'];
    }
    
    // Add more rules for other collections...
  }
}
```

### Environment Variables

Create a `.env` file in the root directory (if needed for additional configurations):

```env
APP_NAME=LibriUni
API_URL=your_api_url_here
```

---

## 🧪 Testing

Run the test suite:

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run integration tests
flutter test integration_test
```

---

## 📦 Building for Production

### Android APK
```bash
flutter build apk --release
```

### Android App Bundle (for Play Store)
```bash
flutter build appbundle --release
```

### iOS (Mac only)
```bash
flutter build ios --release
```

---

## 🤝 Contributing

We welcome contributions to LibriUni! Here's how you can help:

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/AmazingFeature`)
3. **Commit your changes** (`git commit -m 'Add some AmazingFeature'`)
4. **Push to the branch** (`git push origin feature/AmazingFeature`)
5. **Open a Pull Request**

Please ensure your code follows the project's coding standards and includes appropriate tests.

---

## 📝 Roadmap

### Upcoming Features
- [ ] AI-powered book recommendations
- [ ] Integration with university ID cards (NFC)
- [ ] Multi-language support
- [ ] Offline mode for basic operations
- [ ] E-book integration
- [ ] Advanced analytics with ML insights
- [ ] Mobile app notifications (FCM integration)
- [ ] Reading challenges and gamification
- [ ] Book review and rating system
- [ ] Integration with academic calendars

---

## 🐛 Known Issues

- Dark mode theme switching may require app restart in some cases
- QR scanner may need camera permissions granted manually on some devices

For a complete list of issues, please check the [Issues](https://github.com/yourusername/LibriUni-Mobile-Application--College/issues) page.



## 👥 Authors & Contributors

- **Abdullah Bahbry** - @Abdull0h3

See also the list of [contributors](https://github.com/yourusername/LibriUni-Mobile-Application--College/contributors) who participated in this project.

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend infrastructure
- All open-source contributors whose packages made this project possible
- University libraries that inspired this project

---

## 📞 Support

For support, email your-email@example.com or create an issue in this repository.

---

## ⭐ Show your support

Give a ⭐️ if this project helped you or you find it interesting!

---

<div align="center">
  
  **Built with  using Flutter**
  
  [Report Bug](https://github.com/yourusername/LibriUni-Mobile-Application--College/issues) · 
  [Request Feature](https://github.com/yourusername/LibriUni-Mobile-Application--College/issues) · 
  [Documentation](https://github.com/yourusername/LibriUni-Mobile-Application--College/wiki)
  
</div>
