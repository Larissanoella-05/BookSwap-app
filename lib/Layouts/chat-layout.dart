import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookswap/Services/chat_providers.dart';
import 'package:bookswap/Firebase/auth_providers.dart';
import 'package:bookswap/Models/chat.dart';
import 'package:bookswap/Screens/chat_detail.dart';

/// Chat Layout - Shows chat conversations
class ChatLayout extends ConsumerStatefulWidget {
  const ChatLayout({super.key});

  @override
  ConsumerState<ChatLayout> createState() => _ChatLayoutState();
}

class _ChatLayoutState extends ConsumerState<ChatLayout> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getDisplayName(Chat chat, String currentUserId) {
    final otherParticipantName = chat.getOtherParticipantName(currentUserId);
    final otherParticipantEmail = chat.getOtherParticipantEmail(currentUserId);
    final otherParticipantId = chat.getOtherParticipant(currentUserId);
    
    String displayName = otherParticipantName ?? 'Unknown User';
    if (displayName == 'Unknown User' && otherParticipantEmail != null && otherParticipantEmail.isNotEmpty) {
      final emailParts = otherParticipantEmail.split('@');
      if (emailParts.isNotEmpty && emailParts[0].isNotEmpty) {
        displayName = emailParts[0];
      } else {
        displayName = otherParticipantEmail;
      }
    } else if (displayName == 'Unknown User') {
      displayName = otherParticipantEmail ?? otherParticipantId ?? 'Unknown User';
    }
    return displayName;
  }

  List<Chat> _filterChats(List<Chat> chats, String currentUserId, String query) {
    if (query.isEmpty) return chats;
    
    final lowerQuery = query.toLowerCase();
    return chats.where((chat) {
      final displayName = _getDisplayName(chat, currentUserId).toLowerCase();
      final email = chat.getOtherParticipantEmail(currentUserId)?.toLowerCase() ?? '';
      final lastMessage = chat.lastMessage?.toLowerCase() ?? '';
      
      return displayName.contains(lowerQuery) || 
             email.contains(lowerQuery) ||
             lastMessage.contains(lowerQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserStreamProvider);

    return currentUserAsync.when(
      data: (currentUser) {
        if (currentUser == null) {
          return const Center(
            child: Text('Please log in to view chats'),
          );
        }

        final userChatsAsync = ref.watch(userChatsProvider(currentUser.uid));

    return userChatsAsync.when(
      data: (chats) {
        final filteredChats = _filterChats(chats, currentUser.uid, _searchQuery);
        
        return Column(
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search chats...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey[600]),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey[400]!),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            // Chat List
            if (filteredChats.isEmpty && chats.isEmpty)
              Expanded(
                child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.message_outlined,
                  size: 80,
                  color: Color.fromARGB(255, 150, 150, 150),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No chats yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Color.fromARGB(255, 100, 100, 100),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Start a swap to begin chatting!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color.fromARGB(255, 150, 150, 150),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
                ),
              )
            else if (filteredChats.isEmpty && _searchQuery.isNotEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 60,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No chats found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try a different search term',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: filteredChats.length,
          itemBuilder: (context, index) {
                    final chat = filteredChats[index];
            return _ChatCard(chat: chat, currentUserId: currentUser.uid);
          },
                ),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text('Error: $error'),
      ),
    );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text('Error loading user: $error'),
      ),
    );
  }
}

/// Chat Card Widget
class _ChatCard extends ConsumerWidget {
  final Chat chat;
  final String currentUserId;

  const _ChatCard({
    required this.chat,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otherParticipantId = chat.getOtherParticipant(currentUserId);
    final otherParticipantName = chat.getOtherParticipantName(currentUserId);
    final otherParticipantEmail = chat.getOtherParticipantEmail(currentUserId);
    final otherParticipantPhotoURL = chat.getOtherParticipantPhotoURL(currentUserId);
    
    // Use name, then extract name from email, then email, then fallback to ID
    String displayName = otherParticipantName ?? 'Unknown User';
    if (displayName == 'Unknown User' && otherParticipantEmail != null && otherParticipantEmail.isNotEmpty) {
      // Extract name from email (part before @)
      final emailParts = otherParticipantEmail.split('@');
      if (emailParts.isNotEmpty && emailParts[0].isNotEmpty) {
        displayName = emailParts[0];
      } else {
        displayName = otherParticipantEmail;
      }
    } else if (displayName == 'Unknown User') {
      displayName = otherParticipantEmail ?? otherParticipantId ?? 'Unknown User';
    }
    
    final initial = displayName.isNotEmpty 
        ? displayName.substring(0, 1).toUpperCase() 
        : 'U';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(chat: chat),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Color.fromARGB(255, 230, 230, 230),
              width: 0.5,
            ),
          ),
      ),
        child: Row(
          children: [
            // Profile Picture
            CircleAvatar(
          radius: 28,
              backgroundColor: const Color.fromARGB(255, 250, 174, 22),
          backgroundImage: otherParticipantPhotoURL != null && otherParticipantPhotoURL.isNotEmpty
              ? NetworkImage(otherParticipantPhotoURL)
              : null,
          child: otherParticipantPhotoURL == null || otherParticipantPhotoURL.isEmpty
              ? Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                        fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
            const SizedBox(width: 16),
            // Name and Last Message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
          displayName,
          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                          overflow: TextOverflow.ellipsis,
          ),
        ),
                      if (chat.lastMessageTime != null)
                        Text(
                          _formatTime(chat.lastMessageTime!),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
          chat.lastMessage ?? 'No messages yet',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      // Today - show time in 12-hour format
      final hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}
