# BookSwap App

A Flutter marketplace app where students can list textbooks they wish to exchange and initiate swap offers with other users. Built with Firebase for authentication, data storage, and real-time updates.

## Features

### ✅ Authentication
- Sign up/Sign in with Firebase Authentication (email/password)
- Email verification system
- User profile management

### ✅ Book Listings (CRUD)
- **Create**: Post books with title, author, condition (New, Like New, Good, Used)
- **Read**: Browse all available listings in a shared feed
- **Update**: Edit your own book listings
- **Delete**: Remove your own listings

### ✅ Swap Functionality
- Initiate swap offers by tapping "Swap" button
- Real-time status updates (Available → Pending → Swapped)
- Track your offers in "My Offers" section

### ✅ State Management
- Provider pattern for reactive state management
- Real-time Firestore sync for instant updates

### ✅ Navigation
- Bottom navigation with 4 screens:
  - **Browse Listings**: View all available books
  - **My Listings**: Manage your books and offers
  - **My Offers**: Track sent and received swap offers
  - **Settings**: Profile and preferences

### ✅ Chat System (Bonus)
- Real-time messaging between users after swap acceptance
- Unread message notifications
- Message timestamps

## Setup Instructions

### Prerequisites
- Flutter SDK (3.9.0 or higher)
- Android Studio / VS Code with Flutter extensions
- Firebase project setup

### 1. Clone Repository
```bash
git clone <your-repository-url>
cd bookswap_app
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Firebase Setup
The app is already configured to connect to the Firebase project `bookswap-app-e29b4`. However, if you want to use your own Firebase project:

1. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Enable Authentication with Email/Password provider
3. Create a Firestore database
4. Run FlutterFire CLI to generate new configuration:
   ```bash
   flutter pub global activate flutterfire_cli
   flutterfire configure
   ```

### 4. Required Firestore Indexes
Create these indexes in Firebase Console → Firestore → Indexes:

**For swap_offers collection:**
- Fields: `senderId` (Ascending), `createdAt` (Descending)
- Fields: `recipientId` (Ascending), `createdAt` (Descending)
- Fields: `recipientId` (Ascending), `status` (Ascending)

**For chat_messages collection:**
- Fields: `swapOfferId` (Ascending), `timestamp` (Ascending)
- Fields: `swapOfferId` (Ascending), `senderId` (Ascending), `isRead` (Ascending)

**For books collection:**
- Fields: `ownerId` (Ascending), `createdAt` (Descending)

### 5. Run the App
```bash
flutter run
```

**Important**: Run on a mobile device or emulator, not in a web browser.

## Project Structure
```
lib/
├── main.dart                 # App entry point
├── firebase_options.dart     # Firebase configuration
├── models/                   # Data models
│   ├── book.dart
│   ├── swap_offer.dart
│   └── chat_message.dart
├── providers/                # State management
│   ├── book_provider.dart
│   ├── swap_provider.dart
│   └── chat_provider.dart
├── services/                 # Firebase services
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   ├── swap_service.dart
│   └── chat_service.dart
├── screens/                  # UI screens
│   ├── welcome_screen.dart
│   ├── login_page.dart
│   ├── sign_up_screen.dart
│   ├── homepage.dart
│   ├── post_book.dart
│   ├── book_details_screen.dart
│   ├── edit_book_screen.dart
│   ├── my_offers_screen.dart
│   ├── chat_screen.dart
│   └── email_verification_screen.dart
└── utils/                    # Utilities
    └── image_helper.dart
```

## Technologies Used
- **Frontend**: Flutter (Dart)
- **Backend**: Firebase (Authentication, Firestore, Storage)
- **State Management**: Provider
- **Real-time Updates**: Firestore listeners
- **Image Handling**: Base64 encoding
- **Local Storage**: SharedPreferences

## Key Dependencies
```yaml
dependencies:
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  cloud_firestore: ^5.4.3
  provider: ^6.1.1
  image_picker: ^1.0.4
  file_picker: ^8.1.2
  image: ^4.2.0
  timeago: ^3.6.1
  shared_preferences: ^2.2.2
```

## Testing
Run the analyzer to check for issues:
```bash
flutter analyze
```

Run tests:
```bash
flutter test
```

## Demo Features
1. **User Authentication**: Sign up, login, email verification
2. **Book Management**: Create, read, update, delete book listings
3. **Swap System**: Initiate offers, accept/reject, real-time status updates
4. **Chat System**: Message other users after swap acceptance
5. **Settings**: Toggle notifications, view profile

## Firebase Collections
- `users`: User authentication data
- `books`: Book listings with metadata
- `swap_offers`: Swap offer details and status
- `chat_messages`: Real-time chat messages

## Troubleshooting
- **Index errors**: Create required Firestore indexes as listed above
- **Package errors**: Run `flutter pub get` to install dependencies
- **Firebase connection**: Ensure `firebase_options.dart` has correct project configuration
- **Email verification**: Check spam folder or use resend feature

## License
This project is for educational purposes as part of a mobile app development course.