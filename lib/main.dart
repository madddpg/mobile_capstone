import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:iconstruct/core/services/fcm_service.dart';
import 'package:iconstruct/core/state/user_state/user_provider.dart';
import 'firebase_options.dart';
import 'package:iconstruct/core/theme/app_theme.dart';
import 'package:iconstruct/core/widgets/offline_banner.dart';
import 'package:iconstruct/features/onboarding/presentation/screens/display_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Required so bid pushes still deliver when the app is backgrounded/killed.
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await _activateAppCheck();

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => UserProvider())],
      child: const MyApp(),
    ),
  );
}

/// Debug uses the App Check debug provider so the native SDKs have a provider
/// installed (otherwise Functions logs "No AppCheckProvider installed" and
/// verify can fail with INVALID_ARGUMENT). Release uses Play Integrity /
/// DeviceCheck. Copy the debug token from logcat into Firebase Console →
/// App Check → Manage debug tokens. OTP callables do not enforce App Check.
Future<void> _activateAppCheck() async {
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: kReleaseMode
          ? AndroidProvider.playIntegrity
          : AndroidProvider.debug,
      appleProvider: kReleaseMode
          ? AppleProvider.deviceCheck
          : AppleProvider.debug,
    );
    if (!kReleaseMode) {
      try {
        await FirebaseAppCheck.instance.getToken(true);
        debugPrint('App Check debug token was accepted by Firebase.');
      } catch (e) {
        debugPrint(
          'App Check attestation failed: $e\n'
          'Next steps:\n'
          '1) In Logcat search: DebugAppCheckProvider\n'
          '2) Copy the UUID debug secret\n'
          '3) Firebase Console → App Check → ⋮ → Manage debug tokens → Add\n'
          '4) App Check → APIs → Cloud Functions → Monitor (not Enforce)\n'
          '5) Wait a minute, then full-restart the app',
        );
      }
    }
  } catch (e) {
    debugPrint('App Check could not start: $e');
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'iConstruct',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // Cap runaway system font scaling so estimate tables stay readable while
      // still honouring a user's accessibility preference.
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(
              minScaleFactor: 1.0,
              maxScaleFactor: 1.3,
            ),
          ),
          child: OfflineBannerHost(child: child ?? const SizedBox.shrink()),
        );
      },
      home: const DisplayScreen(),
    );
  }
}
