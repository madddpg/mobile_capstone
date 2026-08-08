import 'package:flutter_test/flutter_test.dart';
import 'package:iconstruct/features/auth/data/email_service.dart';

void main() {
  test('resetPasswordCallableData sends verificationToken, not token', () {
    final payload = EmailService.resetPasswordCallableData(
      email: '  builder@example.com ',
      verificationToken: 'otp-proof-token',
      newPassword: 'NewPass123!',
    );

    expect(payload['email'], 'builder@example.com');
    expect(payload['verificationToken'], 'otp-proof-token');
    expect(payload['newPassword'], 'NewPass123!');
    expect(payload.containsKey('token'), isFalse);
  });
}
