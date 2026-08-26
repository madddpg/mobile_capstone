import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Builder ↔ shop thread that unlocks after a quotation is accepted.
///
/// Same Firebase project as the web shop dashboard. Conversation docs and
/// Cloud Functions are owned by the web repo — this client only reads/writes
/// messages and may create a thread if the function is slow.
class ChatService {
  ChatService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  static String conversationId(String projectId, String shopId) =>
      '${projectId}_$shopId';

  /// List my chats (builder side).
  Stream<QuerySnapshot<Map<String, dynamic>>> watchMyConversations() {
    final uid = _auth.currentUser!.uid;
    return _db
        .collection('conversations')
        .where('builderId', isEqualTo: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots();
  }

  /// Live messages in one thread.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchMessages(
    String conversationId,
  ) {
    return _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt')
        .limit(200)
        .snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchConversation(
    String conversationId,
  ) {
    return _db.collection('conversations').doc(conversationId).snapshots();
  }

  /// Send as builder.
  Future<void> sendMessage({
    required String conversationId,
    required String text,
  }) async {
    final uid = _auth.currentUser!.uid;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final convRef = _db.collection('conversations').doc(conversationId);

    await convRef.collection('messages').add({
      'senderId': uid,
      'senderRole': 'builder',
      'text': trimmed.length > 4000 ? trimmed.substring(0, 4000) : trimmed,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await convRef.update({
      'lastMessage':
          trimmed.length > 200 ? trimmed.substring(0, 200) : trimmed,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastSenderId': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Fallback if Cloud Function has not created the thread yet.
  Future<String> ensureConversationAfterAccept({
    required String projectId,
    required String shopId,
    required String quotationId,
    required String projectTitle,
    String shopName = '',
    String builderName = 'Builder',
  }) async {
    final uid = _auth.currentUser!.uid;
    final id = conversationId(projectId, shopId);
    final ref = _db.collection('conversations').doc(id);
    if (await _conversationExists(ref) == true) return id;

    await ref.set({
      'projectId': projectId,
      'quotationId': quotationId,
      'shopId': shopId,
      'shopName': shopName,
      'builderId': uid,
      'userId': uid,
      'builderName': builderName,
      'projectTitle': projectTitle,
      'status': 'open',
      'lastMessage': 'Quote accepted — you can now message each other.',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastSenderId': '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return id;
  }

  /// Prefer the Cloud Function thread; fall back to a client create.
  Future<String> waitOrEnsureConversation({
    required String projectId,
    required String shopId,
    required String quotationId,
    required String projectTitle,
    String shopName = '',
    String builderName = 'Builder',
    Duration timeout = const Duration(seconds: 4),
  }) async {
    final id = conversationId(projectId, shopId);
    final ref = _db.collection('conversations').doc(id);
    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      final exists = await _conversationExists(ref);
      if (exists == true) return id;
      if (exists == null) break;
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }

    return ensureConversationAfterAccept(
      projectId: projectId,
      shopId: shopId,
      quotationId: quotationId,
      projectTitle: projectTitle,
      shopName: shopName,
      builderName: builderName,
    );
  }

  /// Missing-doc reads are often denied until the thread exists.
  /// Returns null when rules hide the missing document as permission-denied.
  Future<bool?> _conversationExists(
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    try {
      return (await ref.get()).exists;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') return null;
      rethrow;
    }
  }
}
