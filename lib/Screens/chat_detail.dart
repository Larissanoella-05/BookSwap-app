import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookswap/Services/chat_providers.dart';
import 'package:bookswap/Firebase/auth_providers.dart';
import 'package:bookswap/Models/chat.dart';

/// Chat Detail Screen - Shows individual chat conversation
class ChatDetailScreen extends ConsumerStatefulWidget {
  final Chat chat;

  const ChatDetailScreen({
    super.key,
    required this.chat,
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Listen to messages and scroll when new ones arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final chatService = ref.read(chatServiceProvider);
    final text = _messageController.text.trim();
    _messageController.clear();

    try {
      await chatService.sendMessage(
        chatId: widget.chat.id,
        text: text,
      );
      // Scroll to bottom after sending
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chat.id));
    final otherParticipantId = widget.chat.getOtherParticipant(currentUser?.uid ?? '');
    final otherParticipantName = widget.chat.getOtherParticipantName(currentUser?.uid ?? '');
    final otherParticipantEmail = widget.chat.getOtherParticipantEmail(currentUser?.uid ?? '');
    final otherParticipantPhotoURL = widget.chat.getOtherParticipantPhotoURL(currentUser?.uid ?? '');
    
    // Use name, then extract name from email, then email, then fallback to ID
    String displayName = otherParticipantName ?? 'Chat';
    if (displayName == 'Chat' && otherParticipantEmail != null && otherParticipantEmail.isNotEmpty) {
      // Extract name from email (part before @)
      final emailParts = otherParticipantEmail.split('@');
      if (emailParts.isNotEmpty && emailParts[0].isNotEmpty) {
        displayName = emailParts[0];
      } else {
        displayName = otherParticipantEmail;
      }
    } else if (displayName == 'Chat') {
      displayName = otherParticipantEmail ?? otherParticipantId ?? 'Chat';
    }
    
    final initial = displayName.isNotEmpty 
        ? displayName.substring(0, 1).toUpperCase() 
        : 'C';

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 239, 239, 239),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color.fromARGB(255, 250, 174, 22)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
                displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
            fontWeight: FontWeight.bold,
            ),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 5, 22, 46),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              // TODO: Show menu options
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                // Scroll to bottom when messages load or update
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet. Start the conversation!',
                      style: TextStyle(
                        color: Color.fromARGB(255, 100, 100, 100),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUser?.uid;
                    
                    // Check if we need to show a date separator
                    final showDateSeparator = index == 0 || 
                        _shouldShowDateSeparator(messages[index - 1].timestamp, message.timestamp);
                    
                    return Column(
                      children: [
                        if (showDateSeparator)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              _formatDate(message.timestamp),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                          children: [
                            if (!isMe) ...[
                              // Profile picture for received messages
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: const Color.fromARGB(255, 250, 174, 22),
                                backgroundImage: otherParticipantPhotoURL != null && otherParticipantPhotoURL.isNotEmpty
                                    ? NetworkImage(otherParticipantPhotoURL)
                                    : null,
                                child: otherParticipantPhotoURL == null || otherParticipantPhotoURL.isEmpty
                                    ? Text(
                                        initial,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Column(
                                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? const Color.fromARGB(255, 250, 174, 22)
                              : const Color.fromARGB(255, 5, 22, 46),
                                      borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                                    child: Text(
                              message.text,
                                      style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Text(
                              _formatTime(message.timestamp),
                              style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 11,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                            if (isMe) const SizedBox(width: 8),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Text('Error: $error'),
              ),
            ),
          ),
          // Message Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Message',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[400]!),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: _sendMessage,
                  child: const Text(
                    'Send',
                    style: TextStyle(
                      color: Color.fromARGB(255, 100, 100, 100),
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  bool _shouldShowDateSeparator(DateTime previousDate, DateTime currentDate) {
    return previousDate.year != currentDate.year ||
        previousDate.month != currentDate.month ||
        previousDate.day != currentDate.day;
  }
}

