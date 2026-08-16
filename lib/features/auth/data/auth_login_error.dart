/// User-facing copy for Firebase Auth sign-in failures.
String authLoginErrorMessage(String code, {String? fallback}) {
  switch (code) {
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
    case 'invalid-email':
      return 'Incorrect email or password.';
    case 'too-many-requests':
      return 'Too many attempts. Wait a moment and try again.';
    case 'user-disabled':
      return 'This account has been disabled.';
    case 'network-request-failed':
      return 'You appear to be offline. Check your connection and try again.';
    default:
      final detail = fallback?.trim();
      if (detail != null && detail.isNotEmpty) {
        return 'Could not sign in. $detail';
      }
      return 'Could not sign in. Please try again.';
  }
}

/// Strips exception class prefixes so SnackBars show only the message.
String stripAuthExceptionPrefix(Object error) {
  return error
      .toString()
      .replaceFirst(RegExp(r'^EmailApiException(\(\d+\))?: '), '')
      .replaceFirst('EmailApiException: ', '');
}
