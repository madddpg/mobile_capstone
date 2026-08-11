import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:iconstruct/features/auth/presentation/models/ranked_shop.dart';
import 'package:iconstruct/features/auth/presentation/services/shop_ranking.dart';

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
      // Approved shops only. Do not require subscriptionStatus == active in the
      // query — documents missing that field would never match, emptying Top
      // Shops even though those shops still receive new-post notifications.
      final shopsQuery = await _firestore
          .collection('shops')
          .where('status', isEqualTo: 'approved')
          .get();

      debugPrint('ShopRankingService: Fetched ${shopsQuery.docs.length} shops');

      final rankedShops = ShopRanking.fromShopDocs(
        shopsQuery.docs.map((doc) => MapEntry(doc.id, doc.data())),
      );

      _cache = rankedShops;
      _cachedAt = now;
      return rankedShops;
    } catch (e) {
      debugPrint('ShopRankingService Error: $e');
      return _cache ?? [];
    }
  }
}
