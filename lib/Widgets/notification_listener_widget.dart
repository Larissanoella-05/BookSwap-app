import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookswap/Services/swap_providers.dart';
import 'package:bookswap/Services/chat_providers.dart';
import 'package:bookswap/Firebase/auth_providers.dart';
import 'package:bookswap/Services/notification_service.dart';
import 'package:bookswap/Services/book_providers.dart';
import 'package:bookswap/Models/swap.dart';
import 'package:bookswap/Models/chat.dart';
import 'package:bookswap/Models/message.dart' as msg;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';


class NotificationListenerWidget extends ConsumerStatefulWidget {
  final Widget child;

  const NotificationListenerWidget({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<NotificationListenerWidget> createState() => _NotificationListenerWidgetState();
}

class _NotificationListenerWidgetState extends ConsumerState<NotificationListenerWidget> {
  final NotificationService _notificationService = NotificationService();
  Set<String> _lastSwapIds = {};
  Map<String, Set<String>> _lastMessageIds = {};
  Set<String> _listeningChatIds = {};
  final Map<String, ProviderSubscription> _messageListeners = {};

  @override
  void dispose() {
    // Save last active time before disposing
    _saveLastActiveTime();
    // Clean up all manual listeners
    for (final subscription in _messageListeners.values) {
      subscription.close();
    }
    _messageListeners.clear();
    super.dispose();
  }

  /// Save the current time as last active time
  Future<void> _saveLastActiveTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_active_timestamp', DateTime.now().millisecondsSinceEpoch);
      debugPrint('NotificationListener: Saved last active time');
    } catch (e) {
      debugPrint('Error saving last active time: $e');
    }
  }

  /// Get the last active timestamp
  Future<DateTime?> _getLastActiveTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt('last_active_timestamp');
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    } catch (e) {
      debugPrint('Error getting last active time: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser != null) {
      // Listen for new swap offers
      ref.listen<AsyncValue<List<Swap>>>(
        receivedOffersProvider(currentUser.uid),
        (previous, next) {
          next.when(
            data: (swaps) async {
              debugPrint('NotificationListener: Received ${swaps.length} swap(s)');
              if (_lastSwapIds.isEmpty) {
                // First load - check for swaps created while user was offline
                final lastActiveTime = await _getLastActiveTime();
                debugPrint('NotificationListener: First load - lastActiveTime: $lastActiveTime');
                _lastSwapIds = swaps.map((s) => s.id).toSet();
                
                if (lastActiveTime != null) {
                  // Show notifications for swaps created after last active time
                  debugPrint('NotificationListener: Checking ${swaps.length} swaps against lastActiveTime: $lastActiveTime');
                  for (final swap in swaps) {
                    debugPrint('NotificationListener: Swap ${swap.id} - createdAt: ${swap.createdAt}, status: ${swap.status}, isAfter: ${swap.createdAt.isAfter(lastActiveTime)}');
                  }
                  final offlineSwaps = swaps.where((swap) => 
                    swap.createdAt.isAfter(lastActiveTime) && 
                    swap.status == SwapStatus.pending
                  ).toList();
                  
                  debugPrint('NotificationListener: Found ${offlineSwaps.length} offline swap(s)');
                  
                  if (offlineSwaps.isNotEmpty) {
                    debugPrint('NotificationListener: Found ${offlineSwaps.length} swap(s) that arrived while offline');
                    // Show notifications with a small delay between them
                    for (var i = 0; i < offlineSwaps.length; i++) {
                      await Future.delayed(Duration(milliseconds: i * 500));
                      _showSwapNotification(offlineSwaps[i]);
                    }
                  } else {
                    debugPrint('NotificationListener: No offline swaps found (all swaps are older than lastActiveTime or not pending)');
                  }
                } else {
                  debugPrint('NotificationListener: No lastActiveTime found (first time user or data cleared)');
                }
                // Update last active time after processing offline items
                _saveLastActiveTime();
                return;
              }

              final nextIds = swaps.map((s) => s.id).toSet();
              final newSwapIds = nextIds.difference(_lastSwapIds);

              // Show notification for each new swap
              if (newSwapIds.isNotEmpty) {
                debugPrint('NotificationListener: Found ${newSwapIds.length} new swap(s)');
                for (final swapId in newSwapIds) {
                  final newSwap = swaps.firstWhere((s) => s.id == swapId);
                  _showSwapNotification(newSwap);
                }
              }

              _lastSwapIds = nextIds;
            },
            loading: () {
              debugPrint('NotificationListener: Swaps are loading...');
            },
            error: (error, stackTrace) {
              debugPrint('NotificationListener: Error loading swaps: $error');
              debugPrint('NotificationListener: Stack trace: $stackTrace');
            },
          );
        },
      );

      // Listen for chats and set up message listeners for each chat
      ref.listen<AsyncValue<List<Chat>>>(
        userChatsProvider(currentUser.uid),
        (previous, next) {
          next.when(
            data: (chats) {
              debugPrint('NotificationListener: Received ${chats.length} chat(s)');
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final currentChatIds = chats.map((c) => c.id).toSet();
                final newChatIds = currentChatIds.difference(_listeningChatIds);
                final removedChatIds = _listeningChatIds.difference(currentChatIds);

                debugPrint('NotificationListener: Setting up listeners for ${newChatIds.length} new chat(s)');
                // Set up listeners for new chats
                for (final chatId in newChatIds) {
                  _listeningChatIds.add(chatId);
                  _setupMessageListener(chatId, currentUser.uid);
                }

                // Clean up listeners for removed chats
                for (final chatId in removedChatIds) {
                  _listeningChatIds.remove(chatId);
                  _lastMessageIds.remove(chatId);
                  _messageListeners[chatId]?.close();
                  _messageListeners.remove(chatId);
                }
              });
            },
            loading: () {
              debugPrint('NotificationListener: Chats are loading...');
            },
            error: (error, stackTrace) {
              debugPrint('NotificationListener: Error loading chats: $error');
              debugPrint('NotificationListener: Stack trace: $stackTrace');
            },
          );
        },
      );
    } else {
      // User logged out, save last active time and clean up everything
      _saveLastActiveTime();
      _lastSwapIds.clear();
      _lastMessageIds.clear();
      for (final subscription in _messageListeners.values) {
        subscription.close();
      }
      _messageListeners.clear();
      _listeningChatIds.clear();
    }

    return widget.child;
  }

  /// Set up a listener for messages in a specific chat using listenManual
  void _setupMessageListener(String chatId, String currentUserId) {
    debugPrint('NotificationListener: Setting up message listener for chat $chatId');
    // Use ref.listenManual to set up listeners dynamically
    final subscription = ref.listenManual<AsyncValue<List<msg.Message>>>(
      chatMessagesProvider(chatId),
      (previous, next) {
        next.when(
          data: (messages) async {
            debugPrint('NotificationListener: Received ${messages.length} message(s) in chat $chatId');
            if (!_lastMessageIds.containsKey(chatId)) {
              // First load - check for messages created while user was offline
              final lastActiveTime = await _getLastActiveTime();
              debugPrint('NotificationListener: First load for chat $chatId - lastActiveTime: $lastActiveTime');
              _lastMessageIds[chatId] = messages.map((m) => m.id).toSet();
              
              if (lastActiveTime != null) {
                // Show notifications for messages created after last active time
                debugPrint('NotificationListener: Checking ${messages.length} messages in chat $chatId against lastActiveTime: $lastActiveTime');
                for (final message in messages.take(5)) { // Log first 5 messages
                  debugPrint('NotificationListener: Message ${message.id} - timestamp: ${message.timestamp}, senderId: ${message.senderId}, isAfter: ${message.timestamp.isAfter(lastActiveTime)}, isNotMine: ${message.senderId != currentUserId}');
                }
                final offlineMessages = messages.where((m) => 
                  m.timestamp.isAfter(lastActiveTime) && 
                  m.senderId != currentUserId
                ).toList();
                
                debugPrint('NotificationListener: Found ${offlineMessages.length} offline message(s)');
                
                if (offlineMessages.isNotEmpty) {
                  debugPrint('NotificationListener: Found ${offlineMessages.length} message(s) in chat $chatId that arrived while offline');
                  // Show notification for the most recent offline message
                  final mostRecentMessage = offlineMessages.reduce((a, b) => 
                    a.timestamp.isAfter(b.timestamp) ? a : b
                  );
                  _showMessageNotification(mostRecentMessage, chatId);
                } else {
                  debugPrint('NotificationListener: No offline messages found in chat $chatId');
                }
              } else {
                debugPrint('NotificationListener: No lastActiveTime found for chat $chatId');
              }
              // Update last active time after processing offline messages for this chat
              // (only update once, but it's safe to call multiple times)
              _saveLastActiveTime();
              return;
            }

            final previousIds = _lastMessageIds[chatId]!;
            final nextIds = messages.map((m) => m.id).toSet();

            debugPrint('NotificationListener: Comparing messages in chat $chatId - previous: ${previousIds.length}, next: ${nextIds.length}');
            
            // Find new messages that weren't sent by current user
            final newMessageIds = nextIds.difference(previousIds);
            debugPrint('NotificationListener: Found ${newMessageIds.length} new message ID(s) in chat $chatId');
            
            if (newMessageIds.isNotEmpty) {
              debugPrint('NotificationListener: New message IDs: ${newMessageIds.take(3).join(", ")}');
              final newMessages = messages.where((m) => 
                newMessageIds.contains(m.id) && m.senderId != currentUserId
              ).toList();
              
              debugPrint('NotificationListener: Filtered to ${newMessages.length} new message(s) not sent by current user');
              
              if (newMessages.isNotEmpty) {
                debugPrint('NotificationListener: Found ${newMessages.length} new message(s) in chat $chatId');
                final newMessage = newMessages.first;
                _showMessageNotification(newMessage, chatId);
              } else {
                debugPrint('NotificationListener: All new messages were sent by current user, skipping notification');
              }
            } else {
              debugPrint('NotificationListener: No new message IDs found (messages might have been removed or reordered)');
            }

            // Update last seen message IDs
            _lastMessageIds[chatId] = nextIds;
          },
          loading: () {
            debugPrint('NotificationListener: Messages for chat $chatId are loading...');
          },
          error: (error, stackTrace) {
            debugPrint('NotificationListener: Error loading messages for chat $chatId: $error');
            debugPrint('NotificationListener: Stack trace: $stackTrace');
          },
        );
      },
    );
    
    // Store the subscription so we can clean it up later
    _messageListeners[chatId] = subscription;
  }

  /// Show notification for a new swap
  Future<void> _showSwapNotification(Swap swap) async {
    try {
      debugPrint('NotificationListener: Attempting to show swap notification for swap ${swap.id}');
      // Get book title
      final bookAsync = ref.read(bookByIdProvider(swap.bookId));
      await bookAsync.when(
        data: (book) async {
          final requesterName = swap.requesterEmail.split('@')[0];
          
          debugPrint('NotificationListener: Showing swap notification - $requesterName wants "${book.title}"');
          await _notificationService.showSwapRequestNotification(
            requesterName: requesterName,
            bookTitle: book.title,
          );
        },
        loading: () async {
          debugPrint('NotificationListener: Book data is loading, waiting...');
          await Future.delayed(Duration(milliseconds: 500));
          final bookAsyncRetry = ref.read(bookByIdProvider(swap.bookId));
          await bookAsyncRetry.when(
            data: (book) async {
              final requesterName = swap.requesterEmail.split('@')[0];
              debugPrint('NotificationListener: Showing swap notification (retry) - $requesterName wants "${book.title}"');
              await _notificationService.showSwapRequestNotification(
                requesterName: requesterName,
                bookTitle: book.title,
              );
            },
            loading: () {
              debugPrint('NotificationListener: Book still loading, using fallback');
              _showSwapNotificationFallback(swap);
            },
            error: (error, stack) {
              debugPrint('NotificationListener: Error loading book: $error');
              _showSwapNotificationFallback(swap);
            },
          );
        },
        error: (error, stack) async {
          debugPrint('NotificationListener: Error loading book for notification: $error');
          _showSwapNotificationFallback(swap);
        },
      );
    } catch (e) {
      debugPrint('Error showing swap notification: $e');
      _showSwapNotificationFallback(swap);
    }
  }

  /// Fallback method to show notification without book data
  Future<void> _showSwapNotificationFallback(Swap swap) async {
    try {
      final requesterName = swap.requesterEmail.split('@')[0];
      debugPrint('NotificationListener: Showing swap notification (fallback) - $requesterName wants a book');
      await _notificationService.showSwapRequestNotification(
        requesterName: requesterName,
        bookTitle: 'a book',
      );
    } catch (e) {
      debugPrint('Error showing fallback swap notification: $e');
    }
  }

  /// Show notification for a new message
  Future<void> _showMessageNotification(msg.Message message, String chatId) async {
    try {
      debugPrint('NotificationListener: Attempting to show message notification for chat $chatId');
      // Get chat to find sender name
      final chatAsync = ref.read(chatByIdProvider(chatId));
      await chatAsync.when(
        data: (chat) async {
          final senderId = message.senderId;
          // Try to get name from multiple sources
          String senderName = 'Someone';
          if (chat.participantNames.containsKey(senderId) && 
              chat.participantNames[senderId] != null && 
              chat.participantNames[senderId]!.isNotEmpty) {
            senderName = chat.participantNames[senderId]!;
          } else if (chat.participantEmails.containsKey(senderId) && 
                     chat.participantEmails[senderId] != null) {
            final email = chat.participantEmails[senderId]!;
            senderName = email.split('@')[0];
          }
          
          // Get sender photo URL
          final senderPhotoURL = chat.participantPhotoURLs[senderId];
          
          final messagePreview = message.text.length > 50 
              ? '${message.text.substring(0, 50)}...' 
              : message.text;
          
          debugPrint('NotificationListener: Showing message notification - $senderName: $messagePreview (photo: ${senderPhotoURL != null ? "yes" : "no"})');
          await _notificationService.showMessageNotification(
            senderName: senderName,
            messageText: messagePreview,
            chatId: chatId,
            senderPhotoURL: senderPhotoURL,
          );
        },
        loading: () async {
          debugPrint('NotificationListener: Chat data is loading, waiting...');
          // Wait a bit and try again
          await Future.delayed(Duration(milliseconds: 500));
          final chatAsyncRetry = ref.read(chatByIdProvider(chatId));
          await chatAsyncRetry.when(
            data: (chat) async {
              final senderId = message.senderId;
              // Try to get name from multiple sources
              String senderName = 'Someone';
              if (chat.participantNames.containsKey(senderId) && 
                  chat.participantNames[senderId] != null && 
                  chat.participantNames[senderId]!.isNotEmpty) {
                senderName = chat.participantNames[senderId]!;
              } else if (chat.participantEmails.containsKey(senderId) && 
                         chat.participantEmails[senderId] != null) {
                final email = chat.participantEmails[senderId]!;
                senderName = email.split('@')[0];
              }
              
              // Get sender photo URL
              final senderPhotoURL = chat.participantPhotoURLs[senderId];
              
              final messagePreview = message.text.length > 50 
                  ? '${message.text.substring(0, 50)}...' 
                  : message.text;
              
              debugPrint('NotificationListener: Showing message notification (retry) - $senderName: $messagePreview (photo: ${senderPhotoURL != null ? "yes" : "no"})');
              await _notificationService.showMessageNotification(
                senderName: senderName,
                messageText: messagePreview,
                chatId: chatId,
                senderPhotoURL: senderPhotoURL,
              );
            },
            loading: () {
              debugPrint('NotificationListener: Chat still loading, using fallback');
              _showMessageNotificationFallback(message, chatId);
            },
            error: (error, stack) {
              debugPrint('NotificationListener: Error loading chat: $error');
              _showMessageNotificationFallback(message, chatId);
            },
          );
        },
        error: (error, stack) async {
          debugPrint('NotificationListener: Error loading chat for notification: $error');
          _showMessageNotificationFallback(message, chatId);
        },
      );
    } catch (e) {
      debugPrint('Error showing message notification: $e');
      _showMessageNotificationFallback(message, chatId);
    }
  }

  /// Fallback method to show notification without chat data
  Future<void> _showMessageNotificationFallback(msg.Message message, String chatId) async {
    try {
      final senderName = 'Someone';
      final messagePreview = message.text.length > 50 
          ? '${message.text.substring(0, 50)}...' 
          : message.text;
      
      debugPrint('NotificationListener: Showing message notification (fallback) - $senderName: $messagePreview');
      await _notificationService.showMessageNotification(
        senderName: senderName,
        messageText: messagePreview,
        chatId: chatId,
        senderPhotoURL: null,
      );
    } catch (e) {
      debugPrint('Error showing fallback message notification: $e');
    }
  }
}

