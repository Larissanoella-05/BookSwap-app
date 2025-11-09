import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';

/// Service for handling local notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final initialized = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (initialized == false) {
        debugPrint('Notification service: Platform initialization returned false');
        return;
      }

      // Request permissions for Android 13+
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _notifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      }

      _initialized = true;
      debugPrint(' Notification service initialized successfully');
    } catch (e) {
      debugPrint(' Notification service initialization error: $e');
      debugPrint('Note: This may require a full app rebuild (not just hot reload)');
      debugPrint('Try: Stop the app, run "flutter clean", then rebuild');
      // Don't set _initialized to true if initialization failed
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap if needed
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }

  /// Show a notification for a new swap request
  Future<void> showSwapRequestNotification({
    required String requesterName,
    required String bookTitle,
  }) async {
    if (!_initialized) {
      debugPrint('Notification service not initialized, skipping notification');
      return;
    }

    final enabled = await areNotificationsEnabled();
    if (!enabled) return;

    const androidDetails = AndroidNotificationDetails(
      'swap_requests',
      'Swap Requests',
      channelDescription: 'Notifications for book swap requests',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final notificationId = DateTime.now().millisecondsSinceEpoch % 100000;
    debugPrint('NotificationService: Showing swap notification (ID: $notificationId)');
    await _notifications.show(
      notificationId,
      'New Swap Request',
      '$requesterName wants to swap for "$bookTitle"',
      details,
    );
    debugPrint('NotificationService: Swap notification shown successfully');
  }

  /// Show a notification for a new message
  Future<void> showMessageNotification({
    required String senderName,
    required String messageText,
    required String chatId,
    String? senderPhotoURL,
  }) async {
    if (!_initialized) {
      debugPrint('Notification service not initialized, skipping notification');
      return;
    }

    final enabled = await areNotificationsEnabled();
    if (!enabled) return;

    // Download image for avatar if provided
    String? largeIconPath;
    ByteArrayAndroidBitmap? largeIconBitmap;
    if (senderPhotoURL != null && senderPhotoURL.isNotEmpty) {
      try {
        // Download image for both Android (as bitmap) and iOS (as file path)
        final imageBytes = await _downloadImageBytes(senderPhotoURL);
        if (imageBytes != null) {
          largeIconBitmap = ByteArrayAndroidBitmap(imageBytes);
          debugPrint('NotificationService: Downloaded avatar image bytes (${imageBytes.length} bytes)');
        }
        
        // Also download to file for iOS attachments
        largeIconPath = await _downloadImageForNotification(senderPhotoURL);
        if (largeIconPath != null) {
          debugPrint('NotificationService: Downloaded avatar image to file: $largeIconPath');
        }
      } catch (e) {
        debugPrint('NotificationService: Failed to download avatar image: $e');
      }
    }

    final androidDetails = AndroidNotificationDetails(
      'messages',
      'Messages',
      channelDescription: 'Notifications for new chat messages',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      largeIcon: largeIconBitmap,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      attachments: largeIconPath != null 
          ? [
              DarwinNotificationAttachment(
                largeIconPath,
                identifier: 'avatar',
              ),
            ]
          : null,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final notificationId = DateTime.now().millisecondsSinceEpoch % 100000;
    debugPrint('NotificationService: Showing message notification (ID: $notificationId) - $senderName');
    await _notifications.show(
      notificationId,
      senderName,
      messageText,
      details,
      payload: chatId,
    );
    debugPrint('NotificationService: Message notification shown successfully');
  }

  /// Download image bytes from URL
  Future<Uint8List?> _downloadImageBytes(String imageUrl) async {
    try {
      debugPrint('NotificationService: Downloading avatar bytes from $imageUrl');
      final response = await http.get(Uri.parse(imageUrl));
      
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        debugPrint('NotificationService: Failed to download avatar - status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('NotificationService: Error downloading image bytes: $e');
    }
    return null;
  }

  /// Download image from URL and save it locally for notification (for iOS)
  Future<String?> _downloadImageForNotification(String imageUrl) async {
    try {
      final imageBytes = await _downloadImageBytes(imageUrl);
      if (imageBytes != null) {
        // Get temporary directory
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/notification_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final file = File(filePath);
        await file.writeAsBytes(imageBytes);
        debugPrint('NotificationService: Avatar saved to $filePath');
        return filePath;
      }
    } catch (e) {
      debugPrint('NotificationService: Error saving image to file: $e');
    }
    return null;
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}

