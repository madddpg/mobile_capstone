import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

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
  final FirebaseFunctions _functions;

  EmailService({FirebaseAuth? auth, FirebaseFunctions? functions})
    : _auth = auth ?? FirebaseAuth.instance,
      _functions = functions ?? FirebaseFunctions.instance;

  Future<EmailSendOtpResult> sendOtp({
    required String email,
    bool isPasswordReset = false,
  }) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      throw const EmailApiException('Email is required.');
    }

    try {
      final callable = _functions.httpsCallable('sendEmailOtp');
      final payload = <String, dynamic>{'email': trimmedEmail};
      if (isPasswordReset) {
        payload['purpose'] = 'password_reset';
      }
      final response = await callable.call(payload);
      final data = Map<String, dynamic>.from(response.data as Map);

      return EmailSendOtpResult(
        success: data['success'] == true,
        message:
            (data['message'] as String?) ??
            'OTP sent. Please check your inbox.',
      );
    } on FirebaseFunctionsException catch (e) {
      throw EmailApiException(_mapFunctionError(e), statusCode: _statusFor(e));
    } catch (e) {
      throw EmailApiException('Failed to send OTP email. ${e.toString()}');
    }
  }

  Future<EmailOtpVerificationResult> verifyOtp({
    required String email,
    required String otp,
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
      final callable = _functions.httpsCallable('verifyEmailOtp');
      final response = await callable.call(<String, dynamic>{
        'email': trimmedEmail,
        'otp': trimmedOtp,
      });
      final data = Map<String, dynamic>.from(response.data as Map);

      return EmailOtpVerificationResult(
        success: data['success'] == true,
        message: (data['message'] as String?) ?? 'Email verified successfully.',
        verificationToken: data['verificationToken'] as String?,
      );
    } on FirebaseFunctionsException catch (e) {
      throw EmailApiException(_mapFunctionError(e), statusCode: _statusFor(e));
    } catch (e) {
      throw EmailApiException('Failed to verify the OTP code. ${e.toString()}');
    }
  }

  Future<EmailSendOtpResult> verifyOtpForCurrentUser({
    required String email,
    required String otp,
  }) async {
    final verificationResult = await verifyOtp(email: email, otp: otp);
    final verificationToken = verificationResult.verificationToken;

    if (verificationToken == null || verificationToken.isEmpty) {
      throw const EmailApiException(
        'Verification finished without a registration proof token.',
      );
    }

    return _finalizeVerifiedEmail(
      email: email,
      verificationToken: verificationToken,
    );
  }

  Future<UserCredential> register({
    required String email,
    required String password,
    required String verificationToken,
  }) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || password.isEmpty || verificationToken.isEmpty) {
      throw const EmailApiException(
        'Email, password, and OTP verification are required.',
      );
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );

      await _finalizeVerifiedEmail(
        email: trimmedEmail,
        verificationToken: verificationToken,
      );

      return credential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return _resumeExistingRegistration(
          email: trimmedEmail,
          password: password,
          verificationToken: verificationToken,
        );
      }

      throw EmailApiException(e.message ?? 'Registration failed.');
    } catch (e) {
      throw EmailApiException('Registration failed. ${e.toString()}');
    }
  }

  Future<UserCredential> _resumeExistingRegistration({
    required String email,
    required String password,
    required String verificationToken,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await credential.user?.reload();

      if (credential.user?.emailVerified ?? false) {
        throw const EmailApiException(
          'This email is already registered and verified. Please log in instead.',
        );
      }

      await _finalizeVerifiedEmail(
        email: email,
        verificationToken: verificationToken,
      );

      return credential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw const EmailApiException(
          'This email is already registered. Enter the existing password or log in instead.',
        );
      }

      throw EmailApiException(
        e.message ?? 'This email is already registered. Please log in instead.',
      );
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
      return await _auth.signInWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw EmailApiException(e.message ?? 'Login failed.');
    } catch (e) {
      throw EmailApiException('Login failed. ${e.toString()}');
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
      throw const EmailApiException(
        'Email, verification token, and new password are required.',
      );
    }
    if (newPassword.length < 6) {
      throw const EmailApiException('Password must be at least 6 characters.');
    }

    try {
      final callable = _functions.httpsCallable('resetPasswordWithToken');
      final response = await callable.call(<String, dynamic>{
        'email': trimmedEmail,
        'verificationToken': verificationToken,
        'newPassword': newPassword,
      });
      final data = Map<String, dynamic>.from(response.data as Map);
      if (data['success'] != true) {
        throw const EmailApiException(
          'Failed to reset password. Please try again.',
        );
      }
    } on FirebaseFunctionsException catch (e) {
      throw EmailApiException(_mapFunctionError(e), statusCode: _statusFor(e));
    } catch (e) {
      if (e is EmailApiException) rethrow;
      throw EmailApiException('Failed to reset password. ${e.toString()}');
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

  Future<EmailSendOtpResult> _finalizeVerifiedEmail({
    required String email,
    required String verificationToken,
  }) async {
    try {
      final callable = _functions.httpsCallable('finalizeEmailOtpRegistration');
      final response = await callable.call(<String, dynamic>{
        'email': email.trim(),
        'verificationToken': verificationToken,
      });
      final data = Map<String, dynamic>.from(response.data as Map);
      await _auth.currentUser?.reload();

      return EmailSendOtpResult(
        success: data['success'] == true,
        message: (data['message'] as String?) ?? 'Email verified successfully.',
      );
    } on FirebaseFunctionsException catch (e) {
      throw EmailApiException(_mapFunctionError(e), statusCode: _statusFor(e));
    } catch (e) {
      throw EmailApiException(
        'Failed to finalize email verification. ${e.toString()}',
      );
    }
  }

  User? get currentUser => _auth.currentUser;

  String _mapFunctionError(FirebaseFunctionsException error) {
    return error.message ?? 'A server error occurred.';
  }

  int? _statusFor(FirebaseFunctionsException error) {
    switch (error.code) {
      case 'invalid-argument':
        return 400;
      case 'unauthenticated':
        return 401;
      case 'permission-denied':
        return 403;
      case 'not-found':
        return 404;
      case 'resource-exhausted':
        return 429;
      case 'deadline-exceeded':
        return 504;
      case 'failed-precondition':
        return 412;
      default:
        return null;
    }
  }
}
