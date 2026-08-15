import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconstruct/core/services/fcm_service.dart';
import 'user_model.dart';

class UserProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  StreamSubscription<DocumentSnapshot>? _userSubscription;

  UserProvider() {
    _initListener();
  }

  void _initListener() {
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        // Unverified Auth sessions (failed/incomplete registration) must not
        // bind this device's push token or load a builder profile.
        if (!user.emailVerified) {
          await _userSubscription?.cancel();
          _currentUser = null;
          notifyListeners();
          return;
        }
        _subscribeToUserData(user.uid);
        // Register / refresh device token on every signed-in session restore.
        await FCMService().initFCM(user.uid);
      } else {
        _userSubscription?.cancel();
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  void _subscribeToUserData(String uid) {
    _userSubscription?.cancel();
    _userSubscription = _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.exists && snapshot.data() != null) {
              final data = snapshot.data() as Map<String, dynamic>;
              // Use user.email from auth if the doc doesn't have an email field yet
              if (!data.containsKey('email')) {
                data['email'] = _auth.currentUser?.email ?? '';
              }
              _currentUser = UserModel.fromMap(uid, data);
              notifyListeners();
            }
          },
          onError: (error) {
            debugPrint('Error listening to user data: $error');
          },
        );
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}
