import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:iconstruct/features/auth/presentation/models/ranked_shop.dart';

class ShopRankingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<RankedShop>> fetchRankedShops() async {
    try {
      // 1. Fetch all approved and active shops
      final shopsQuery = await _firestore
          .collection('shops')
          .where('status', isEqualTo: 'approved')
          .where('subscriptionStatus', isEqualTo: 'active')
          .get();

      debugPrint('ShopRankingService: Fetched ${shopsQuery.docs.length} shops');

      if (shopsQuery.docs.isEmpty) {
        return [];
      }

      // 2. Fetch all quotations using collectionGroup
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

        debugPrint(
          'ShopRankingService: Shop "${data['shopName']}" | Quotations: $count',
        );

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

      // 8. If a shop has 0 quotations, still show it after ranked shops (already handled by natural int sorting)

      return rankedShops;
    } catch (e) {
      debugPrint('ShopRankingService Error: $e');
      return [];
    }
  }
}
