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
import 'package:iconstruct/features/onboarding/presentation/screens/display_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Required so bid pushes still deliver when the app is backgrounded/killed.
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // App Check: in debug, skip activation so local runs work when Firestore is
  // set to Monitor. If you enforce App Check, register the debug token printed
  // by FlutterFire instead of skipping, then re-enable the debug provider.
  if (kReleaseMode) {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.deviceCheck,
    );
  } else {
    debugPrint(
      'App Check skipped in debug. Keep Firestore App Check on Monitor, '
      'or enforce it only after registering a debug token.',
    );
  }

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => UserProvider())],
      child: const MyApp(),
    ),
  );
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
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const DisplayScreen(),
    );
  }
}
