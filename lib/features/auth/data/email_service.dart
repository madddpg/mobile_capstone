import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../core/api_config.dart';
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

class EmailService {
  final FirebaseAuth _auth;

  EmailService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  /// Centralized API request handler for authentication flows that logs parameters before making the API call
  Future<http.Response> _post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('${ApiConfig.authUrl}$endpoint');

    // Debug logging to print the full request URL before calling the API
    debugPrint('================ API REQUEST ================');
    debugPrint('POST $url');
    debugPrint('BODY: ${jsonEncode(body)}');
    debugPrint('=============================================');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      debugPrint('================ API RESPONSE ================');
      debugPrint('STATUS [${response.statusCode}] for POST $url');
      debugPrint('BODY: ${response.body}');
      debugPrint('==============================================');

      return response;
    } catch (e) {
      debugPrint('================ API ERROR ================');
      debugPrint('ERROR making request to $url: $e');
      debugPrint('===========================================');
      throw EmailApiException('Network error: Could not reach the server. $e');
    }
  }

  /// Safely decodes JSON and handles HTML fallback responses
  Map<String, dynamic> _safeDecode(http.Response response) {
    try {
      if (response.body.trim().startsWith('<')) {
        debugPrint(
          'WARNING: Received HTML instead of JSON. Backend might be returning 404 or a server error.',
        );
        return {
          'message':
              'Server returned an invalid HTML response (Status ${response.statusCode})',
        };
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('JSON Decode Error: $e');
      return {'message': 'Invalid response format from server.'};
    }
  }

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

      // Automatically update the user profile's verification status
      if (uid != null) {
        final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
        await userRef.update({
          'isVerified': true,
          'verified_at': FieldValue.serverTimestamp(),
        });
        debugPrint('OTP success. Profile updated for UID $uid.');
      }

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

      // 2. Fetch profile ONLY with user's UID
      final userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid);
      final userDoc = await userDocRef.get();

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
      if (e is EmailApiException) rethrow;
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
