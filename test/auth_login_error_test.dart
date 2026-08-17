import 'package:flutter_test/flutter_test.dart';
import 'package:iconstruct/features/auth/data/auth_login_error.dart';
import 'package:iconstruct/features/project_creation/data/project_lifecycle.dart';

void main() {
  group('authLoginErrorMessage', () {
    test(
      'maps wrong password and sibling credential codes to one clear line',
      () {
        expect(
          authLoginErrorMessage('wrong-password'),
          'Incorrect email or password.',
        );
        expect(
          authLoginErrorMessage('invalid-credential'),
          'Incorrect email or password.',
        );
        expect(
          authLoginErrorMessage('user-not-found'),
          'Incorrect email or password.',
        );
      },
    );

    test('maps lockout, disabled, and offline codes', () {
      expect(
        authLoginErrorMessage('too-many-requests'),
        contains('Too many attempts'),
      );
      expect(authLoginErrorMessage('user-disabled'), contains('disabled'));
      expect(
        authLoginErrorMessage('network-request-failed'),
        contains('offline'),
      );
    });

    test('strips EmailApiException prefixes from SnackBar copy', () {
      expect(
        stripAuthExceptionPrefix(
          'EmailApiException: Incorrect email or password.',
        ),
        'Incorrect email or password.',
      );
      expect(
        stripAuthExceptionPrefix(
          'EmailApiException(401): Incorrect email or password.',
        ),
        'Incorrect email or password.',
      );
    });
  });

  group('ProjectLifecycle posting gates', () {
    test('posted estimates are not treated as still-planning', () {
      expect(
        ProjectLifecycle.isPosted(
          ProjectLifecycle.waitingForQuotations,
          postId: 'post-1',
        ),
        isTrue,
      );
      expect(ProjectLifecycle.isPlanning(ProjectLifecycle.planning), isTrue);
      expect(
        ProjectLifecycle.isPlanning(ProjectLifecycle.waitingForQuotations),
        isFalse,
      );
    });
  });
}
