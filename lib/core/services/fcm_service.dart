import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:iconstruct/main.dart'; // import navigatorKey
import 'package:iconstruct/features/bidding/screens/quotations_screen.dart'; // Depending on actual path

class FCMService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final FCMService _instance = FCMService._internal();

  factory FCMService() {
    return _instance;
  }

  FCMService._internal();

  Future<void> initFCM(String uid) async {
    if (uid.isEmpty) return;

    try {
      // 1. Request Notification Permission
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            sound: true,
          );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted permission for notifications');

        // 2. Get initial FCM token
        String? token = await _firebaseMessaging.getToken();
        if (token != null) {
          debugPrint('FCM Token: $token');
          await saveUserToken(uid, token);
        }

        // 3. Handle Token Refresh (IMPORTANT)
        _firebaseMessaging.onTokenRefresh.listen((newToken) {
          debugPrint('FCM Token Refreshed: $newToken');
          saveUserToken(uid, newToken);
        });

        // 4. Optional: Handle Foreground Notifications
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint("Foreground notification received!");
          if (message.notification != null) {
            debugPrint("Title: ${message.notification?.title}");
            debugPrint("Body: ${message.notification?.body}");
          }
        });

        // 5. Handle Background App Taps
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          debugPrint('Notification tapped (from background): ${message.data}');
          handleNotificationNavigation(message);
        });

        // 6. Handle Terminated App Taps (Initial Message)
        RemoteMessage? initialMessage = await _firebaseMessaging
            .getInitialMessage();
        if (initialMessage != null) {
          debugPrint(
            'Notification tapped (from terminated state): ${initialMessage.data}',
          );
          // Adding a short delay helps ensure the main widget tree is built first
          Future.delayed(const Duration(milliseconds: 500), () {
            handleNotificationNavigation(initialMessage);
          });
        }
      } else {
        debugPrint('User declined or has not accepted notification permission');
      }
    } catch (e) {
      debugPrint("Error initializing FCM: $e");
    }
  }

  Future<void> saveUserToken(String uid, String token) async {
    try {
      final userRef = _firestore.collection('users').doc(uid);

      // Use arrayUnion to prevent overwriting existing device tokens
      // Used SetOptions(merge: true) to safely create or merge
      await userRef.set({
        'fcmTokens': FieldValue.arrayUnion([token]),
      }, SetOptions(merge: true));

      debugPrint('Token successfully saved to users/$uid');
    } catch (e) {
      debugPrint('Error saving FCM token to Firestore: $e');
    }
  }

  void handleNotificationNavigation(RemoteMessage message) {
    if (message.data.isEmpty) return;

    final type = message.data['type'];
    final postId = message.data['postId'];
    final notificationId = message.data['notificationId']; // if available

    debugPrint("Handling navigation for type: $type, postId: $postId");

    // Optional: Mark as read
    if (notificationId != null && notificationId.toString().isNotEmpty) {
      _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true})
          .catchError(
            (e) => debugPrint(
              "Failed to mark notification $notificationId as read: $e",
            ),
          );
    }

    if (type == 'new_quotation' &&
        postId != null &&
        postId.toString().isNotEmpty) {
      final currentState = navigatorKey.currentState;
      if (currentState != null) {
        currentState.push(
          MaterialPageRoute(
            builder: (context) => QuotationsScreen(postId: postId),
          ),
        );
      } else {
        debugPrint(
          "Error: navigatorKey.currentState is null. Cannot navigate.",
        );
      }
    }
  }
}
