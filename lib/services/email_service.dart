import 'dart:ui' show Locale;

import 'package:firebase_auth/firebase_auth.dart';

class EmailSendOtpResult {
  final bool success;
  final String message;

  const EmailSendOtpResult({required this.success, required this.message});
}

class EmailApiException implements Exception {
  final String message;
  final int? statusCode;

  const EmailApiException(this.message, {this.statusCode});

  @override
  String toString() => statusCode == null
      ? 'EmailApiException: $message'
      : 'EmailApiException($statusCode): $message';
}

class EmailService {
  final FirebaseAuth _auth;

  EmailService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  /// Sends Firebase's verification email to the currently signed in user.
  Future<EmailSendOtpResult> sendOtp({
    required String email,
    required String otp,
    required Locale locale,
    bool useFormEncoding = false,
  }) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      throw const EmailApiException('Email is required.');
    }

    final user = _auth.currentUser;
    if (user == null ||
        user.email?.toLowerCase() != trimmedEmail.toLowerCase()) {
      throw const EmailApiException(
        'Verification email can only be sent for the currently signed-in user.',
      );
    }

    _mapLocaleToLang(locale);

    try {
      await user.sendEmailVerification();
      return const EmailSendOtpResult(
        success: true,
        message: 'Verification email sent. Please check your inbox.',
      );
    } on FirebaseAuthException catch (e) {
      throw EmailApiException(
        e.message ?? 'Failed to send verification email.',
      );
    } catch (_) {
      throw const EmailApiException('Failed to send verification email.');
    }
  }

  /// Registers a new user with Firebase Authentication using email/password.
  Future<UserCredential> register({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || password.isEmpty) {
      throw const EmailApiException('Email and password are required.');
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );

      // Try to send a verification email; ignore errors here.
      await credential.user?.sendEmailVerification();

      return credential;
    } on FirebaseAuthException catch (e) {
      throw EmailApiException(e.message ?? 'Registration failed.');
    } catch (_) {
      throw const EmailApiException('Registration failed.');
    }
  }

  /// Logs in an existing user with Firebase Authentication.
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || password.isEmpty) {
      throw const EmailApiException('Email and password are required.');
    }

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw EmailApiException(e.message ?? 'Login failed.');
    } catch (_) {
      throw const EmailApiException('Login failed.');
    }
  }

  /// Signs out the current Firebase user.
  Future<void> logout() => _auth.signOut();

  Future<void> reloadCurrentUser() async {
    await _auth.currentUser?.reload();
  }

  Future<void> sendCurrentUserVerificationEmail() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const EmailApiException('No signed-in user found.');
    }

    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw EmailApiException(
        e.message ?? 'Failed to send verification email.',
      );
    }
  }

  /// Currently signed-in Firebase user (if any).
  User? get currentUser => _auth.currentUser;

  String _mapLocaleToLang(Locale locale) {
    final code = locale.languageCode.toLowerCase();

    // Common variants for Filipino/Tagalog.
    if (code == 'fil' || code == 'tl') return 'fil';

    // Default to English for all other locales.
    return 'en';
  }
}
