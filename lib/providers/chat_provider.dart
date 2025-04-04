import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for the total number of unread messages
final unreadMessagesCountProvider = StreamProvider<int>((ref) {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    return Stream.value(0);
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(currentUser.uid)
      .collection('chats')
      .snapshots()
      .map((snapshot) {
        int totalUnread = 0;
        for (final doc in snapshot.docs) {
          final data = doc.data();
          if (data.containsKey('unreadCount')) {
            totalUnread += (data['unreadCount'] as int);
          }
        }
        return totalUnread;
      });
});

// Provider to fetch the other user's photo URL for a chat
final otherUserPhotoProvider = FutureProvider.family<String?, String>((ref, userId) async {
  try {
    final docSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    
    if (docSnapshot.exists) {
      final data = docSnapshot.data();
      if (data != null && data.containsKey('photoURL')) {
        return data['photoURL'] as String?;
      }
    }
    return null;
  } catch (e) {
    print('Error fetching user photo: $e');
    return null;
  }
});

// Update chat metadata when a user views a chat
Future<void> markChatAsRead(String chatId) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return;

  try {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('chats')
        .doc(chatId)
        .update({'unreadCount': 0});
  } catch (e) {
    print('Error marking chat as read: $e');
  }
} 