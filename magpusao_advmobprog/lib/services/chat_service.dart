import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/message.dart';

class ChatService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _firebaseAuth => FirebaseAuth.instance;

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        // Profiles are stored at users/{Firebase Auth UID}.
        return <String, dynamic>{...doc.data(), 'uid': doc.id};
      }).toList();
    });
  }

  Future<void> sendMessage(String receiverId, String message) async {
    final currentUser = _firebaseAuth.currentUser;
    final trimmedMessage = message.trim();
    if (currentUser == null) {
      throw StateError('You must be signed in to send a message.');
    }
    if (receiverId.isEmpty || receiverId == currentUser.uid) {
      throw StateError('Select another registered user to send a message.');
    }
    if (trimmedMessage.isEmpty) return;

    final timestamp = Timestamp.now();
    final newMessage = MessageModel(
      senderId: currentUser.uid,
      senderEmail: currentUser.email ?? '',
      receiverId: receiverId,
      message: trimmedMessage,
      timestamp: timestamp,
    );

    final ids = [currentUser.uid, receiverId]..sort();
    final chatRoomId = ids.join('_');
    final room = _firestore.collection('chat_rooms').doc(chatRoomId);
    final messageDocument = room.collection('messages').doc();
    final batch = _firestore.batch();
    batch.set(room, {
      'participants': ids,
      'lastMessage': trimmedMessage,
      'updatedAt': timestamp,
    }, SetOptions(merge: true));
    batch.set(messageDocument, newMessage.toMap());
    await batch.commit();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getMessages(
    String userId,
    String otherUserId,
  ) {
    final ids = [userId, otherUserId]..sort();
    final chatRoomId = ids.join('_');
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> markMessagesAsSeen(String otherUserId) async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) return;

    final ids = [currentUser.uid, otherUserId]..sort();
    final chatRoomId = ids.join('_');
    final snapshot = await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUser.uid)
        .get();

    final unread = snapshot.docs.where((doc) {
      final data = doc.data();
      return data['senderId'] == otherUserId && data['status'] != 'seen';
    }).toList();
    if (unread.isEmpty) return;

    final batch = _firestore.batch();
    for (final message in unread) {
      batch.update(message.reference, {'status': 'seen'});
    }
    await batch.commit();
  }

  Future<String?> getUserByEmail(String email) async {
    final query = await _firestore
        .collection('users')
        .where('email', isEqualTo: email.trim())
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return query.docs.first.id;
  }
}
