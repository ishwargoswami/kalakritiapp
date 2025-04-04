import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kalakritiapp/providers/auth_provider.dart';
import 'package:kalakritiapp/providers/chat_provider.dart';
import 'package:kalakritiapp/screens/chat_screen.dart';
import 'package:kalakritiapp/widgets/loading_overlay.dart';

class ChatInfo {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final String? otherUserPhotoURL;
  final String? otherUserBusiness;
  final bool isSeller;

  ChatInfo({
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    this.otherUserPhotoURL,
    this.otherUserBusiness,
    this.isSeller = false,
  });

  factory ChatInfo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatInfo(
      chatId: data['chatId'] ?? '',
      otherUserId: data['otherUserId'] ?? '',
      otherUserName: data['otherUserName'] ?? 'Unknown User',
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: data['lastMessageTimestamp'] != null
          ? (data['lastMessageTimestamp'] as Timestamp).toDate()
          : DateTime.now(),
      unreadCount: data['unreadCount'] ?? 0,
      otherUserPhotoURL: data['otherUserPhotoURL'],
      otherUserBusiness: data['otherUserBusiness'],
      isSeller: data['isSeller'] ?? false,
    );
  }
}

class ChatsListScreen extends ConsumerStatefulWidget {
  const ChatsListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends ConsumerState<ChatsListScreen> {
  bool _isLoading = true;
  List<ChatInfo> _chats = [];
  Stream<QuerySnapshot>? _chatsStream;

  @override
  void initState() {
    super.initState();
    _setupChatsStream();
  }

  void _setupChatsStream() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() {
        _chats = [];
        _isLoading = false;
      });
      return;
    }

    try {
      // Stream from user's chat metadata collection - this works for both sellers and buyers
      _chatsStream = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('chats')
          .orderBy('lastMessageTimestamp', descending: true)
          .snapshots();
      
      _chatsStream!.listen(
        (snapshot) {
          setState(() {
            _chats = snapshot.docs.map((doc) => ChatInfo.fromFirestore(doc)).toList();
            _isLoading = false;
          });
        },
        onError: (error) {
          print('Error fetching chats: $error');
          setState(() {
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      print('Error setting up chat stream: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshChats() async {
    setState(() => _isLoading = true);
    _setupChatsStream();
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Messages'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        body: FirebaseAuth.instance.currentUser == null
            ? _buildSignInPrompt()
            : _chats.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _refreshChats,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(8),
                      itemCount: _chats.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final chat = _chats[index];
                        return _buildChatTile(chat, ref);
                      },
                    ),
                  ),
      ),
    );
  }

  Widget _buildSignInPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.account_circle,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Please sign in to view your messages',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Navigate to login screen
              // This should be replaced with actual navigation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navigate to login screen')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect with artisans to start a conversation',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChatTile(ChatInfo chat, WidgetRef ref) {
    final photoUrlAsync = ref.watch(otherUserPhotoProvider(chat.otherUserId));
    final photoUrl = photoUrlAsync.when(
      data: (url) => url,
      loading: () => null,
      error: (_, __) => null,
    );
    
    return ListTile(
      onTap: () async {
        await markChatAsRead(chat.chatId);
        
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              otherUserId: chat.otherUserId,
              otherUserName: chat.otherUserName,
            ),
          ),
        );
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey[200],
        backgroundImage: photoUrl != null
            ? CachedNetworkImageProvider(photoUrl)
            : null,
        child: photoUrl == null
            ? const Icon(Icons.person, color: Colors.grey)
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chat.otherUserName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (chat.otherUserBusiness != null && chat.otherUserBusiness!.isNotEmpty)
                  Text(
                    chat.otherUserBusiness!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Text(
            _formatChatTime(chat.lastMessageTime),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                chat.lastMessage,
                style: TextStyle(
                  color: chat.unreadCount > 0
                      ? Colors.black87
                      : Colors.grey[600],
                  fontWeight: chat.unreadCount > 0
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (chat.unreadCount > 0)
              Container(
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  chat.unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatChatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return DateFormat('h:mm a').format(time);
    } else if (difference.inDays < 7) {
      return DateFormat('E').format(time); // Weekday
    } else {
      return DateFormat('M/d/yy').format(time);
    }
  }
} 