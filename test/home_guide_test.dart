import 'package:flutter_test/flutter_test.dart';
import 'package:iconstruct/features/onboarding/data/home_guide_steps.dart';

void main() {
  group('homeGuideSteps', () {
    test('walks estimate → quotations → compare, and stays skippable in copy', () {
      final steps = homeGuideSteps(firstName: 'Ahmad');

      expect(steps, hasLength(4));
      expect(steps.first.target, HomeGuideTarget.welcome);
      expect(steps.first.title, 'Welcome, Ahmad.');
      expect(steps.last.nextLabel, 'Got it');

      final joined = steps.map((s) => '${s.title} ${s.body}').join(' ').toLowerCase();
      expect(joined, contains('estimate'));
      expect(joined, contains('quotation'));
      expect(joined, isNot(contains('crew')));
      expect(joined, isNot(contains('construction site')));
      expect(joined, isNot(contains('schedule')));
    });

    test('falls back to a generic welcome without a first name', () {
      expect(homeGuideSteps().first.title, 'Welcome.');
      expect(homeGuideSteps(firstName: 'User').first.title, 'Welcome.');
    });
  });
}
