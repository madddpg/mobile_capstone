import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:iconstruct/features/auth/presentation/models/ranked_shop.dart';

class ShopRankingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static List<RankedShop>? _cache;
  static DateTime? _cachedAt;
  static const Duration _ttl = Duration(minutes: 5);

  /// Clears the in-memory ranking cache (e.g. after pull-to-refresh).
  static void clearCache() {
    _cache = null;
    _cachedAt = null;
  }

  Future<List<RankedShop>> fetchRankedShops({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _cache != null &&
        _cachedAt != null &&
        now.difference(_cachedAt!) < _ttl) {
      return _cache!;
    }

    try {
      // 1. Fetch all approved and active shops
      final shopsQuery = await _firestore
          .collection('shops')
          .where('status', isEqualTo: 'approved')
          .where('subscriptionStatus', isEqualTo: 'active')
          .get();

      debugPrint('ShopRankingService: Fetched ${shopsQuery.docs.length} shops');

      if (shopsQuery.docs.isEmpty) {
        _cache = const [];
        _cachedAt = now;
        return _cache!;
      }

      // 2. Fetch all quotations using collectionGroup
      // TODO: denormalize quotationCount onto shop docs so home never
      // needs a full collectionGroup scan as the catalog grows.
      final quotationsQuery = await _firestore
          .collectionGroup('quotations')
          .get();

      debugPrint(
        'ShopRankingService: Fetched ${quotationsQuery.docs.length} quotations',
      );

      // 3. Count how many quotations each shop submitted using quotation.shopId
      final Map<String, int> quotationCounts = {};
      for (var doc in quotationsQuery.docs) {
        final data = doc.data();
        final shopId = data['shopId'] as String?;
        if (shopId != null) {
          quotationCounts[shopId] = (quotationCounts[shopId] ?? 0) + 1;
        }
      }

      // 4. Map shops into RankedShop matching quotation shopId to shops uid
      List<RankedShop> rankedShops = shopsQuery.docs.map((doc) {
        final data = doc.data();
        final uid = data['uid'] as String? ?? doc.id;
        final count = quotationCounts[uid] ?? 0;

        return RankedShop(
          uid: uid,
          shopName: data['shopName'] ?? 'Unknown Shop',
          address: data['address'] ?? '',
          barangay: data['barangay'] ?? '',
          city: data['city'] ?? '',
          subscriptionPlan: data['subscriptionPlan'],
          quotationCount: count,
        );
      }).toList();

      // 5. Sort shops by quotation count descending
      rankedShops.sort((a, b) => b.quotationCount.compareTo(a.quotationCount));

      _cache = rankedShops;
      _cachedAt = now;
      return rankedShops;
    } catch (e) {
      debugPrint('ShopRankingService Error: $e');
      return _cache ?? [];
    }
  }
}
