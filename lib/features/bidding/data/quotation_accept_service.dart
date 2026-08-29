import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:iconstruct/features/chat/data/chat_service.dart';
import 'package:iconstruct/features/project_creation/data/project_lifecycle.dart';

/// Firestore field names that may hold the builder's Auth uid on a post.
///
/// Security rules treat **`userId`** as the canonical owner id. Older or
/// web-side docs may use the aliases instead.
const postedEstimateOwnerKeys = [
  'userId',
  'builderId',
  'ownerId',
  'postedBy',
];

/// First non-empty owner id on a `projectPosts` document (`userId` first).
String? postedEstimateOwnerId(Map<String, dynamic> data) {
  for (final key in postedEstimateOwnerKeys) {
    final value = data[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) return value;
  }
  return null;
}

bool isPostedEstimateOwner(Map<String, dynamic> data, String uid) {
  return postedEstimateOwnerKeys.any(
    (key) => data[key]?.toString() == uid,
  );
}

String quotationShopId(Map<String, dynamic> data, String documentId) {
  final fromField = data['shopId']?.toString().trim() ?? '';
  if (fromField.isNotEmpty) return fromField;
  return documentId.trim();
}

/// Marks a quotation accepted so the web Cloud Function can open chat.
class QuotationAcceptService {
  QuotationAcceptService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    ChatService? chat,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _chat = chat ?? ChatService();

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final ChatService _chat;

  Future<String> acceptQuotation({
    required String postId,
    required String quotationId,
    required String shopId,
    required String shopName,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not signed in');

    final projectRef = _db.collection('projectPosts').doc(postId);
    final projectDoc = await projectRef.get();
    if (!projectDoc.exists) {
      throw Exception('Posted estimate not found');
    }

    final projectData = projectDoc.data() ?? {};
    if (!isPostedEstimateOwner(projectData, user.uid)) {
      throw Exception(
        'This estimate is not linked to your account. '
        'The post must store your Auth uid in userId.',
      );
    }

    if (projectData['selectedQuotationId'] != null &&
        projectData['selectedQuotationId'].toString().isNotEmpty &&
        projectData['selectedQuotationId'].toString() != quotationId) {
      throw Exception('You already accepted an offer for this estimate.');
    }

    final quotationRef = projectRef.collection('quotations').doc(quotationId);
    final quotationDoc = await quotationRef.get();
    if (!quotationDoc.exists) {
      throw Exception('That quotation is no longer available.');
    }

    final quotationData = quotationDoc.data() ?? {};
    final resolvedShopId = quotationShopId(quotationData, shopId);
    if (resolvedShopId.isEmpty) {
      throw Exception('This quotation is missing a shop id.');
    }

    final batch = _db.batch();

    // Builder quotation updates may only touch status + acceptedAt.
    batch.update(quotationRef, {
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
    });

    final quotationsSnapshot = await projectRef.collection('quotations').get();
    for (final doc in quotationsSnapshot.docs) {
      if (doc.id == quotationId) continue;
      batch.update(doc.reference, {
        'status': 'rejected',
        'acceptedAt': FieldValue.serverTimestamp(),
      });
    }

    batch.update(projectRef, {
      'selectedQuotationId': quotationId,
      'selectedShopId': resolvedShopId,
      'selectedShopName': shopName,
      'status': 'offer_accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final savedProjectId = projectData['projectId']?.toString();
    if (savedProjectId != null && savedProjectId.isNotEmpty) {
      final savedProjectRef = _db
          .collection('users')
          .doc(user.uid)
          .collection('saved_projects')
          .doc(savedProjectId);
      batch.set(
        savedProjectRef,
        {
          'status': ProjectLifecycle.supplierSelected,
          'selectedShopName': shopName,
          'supplierSelectedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
    return resolvedShopId;
  }

  Future<String> acceptAndOpenChat({
    required String postId,
    required String quotationId,
    required String shopId,
    required String shopName,
    required String projectTitle,
    String builderName = 'Builder',
  }) async {
    final resolvedShopId = await acceptQuotation(
      postId: postId,
      quotationId: quotationId,
      shopId: shopId,
      shopName: shopName,
    );

    return _chat.waitOrEnsureConversation(
      projectId: postId,
      shopId: resolvedShopId,
      quotationId: quotationId,
      projectTitle: projectTitle,
      shopName: shopName,
      builderName: builderName,
    );
  }
}
