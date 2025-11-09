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
  - **Chats**: Basic messaging system (bonus feature)
  - **Settings**: Profile and preferences

### ✅ Settings
- Toggle notification preferences
- Profile information display
- Email verification status

## Setup Instructions

### Prerequisites
- Flutter SDK (latest stable version)
- Firebase project setup
- Android Studio / VS Code with Flutter extensions

### Firebase Setup
1. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Enable Authentication with Email/Password provider
3. Create a Firestore database
4. Update `lib/firebase_options.dart` with your Firebase configuration

### Installation
1. Clone the repository
2. Install dependencies: `flutter pub get`
3. Run the app: `flutter run`

## Technologies Used
- **Frontend**: Flutter (Dart)
- **Backend**: Firebase (Authentication, Firestore, Storage)
- **State Management**: Provider
- **Real-time Updates**: Firestore listeners
