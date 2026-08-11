import 'package:iconstruct/features/auth/presentation/models/ranked_shop.dart';

/// Pure helpers for Top Hardware Shops ranking.
///
/// Kept free of Firestore so unit tests can lock the filter/sort rules that
/// previously hid every approved shop from builders.
class ShopRanking {
  ShopRanking._();

  /// Subscription values that mean the shop should stay off the public board.
  static const inactiveSubscriptionStatuses = {
    'inactive',
    'cancelled',
    'canceled',
    'expired',
    'suspended',
  };

  /// Whether an approved shop doc should appear in builder-facing rankings.
  ///
  /// Missing `subscriptionStatus` counts as eligible — that field is optional
  /// metadata and must not hide shops that Cloud Functions still notify on
  /// new project posts (`status == approved` only).
  static bool isEligibleShop(Map<String, dynamic> data) {
    final status = (data['status'] ?? '').toString().trim().toLowerCase();
    if (status != 'approved') return false;

    final rawSub = data['subscriptionStatus'];
    if (rawSub == null) return true;
    final sub = rawSub.toString().trim().toLowerCase();
    if (sub.isEmpty || sub == 'active') return true;
    return !inactiveSubscriptionStatuses.contains(sub);
  }

  static int quotationCountOf(Map<String, dynamic> data) {
    final raw = data['quotationCount'];
    if (raw is num) return raw.toInt().clamp(0, 1 << 30);
    return int.tryParse('${raw ?? ''}')?.clamp(0, 1 << 30) ?? 0;
  }

  /// Builds a ranked list from approved shop documents.
  ///
  /// Counts come from the denormalized `quotationCount` field on each shop
  /// doc — builders cannot collectionGroup-scan `quotations` under the
  /// ownership rules that protect private bids.
  static List<RankedShop> fromShopDocs(
    Iterable<MapEntry<String, Map<String, dynamic>>> docs,
  ) {
    final ranked = <RankedShop>[];

    for (final entry in docs) {
      final data = entry.value;
      if (!isEligibleShop(data)) continue;

      final uid = (data['uid'] ?? entry.key).toString();
      ranked.add(
        RankedShop(
          uid: uid,
          shopName: (data['shopName'] ?? 'Unknown Shop').toString(),
          address: (data['address'] ?? '').toString(),
          barangay: (data['barangay'] ?? '').toString(),
          city: (data['city'] ?? '').toString(),
          subscriptionPlan: data['subscriptionPlan']?.toString(),
          quotationCount: quotationCountOf(data),
        ),
      );
    }

    ranked.sort((a, b) {
      final byCount = b.quotationCount.compareTo(a.quotationCount);
      if (byCount != 0) return byCount;
      return a.shopName.toLowerCase().compareTo(b.shopName.toLowerCase());
    });

    return ranked;
  }
}
