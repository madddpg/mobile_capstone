import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// User-facing copy for common backend failures (rules, auth, network).
///
/// [action] completes the sentence `Could not ...`, so pass a verb phrase such
/// as `'save your estimate'`.
///
/// Raw exception text is only appended in debug builds; released builds never
/// show error codes, stack text or setup instructions to a builder.
String firestoreUserMessage(Object error, {required String action}) {
  final code = error is FirebaseException ? error.code : null;

  switch (code) {
    case 'permission-denied':
      if (FirebaseAuth.instance.currentUser == null) {
        return 'Your session expired. Please log in again to $action.';
      }
      return _withDebugDetail(
        "You don't have permission to $action.",
        'Check firestore.rules and App Check settings.',
      );

    case 'unauthenticated':
      return 'Your session expired. Please log in again to $action.';

    case 'unavailable':
    case 'network-request-failed':
      return 'You appear to be offline. Check your connection and try again.';

    case 'deadline-exceeded':
      return 'That took too long. Please try again.';

    case 'not-found':
      return 'That item no longer exists. Try refreshing.';

    case 'already-exists':
      return 'That item already exists.';

    case 'aborted':
    case 'failed-precondition':
      return 'Something changed while you were working. Refresh and try again.';

    case 'resource-exhausted':
      return 'Too many requests right now. Please wait a moment and try again.';

    case 'cancelled':
      return 'That action was cancelled.';
  }

  if (error is FirebaseAuthException) {
    return _withDebugDetail(
      'Could not $action. Please try again.',
      '${error.code}: ${error.message ?? ''}',
    );
  }

  return _withDebugDetail(
    'Could not $action. Please try again.',
    error.toString(),
  );
}

String _withDebugDetail(String message, String detail) {
  if (!kDebugMode || detail.trim().isEmpty) return message;
  return '$message\n[debug] ${detail.trim()}';
}
