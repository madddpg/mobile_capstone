import 'package:firebase_auth/firebase_auth.dart';

class EmailActionResult {
  final bool success;
  final String message;

  const EmailActionResult({required this.success, required this.message});
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

  Future<EmailActionResult> sendVerificationEmail({User? user}) async {
    final currentUser = user ?? _auth.currentUser;
    final email = currentUser?.email?.trim();

    if (currentUser == null || email == null || email.isEmpty) {
      throw const EmailApiException(
        'No signed-in user with an email was found.',
      );
    }

    try {
      await currentUser.sendEmailVerification();

      return const EmailActionResult(
        success: true,
        message: 'Verification email sent. Check your inbox and spam folder.',
      );
    } on FirebaseAuthException catch (e) {
      throw EmailApiException(
        e.message ?? 'Could not send the verification email.',
      );
    } catch (e) {
      throw EmailApiException(
        'Could not send the verification email. ${e.toString()}',
      );
    }
  }

  Future<EmailActionResult> checkEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const EmailApiException('No signed-in user found.');
    }

    try {
      await user.reload();
      final refreshedUser = _auth.currentUser;
      if (refreshedUser?.emailVerified ?? false) {
        return const EmailActionResult(
          success: true,
          message: 'Email verified successfully.',
        );
      }

      throw const EmailApiException(
        'Email not verified yet. Open the verification link from your inbox, then try again.',
      );
    } on FirebaseAuthException catch (e) {
      throw EmailApiException(
        e.message ?? 'Could not refresh your verification status.',
      );
    } catch (e) {
      if (e is EmailApiException) {
        rethrow;
      }

      throw EmailApiException(
        'Could not refresh your verification status. ${e.toString()}',
      );
    }
  }

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
        await sendVerificationEmail(user: credential.user);
      } on EmailApiException catch (e) {
        throw EmailApiException(
          'Account created, but verification email could not be sent. ${e.message}',
        );
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return _resumeExistingRegistration(
          email: trimmedEmail,
          password: password,
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

      try {
        await sendVerificationEmail(user: credential.user);
      } on EmailApiException catch (e) {
        throw EmailApiException(
          'This account already exists and is awaiting verification, but the verification email could not be sent. ${e.message}',
        );
      }

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

  Future<void> logout() => _auth.signOut();

  Future<void> reloadCurrentUser() async {
    await _auth.currentUser?.reload();
  }

  Future<EmailActionResult> sendCurrentUserVerificationEmail() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const EmailApiException('No signed-in user found.');
    }

    return sendVerificationEmail(user: user);
  }

  User? get currentUser => _auth.currentUser;
}
