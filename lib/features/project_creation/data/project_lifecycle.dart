/// Planning and canvassing lifecycle for a builder's material estimate.
///
/// "Completed" means the planning/canvassing cycle is done — materials are
/// planned and a supplier has been selected. It does not describe on-site work.
library;

class ProjectLifecycle {
  ProjectLifecycle._();

  static const String draft = 'draft';
  static const String planning = 'planning';
  static const String waitingForQuotations = 'waiting for quotations';
  static const String receivingQuotations = 'receiving quotations';
  static const String supplierSelected = 'supplier selected';
  static const String completed = 'completed';

  static const int stageDraft = 0;
  static const int stagePlanning = 1;
  static const int stageWaiting = 2;
  static const int stageReceiving = 3;
  static const int stageSupplierSelected = 4;
  static const int stageCompleted = 5;

  /// Canonical status per stage index.
  static const List<String> statuses = [
    draft,
    planning,
    waitingForQuotations,
    receivingQuotations,
    supplierSelected,
    completed,
  ];

  /// Labels shown on cards and chips.
  static const List<String> stageLabels = [
    'Draft',
    'Planning',
    'Waiting for Quotations',
    'Receiving Quotations',
    'Supplier Selected',
    'Completed',
  ];

  /// Compact labels for the timeline.
  static const List<String> shortLabels = [
    'Draft',
    'Plan',
    'Wait',
    'Quotes',
    'Select',
    'Done',
  ];

  /// Maps a stored status (including legacy values) to a stage index.
  static int stageIndex(String status) {
    switch (status.toLowerCase().trim()) {
      case draft:
      case '':
        return stageDraft;
      case planning:
      case 'ready':
        return stagePlanning;
      case 'posted':
      case 'open':
      case waitingForQuotations:
        return stageWaiting;
      case 'has_quotations':
      case receivingQuotations:
        return stageReceiving;
      case 'offer_accepted':
      case 'awarded':
      case supplierSelected:
        return stageSupplierSelected;
      case completed:
        return stageCompleted;
      default:
        return stageDraft;
    }
  }

  static String label(String status) => stageLabels[stageIndex(status)];

  static String statusForStage(int stage) =>
      statuses[stage.clamp(0, statuses.length - 1)];

  /// Stage implied by a `projectPosts` document.
  ///
  /// A post always means quotations were requested, so the floor is
  /// [stageWaiting]; bids move it to [stageReceiving] and an accepted offer to
  /// [stageSupplierSelected].
  static int stageFromPost(Map<String, dynamic>? post) {
    if (post == null) return stageWaiting;

    if (post['selectedQuotationId'] != null) return stageSupplierSelected;

    final postStage = stageIndex((post['status'] ?? '').toString());
    if (postStage >= stageSupplierSelected) return stageSupplierSelected;

    final rawCount = post['quotationCount'];
    final count = rawCount is num
        ? rawCount.toInt()
        : int.tryParse('${rawCount ?? 0}') ?? 0;
    if (count > 0 || postStage == stageReceiving) return stageReceiving;

    return stageWaiting;
  }

  /// Whether a builder may mark the planning cycle complete.
  static bool canMarkComplete(String status) {
    final stage = stageIndex(status);
    return stage >= stageSupplierSelected && stage != stageCompleted;
  }
}
