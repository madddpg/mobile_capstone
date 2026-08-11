import 'package:flutter_test/flutter_test.dart';
import 'package:iconstruct/features/auth/presentation/services/shop_ranking.dart';

void main() {
  group('ShopRanking.isEligibleShop', () {
    test('includes approved shops with no subscriptionStatus', () {
      expect(
        ShopRanking.isEligibleShop({'status': 'approved'}),
        isTrue,
      );
    });

    test('includes approved shops marked active', () {
      expect(
        ShopRanking.isEligibleShop({
          'status': 'approved',
          'subscriptionStatus': 'active',
        }),
        isTrue,
      );
    });

    test('excludes pending shops', () {
      expect(
        ShopRanking.isEligibleShop({'status': 'pending'}),
        isFalse,
      );
    });

    test('excludes cancelled subscriptions', () {
      expect(
        ShopRanking.isEligibleShop({
          'status': 'approved',
          'subscriptionStatus': 'cancelled',
        }),
        isFalse,
      );
    });
  });

  group('ShopRanking.fromShopDocs', () {
    test('ranks by denormalized quotationCount then name', () {
      final ranked = ShopRanking.fromShopDocs([
        MapEntry('a', {
          'status': 'approved',
          'shopName': 'Zulu Hardware',
          'quotationCount': 1,
        }),
        MapEntry('b', {
          'status': 'approved',
          'shopName': 'Alpha Supply',
          'quotationCount': 5,
        }),
        MapEntry('c', {
          'status': 'approved',
          'shopName': 'Beta Depot',
          'quotationCount': 5,
        }),
        MapEntry('d', {
          'status': 'pending',
          'shopName': 'Hidden',
          'quotationCount': 99,
        }),
      ]);

      expect(ranked.map((s) => s.shopName).toList(), [
        'Alpha Supply',
        'Beta Depot',
        'Zulu Hardware',
      ]);
      expect(ranked.first.quotationCount, 5);
    });

    test('treats missing quotationCount as zero', () {
      final ranked = ShopRanking.fromShopDocs([
        MapEntry('a', {
          'status': 'approved',
          'shopName': 'New Shop',
        }),
      ]);

      expect(ranked, hasLength(1));
      expect(ranked.single.quotationCount, 0);
    });
  });
}
