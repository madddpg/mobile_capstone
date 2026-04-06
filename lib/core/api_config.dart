import 'dart:io';
import 'package:flutter/foundation.dart';

/// Define the current environment
enum Environment { dev, staging, prod }

class ApiConfig {
  /// Toggle this to switch between environments (Dev vs Production)
  static const Environment currentEnv = Environment.dev;

  /// Toggle this if you are using an Android Emulator instead of a real device
  static const bool isAndroidEmulator = false;

  /// Your laptop's local IP address (Required for real physical devices on Wi-Fi)
  static const String localIp = '192.168.1.5';

  /// Your local Firebase/Node backend port
  static const String localPort = '5000';

  /// Your base API path (leave empty if backend is hosted right on the port)
  static const String apiBasePath = '';

  /// Dynamically computes the correct Base URL based on environment and device
  static String get baseUrl {
    switch (currentEnv) {
      case Environment.prod:
        // Use your full Firebase URL here for production
        return 'https://us-central1-iconstruct-58a87.cloudfunctions.net/api';
      case Environment.staging:
        return 'https://api.yourstagingdomain.com$apiBasePath';
      case Environment.dev:
        return _getLocalBaseUrl();
    }
  }

  /// Handles Localhost mappings across Web, Android, and iOS
  static String _getLocalBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:$localPort$apiBasePath';
    }

    if (Platform.isAndroid) {
      // 10.0.2.2 routes to the host machine's localhost from the Android Emulator.
      // 192.168.x.x is required for a real physical device connecting over Wi-Fi.
      return isAndroidEmulator
          ? 'http://10.0.2.2:$localPort$apiBasePath'
          : 'http://$localIp:$localPort$apiBasePath';
    }

    if (Platform.isIOS) {
      // iOS Simulator natively spans to localhost, but a real iOS device needs the local IP.
      // We default to the local IP to safely support real iOS devices on Wi-Fi as well.
      return 'http://$localIp:$localPort$apiBasePath';
    }

    // Fallback for Windows/Mac/Linux desktop apps
    return 'http://localhost:$localPort$apiBasePath';
  }

  /// Specific endpoints (avoids hardcoding Paths everywhere)
  static String get authUrl => '$baseUrl/auth';
}
