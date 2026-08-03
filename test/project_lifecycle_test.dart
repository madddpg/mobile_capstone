import 'package:flutter_test/flutter_test.dart';

import 'package:iconstruct/features/project_creation/data/project_lifecycle.dart';

void main() {
  group('stageIndex', () {
    test('maps canonical statuses', () {
      expect(
        ProjectLifecycle.stageIndex(ProjectLifecycle.draft),
        ProjectLifecycle.stageDraft,
      );
      expect(
        ProjectLifecycle.stageIndex(ProjectLifecycle.receivingQuotations),
        ProjectLifecycle.stageReceiving,
      );
      expect(
        ProjectLifecycle.stageIndex(ProjectLifecycle.completed),
        ProjectLifecycle.stageCompleted,
      );
    });

    test('maps legacy statuses written by earlier builds', () {
      expect(ProjectLifecycle.stageIndex('ready'), ProjectLifecycle.stagePlanning);
      expect(ProjectLifecycle.stageIndex('posted'), ProjectLifecycle.stageWaiting);
      expect(
        ProjectLifecycle.stageIndex('has_quotations'),
        ProjectLifecycle.stageReceiving,
      );
      expect(
        ProjectLifecycle.stageIndex('offer_accepted'),
        ProjectLifecycle.stageSupplierSelected,
      );
    });

    test('falls back to draft for unknown values', () {
      expect(ProjectLifecycle.stageIndex('whatever'), ProjectLifecycle.stageDraft);
      expect(ProjectLifecycle.stageIndex(''), ProjectLifecycle.stageDraft);
    });
  });

  group('stageFromPost', () {
    test('a post with no bids is waiting for quotations', () {
      expect(
        ProjectLifecycle.stageFromPost({'status': 'open', 'quotationCount': 0}),
        ProjectLifecycle.stageWaiting,
      );
    });

    test('bids advance to receiving quotations', () {
      expect(
        ProjectLifecycle.stageFromPost({'status': 'open', 'quotationCount': 2}),
        ProjectLifecycle.stageReceiving,
      );
      expect(
        ProjectLifecycle.stageFromPost({'status': 'has_quotations'}),
        ProjectLifecycle.stageReceiving,
      );
    });

    test('an accepted offer advances to supplier selected', () {
      expect(
        ProjectLifecycle.stageFromPost({
          'status': 'offer_accepted',
          'selectedQuotationId': 'quote-1',
          'quotationCount': 3,
        }),
        ProjectLifecycle.stageSupplierSelected,
      );
    });
  });

  test('canMarkComplete only after a supplier is selected', () {
    expect(ProjectLifecycle.canMarkComplete(ProjectLifecycle.draft), isFalse);
    expect(
      ProjectLifecycle.canMarkComplete(ProjectLifecycle.receivingQuotations),
      isFalse,
    );
    expect(
      ProjectLifecycle.canMarkComplete(ProjectLifecycle.supplierSelected),
      isTrue,
    );
    expect(
      ProjectLifecycle.canMarkComplete(ProjectLifecycle.completed),
      isFalse,
    );
  });
}
