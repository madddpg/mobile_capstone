import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../core/services/fcm_service.dart';

class EmailSendOtpResult {
  final bool success;
  final String message;

  const EmailSendOtpResult({required this.success, required this.message});
}

class EmailOtpVerificationResult {
  final bool success;
  final String message;
  final String? verificationToken;

  const EmailOtpVerificationResult({
    required this.success,
    required this.message,
    this.verificationToken,
  });
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

/// Thrown when credentials are correct but the email was never verified.
///
/// Carries the identifiers the UI needs to reopen the OTP step so the builder
/// can verify immediately instead of being locked out.
class EmailNotVerifiedException implements Exception {
  final String email;
  final String uid;
  final String message;

  const EmailNotVerifiedException({
    required this.email,
    required this.uid,
    this.message =
        'Please verify your email to continue. We sent you a new code.',
  });

  @override
  String toString() => 'EmailNotVerifiedException: $message';
}

class EmailService {
  final FirebaseAuth _auth;

  EmailService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  Future<String> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || password.isEmpty || firstName.isEmpty) {
      throw const EmailApiException('All fields are required.');
    }

    try {
      debugPrint('================ REGISTRATION FLOW ================');
      debugPrint('Attempting Firebase Registration for email: $trimmedEmail');

      // 1. Create the Firebase Auth user first
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );
      final uid = userCredential.user!.uid;

      debugPrint('Registered successfully. Auth UID: $uid');
      debugPrint('Auth Email: ${userCredential.user!.email}');

      // 2. Create the Firestore profile aligned to the UID
      debugPrint('Creating Firestore document at users/$uid');
      await createUserDocument(
        uid: uid,
        firstName: firstName,
        lastName: lastName,
        email: trimmedEmail,
      );

      debugPrint('Firestore doc created successfully.');

      // 3. Trigger OTP through Callable Cloud Function
      debugPrint(
        'Triggering OTP via Callable Function for email: $trimmedEmail',
      );
      final httpsCallable = FirebaseFunctions.instance.httpsCallable(
        'sendEmailOtp',
      );
      await httpsCallable.call({'email': trimmedEmail});

      debugPrint('OTP send success');

      // 4. Sign out immediately so they aren't authenticated yet
      await _auth.signOut();
      debugPrint('signOut after registration');

      debugPrint('================ REGISTRATION COMPLETE ================');
      return uid;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
      if (e.code == 'email-already-in-use') {
        throw EmailApiException(
          'The email address is already in use by another account.',
        );
      } else if (e.code == 'weak-password') {
        throw EmailApiException('The password provided is too weak.');
      } else if (e.code == 'invalid-email') {
        throw EmailApiException('The email address is badly formatted.');
      }
      throw EmailApiException('Registration failed: ${e.message}');
    } catch (e) {
      if (e is EmailApiException) rethrow;
      throw EmailApiException('Registration failed. $e');
    }
  }

  /// Helper method to create a clean user document ensuring duplicates are avoided
  Future<void> createUserDocument({
    required String uid,
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    await userRef.set(
      {
        'firebaseUid': uid,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'isVerified': false,
        'created_at': FieldValue.serverTimestamp(),
        'verified_at': null,
      },
      SetOptions(merge: true),
    ); // Prefer merge to not overwrite existing valid chunks
  }

  Future<EmailOtpVerificationResult> verifyOtp({
    required String email,
    required String otp,
    String? uid,
  }) async {
    final trimmedEmail = email.trim();
    final trimmedOtp = otp.trim();

    if (trimmedEmail.isEmpty || trimmedOtp.isEmpty) {
      throw const EmailApiException('Email and OTP are required.');
    }
    if (!RegExp(r'^\d{6}$').hasMatch(trimmedOtp)) {
      throw const EmailApiException('Enter the 6-digit OTP code.');
    }

    try {
      final httpsCallable = FirebaseFunctions.instance.httpsCallable(
        'verifyEmailOtp',
      );
      final result = await httpsCallable.call({
        'email': trimmedEmail,
        'otp': trimmedOtp,
      });
      final data = result.data as Map<String, dynamic>;

      // verifyEmailOtp marks the account verified server-side. The client is
      // signed out at this point, so it cannot write users/{uid} itself.
      debugPrint('OTP verified for ${uid ?? trimmedEmail}.');

      return EmailOtpVerificationResult(
        success: true,
        message: data['message'] ?? 'Email verified successfully.',
        verificationToken: data['verificationToken'] as String?,
      );
    } on FirebaseFunctionsException catch (e) {
      throw EmailApiException(
        'OTP Verification failed: ${e.message}',
        statusCode: e.code.hashCode,
      );
    } catch (e) {
      if (e is EmailApiException) rethrow;
      throw EmailApiException('Failed to verify the OTP code. $e');
    }
  }

  Future<EmailSendOtpResult> sendOtp({
    required String email,
    bool isPasswordReset = false,
  }) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      throw const EmailApiException('Email is required.');
    }

    try {
      if (isPasswordReset) {
        final httpsCallable = FirebaseFunctions.instance.httpsCallable(
          'sendEmailOtp',
        );
        // If your reset password flow triggers from the identical endpoint, or if you use resetPasswordWithToken:
        await httpsCallable.call({
          'email': trimmedEmail,
          // 'isPasswordReset': true // Add this on backend if needed
        });

        return const EmailSendOtpResult(
          success: true,
          message: 'OTP sent. Please check your inbox.',
        );
      }

      final httpsCallable = FirebaseFunctions.instance.httpsCallable(
        'sendEmailOtp',
      );
      await httpsCallable.call({'email': trimmedEmail});

      return const EmailSendOtpResult(
        success: true,
        message: 'OTP sent. Please check your inbox.',
      );
    } on FirebaseFunctionsException catch (e) {
      throw EmailApiException(
        'Failed to send OTP: ${e.message}',
        statusCode: e.code.hashCode,
      );
    } catch (e) {
      if (e is EmailApiException) rethrow;
      throw EmailApiException('Failed to send OTP email. $e');
    }
  }

  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || password.isEmpty) {
      throw const EmailApiException('Email and password are required.');
    }

    try {
      debugPrint('================ LOGIN FLOW ================');
      debugPrint('Attempting login for email: $trimmedEmail');

      // 1. Authenticate with Firebase Auth explicitly
      final credential = await _auth.signInWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );

      final uid = credential.user?.uid;

      if (uid == null) {
        throw const EmailApiException('Login failed: User UID is null.');
      }

      debugPrint('Firebase Auth UID: $uid');
      debugPrint('Auth Email: ${credential.user?.email}');

      // Ensure the Auth ID token is ready before any Firestore call.
      await credential.user!.getIdToken(true);

      // 2. Fetch profile ONLY with user's UID
      final userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid);

      DocumentSnapshot<Map<String, dynamic>> userDoc;
      try {
        userDoc = await userDocRef.get(const GetOptions(source: Source.server));
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied') {
          throw const EmailApiException(
            'Login blocked by Firestore permissions. '
            'In Firebase Console → App Check, set Cloud Firestore to Monitor '
            '(not Enforced) while developing, or install an App Check provider. '
            'Also confirm firestore.rules allow users/{uid} for signed-in owners.',
          );
        }
        rethrow;
      }

      debugPrint('Fetched Firestore doc ID: ${userDocRef.id}');
      debugPrint('Firestore doc exists: ${userDoc.exists}');

      // 3. Auto-create missing profile with merge-safe defaults
      if (!userDoc.exists) {
        debugPrint(
          'Profile missing! Auto-creating Firestore document for $uid',
        );
        await userDocRef.set({
          'firebaseUid': uid,
          'email': trimmedEmail,
          'firstName': '', // Defaults
          'lastName': '', // Defaults
          'isVerified': credential.user?.emailVerified ?? false,
          'created_at': FieldValue.serverTimestamp(),
          'verified_at': null,
        }, SetOptions(merge: true));
      }

      // 4. Refuse to hand out a session to an unverified account. A fresh code
      // is sent so the caller can surface the OTP step right away.
      final profileVerified = userDoc.data()?['isVerified'] == true;
      final authVerified = credential.user?.emailVerified ?? false;
      if (!profileVerified && !authVerified) {
        debugPrint('Login blocked: email not verified for $uid');
        await _auth.signOut();
        try {
          await sendOtp(email: trimmedEmail);
        } catch (e) {
          debugPrint('Could not resend verification OTP: $e');
        }
        throw EmailNotVerifiedException(email: trimmedEmail, uid: uid);
      }

      // Initialize FCM and store the push notification token securely into users/{uid}.fcmTokens
      // Fire-and-forget or await depending on strictness. Using await to ensure token saves before proceeding.
      await FCMService().initFCM(uid);

      debugPrint('================ LOGIN COMPLETE ================');

      return credential;
    } on FirebaseAuthException catch (e) {
      // Catch specific Firebase Auth exceptions to handle "user not found" properly
      if (e.code == 'user-not-found' ||
          e.code == 'invalid-credential' ||
          e.code == 'invalid-email') {
        throw EmailApiException(
          'Invalid email or password. User not found or incorrect credentials.',
        );
      }
      throw EmailApiException('Firebase Login failed: ${e.message}');
    } catch (e) {
      if (e is EmailApiException || e is EmailNotVerifiedException) rethrow;
      throw EmailApiException('Login failed. $e');
    }
  }

  Future<void> resetPassword({
    required String email,
    required String verificationToken,
    required String newPassword,
  }) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty ||
        verificationToken.isEmpty ||
        newPassword.isEmpty) {
      throw const EmailApiException('Missing fields for password reset.');
    }

    try {
      final httpsCallable = FirebaseFunctions.instance.httpsCallable(
        'resetPasswordWithToken',
      );
      await httpsCallable.call({
        'email': trimmedEmail,
        'token': verificationToken,
        'newPassword': newPassword,
      });
    } on FirebaseFunctionsException catch (e) {
      throw EmailApiException(
        'Failed to reset password: ${e.message}',
        statusCode: e.code.hashCode,
      );
    } catch (e) {
      if (e is EmailApiException) rethrow;
      throw EmailApiException('Failed to reset password. $e');
    }
  }

  Future<void> logout() => _auth.signOut();

  Future<void> reloadCurrentUser() async {
    await _auth.currentUser?.reload();
  }

  Future<EmailSendOtpResult> sendCurrentUserOtp() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const EmailApiException('No signed-in user found.');
    }
    return sendOtp(email: user.email ?? '');
  }

  User? get currentUser => _auth.currentUser;
}
