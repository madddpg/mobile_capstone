class ApiConfig {
  /// Base URL where your PHP API is hosted.
  ///
  /// Examples:
  /// - Android emulator (XAMPP on host machine): http://10.0.2.2
  /// - iOS simulator (macOS): http://127.0.0.1
  /// - Physical device: http://your-lan-ip
  ///
  /// Override without code changes using:
  /// `flutter run --dart-define=API_BASE_URL=http://your-lan-ip`
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2',
  );

  /// Your PHP entry point file.
  static const String constructApiPath = '/construct_api.php';

  static Uri constructApiUri() => Uri.parse(baseUrl).resolve(constructApiPath);
}
