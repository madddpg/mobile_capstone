import 'dart:async';
import 'dart:convert';
import 'dart:ui' show Locale;

import 'package:http/http.dart' as http;

import '../core/api_config.dart';

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
  final http.Client _client;
  final Uri _endpoint;
  final Duration _timeout;

  EmailService({
    http.Client? client,
    Uri? endpoint,
    Duration timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client(),
       _endpoint = endpoint ?? ApiConfig.constructApiUri(),
       _timeout = timeout;

  /// Sends an OTP email using your PHP API.
  ///
  /// The API must accept:
  /// - email (string)
  /// - otp (digits only, string/int)
  /// - lang (en|fil)
  ///
  /// By default this posts JSON. Set [useFormEncoding] if you prefer
  /// application/x-www-form-urlencoded.
  Future<EmailSendOtpResult> sendOtp({
    required String email,
    required String otp,
    required Locale locale,
    bool useFormEncoding = false,
  }) async {
    final normalizedOtp = otp.replaceAll(RegExp(r'\s+'), '');
    if (email.trim().isEmpty) {
      throw const EmailApiException('Email is required.');
    }
    if (!RegExp(r'^\d+$').hasMatch(normalizedOtp)) {
      throw const EmailApiException('OTP must be digits only.');
    }

    final lang = _mapLocaleToLang(locale);
    final payload = <String, String>{
      'email': email.trim(),
      'otp': normalizedOtp,
      'lang': lang,
    };

    try {
      final http.Response response;
      if (useFormEncoding) {
        response = await _client
            .post(
              _endpoint,
              headers: const {
                'Accept': 'application/json',
                'Content-Type':
                    'application/x-www-form-urlencoded; charset=utf-8',
              },
              body: payload,
            )
            .timeout(_timeout);
      } else {
        response = await _client
            .post(
              _endpoint,
              headers: const {
                'Accept': 'application/json',
                'Content-Type': 'application/json; charset=utf-8',
              },
              body: jsonEncode(payload),
            )
            .timeout(_timeout);
      }

      return _parseResponse(response);
    } on TimeoutException {
      throw const EmailApiException('Request timed out. Please try again.');
    } on http.ClientException catch (e) {
      throw EmailApiException('Network error: ${e.message}');
    } on FormatException {
      throw const EmailApiException('Invalid response from server.');
    }
  }

  EmailSendOtpResult _parseResponse(http.Response response) {
    Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(response.body);
      json = (decoded is Map<String, dynamic>) ? decoded : <String, dynamic>{};
    } catch (_) {
      json = <String, dynamic>{};
    }

    final status = json['status']?.toString();
    final message =
        json['message']?.toString() ??
        (response.statusCode >= 200 && response.statusCode < 300
            ? 'Request completed.'
            : 'Request failed.');

    final okStatusCode =
        response.statusCode >= 200 && response.statusCode < 300;
    final okStatusField = status?.toLowerCase() == 'success';

    if (okStatusCode && okStatusField) {
      return EmailSendOtpResult(success: true, message: message);
    }

    final serverMessage = message.isNotEmpty
        ? message
        : 'Failed to send email.';
    throw EmailApiException(serverMessage, statusCode: response.statusCode);
  }

  String _mapLocaleToLang(Locale locale) {
    final code = locale.languageCode.toLowerCase();

    // Common variants for Filipino/Tagalog.
    if (code == 'fil' || code == 'tl') return 'fil';

    // Default to English for all other locales.
    return 'en';
  }
}
