import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers that a builder has already been through the intro slides so the
/// app opens straight into sign-in (or the home screen) on later launches.
class OnboardingPreferences {
  const OnboardingPreferences._();

  static const String _introSeenKey = 'onboarding_intro_seen_v1';

  static Future<bool> hasSeenIntro() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_introSeenKey) ?? false;
    } catch (e) {
      // Treat storage failures as "not seen": showing the intro again is a much
      // smaller problem than blocking startup.
      debugPrint('Could not read onboarding preference: $e');
      return false;
    }
  }

  static Future<void> markIntroSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_introSeenKey, true);
    } catch (e) {
      debugPrint('Could not persist onboarding preference: $e');
    }
  }
}
