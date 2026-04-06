import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/api_config.dart';

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

  Future<void> register({
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
      final response = await _post('/register', {
        'firstName': firstName,
        'lastName': lastName,
        'email': trimmedEmail,
        'password': password,
      });

      final data = _safeDecode(response);
      if (response.statusCode != 201 && response.statusCode != 200) {
        throw EmailApiException(
          data['message'] ?? 'Registration failed.',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is EmailApiException) rethrow;
      throw EmailApiException('Registration failed. $e');
    }
  }

  Future<EmailOtpVerificationResult> verifyOtp({
    required String email,
    required String otp,
    String? password,
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
      final requestBody = {'email': trimmedEmail, 'otp': trimmedOtp};
      if (password != null && password.isNotEmpty) {
        requestBody['password'] = password;
      }

      final response = await _post('/verify-otp', requestBody);
      final data = _safeDecode(response);

      if (response.statusCode != 200) {
        throw EmailApiException(
          data['message'] ?? 'OTP Verification failed.',
          statusCode: response.statusCode,
        );
      }

      return EmailOtpVerificationResult(
        success: true,
        message: data['message'] ?? 'Email verified successfully.',
        verificationToken: data['uid'] as String?,
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
        final response = await _post('/forgot-password', {
          'email': trimmedEmail,
        });
        final data = _safeDecode(response);

        if (response.statusCode != 200) {
          throw EmailApiException(
            data['message'] ?? 'Failed to send OTP.',
            statusCode: response.statusCode,
          );
        }
        return EmailSendOtpResult(
          success: true,
          message: data['message'] ?? 'OTP sent. Please check your inbox.',
        );
      }

      final response = await _post('/resend-otp', {'email': trimmedEmail});
      final data = _safeDecode(response);

      if (response.statusCode != 200) {
        throw EmailApiException(
          data['message'] ?? 'Failed to resend OTP.',
          statusCode: response.statusCode,
        );
      }
      return EmailSendOtpResult(
        success: true,
        message: data['message'] ?? 'OTP sent. Please check your inbox.',
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
      // 1. Verify locally with Node
      final response = await _post('/login', {
        'email': trimmedEmail,
        'password': password,
      });
      final data = _safeDecode(response);

      if (response.statusCode != 200) {
        throw EmailApiException(
          data['message'] ?? 'Login failed.',
          statusCode: response.statusCode,
        );
      }

      // 2. Sign in with Firebase
      return await _auth.signInWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );
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
      final response = await _post('/reset-password', {
        'email': trimmedEmail,
        'verificationToken': verificationToken,
        'newPassword': newPassword,
      });

      final data = _safeDecode(response);
      if (response.statusCode != 200) {
        throw EmailApiException(
          data['message'] ?? 'Failed to reset password. Please try again.',
          statusCode: response.statusCode,
        );
      }
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
