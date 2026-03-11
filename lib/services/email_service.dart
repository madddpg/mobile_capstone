import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

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
  final FirebaseFunctions _functions;

  EmailService({FirebaseAuth? auth, FirebaseFunctions? functions})
    : _auth = auth ?? FirebaseAuth.instance,
      _functions = functions ?? FirebaseFunctions.instance;

  /// Sends a real email OTP to the currently signed-in user via Cloud Functions.
  Future<EmailSendOtpResult> sendOtp({required String email}) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      throw const EmailApiException('Email is required.');
    }

    final user = _auth.currentUser;
    if (user == null ||
        user.email?.toLowerCase() != trimmedEmail.toLowerCase()) {
      throw const EmailApiException(
        'OTP can only be sent for the currently signed-in user.',
      );
    }

    try {
      final callable = _functions.httpsCallable('sendEmailOtp');
      final response = await callable.call(<String, dynamic>{
        'email': trimmedEmail,
      });
      final data = Map<String, dynamic>.from(response.data as Map);

      return EmailSendOtpResult(
        success: data['success'] == true,
        message:
            (data['message'] as String?) ??
            'OTP sent. Please check your inbox.',
      );
    } on FirebaseFunctionsException catch (e) {
      throw EmailApiException(_mapFunctionError(e), statusCode: _statusFor(e));
    } catch (_) {
      throw const EmailApiException('Failed to send OTP email.');
    }
  }

  Future<EmailSendOtpResult> verifyOtp({
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
      await _auth.currentUser?.reload();

      return EmailSendOtpResult(
        success: data['success'] == true,
        message: (data['message'] as String?) ?? 'Email verified successfully.',
      );
    } on FirebaseFunctionsException catch (e) {
      throw EmailApiException(_mapFunctionError(e), statusCode: _statusFor(e));
    } catch (_) {
      throw const EmailApiException('Failed to verify the OTP code.');
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

      try {
        await sendOtp(email: trimmedEmail);
      } on EmailApiException catch (e) {
        throw EmailApiException(
          'Account created, but OTP email could not be sent. ${e.message}',
        );
      }

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

  Future<EmailSendOtpResult> sendCurrentUserOtp() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const EmailApiException('No signed-in user found.');
    }

    return sendOtp(email: user.email ?? '');
  }

  /// Currently signed-in Firebase user (if any).
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
      default:
        return null;
    }
  }
}
