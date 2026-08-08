import 'package:flutter_test/flutter_test.dart';
import 'package:iconstruct/features/bidding/data/bid_comparison.dart';

void main() {
  group('BidQuote.parseLeadTimeDays', () {
    test('parses common lead-time phrases', () {
      expect(BidQuote.parseLeadTimeDays('3 days'), 3);
      expect(BidQuote.parseLeadTimeDays('1 week'), 7);
      expect(BidQuote.parseLeadTimeDays('2 weeks'), 14);
    });
  });

  group('BidComparison', () {
    final quotes = [
      const BidQuote(
        id: 'a',
        shopName: 'Alpha Hardware',
        estimatedTotal: 10000,
        deliveryFee: 500,
        leadTimeRaw: '5 days',
        materialsCovered: 4,
      ),
      const BidQuote(
        id: 'b',
        shopName: 'Beta Supply',
        estimatedTotal: 9500,
        deliveryFee: 0,
        leadTimeRaw: '2 weeks',
        materialsCovered: 8,
      ),
      const BidQuote(
        id: 'c',
        shopName: 'QuickBuild',
        estimatedTotal: 11000,
        deliveryFee: 200,
        leadTimeRaw: '2 days',
        materialsCovered: 5,
      ),
    ];

    test('highlights lowest all-in, fastest lead, and most complete', () {
      final comparison = BidComparison.fromQuotes(quotes);

      expect(comparison.lowestTotalId, 'b'); // 9500 all-in
      expect(comparison.fastestLeadId, 'c'); // 2 days
      expect(comparison.mostCompleteId, 'b'); // 8 materials
    });

    test('summary mentions shop count and standouts', () {
      final lines = BidComparison.fromQuotes(quotes).summaryLines();

      expect(lines.first, contains('3 shops'));
      expect(lines.any((l) => l.contains('Beta Supply')), isTrue);
      expect(lines.any((l) => l.contains('QuickBuild')), isTrue);
    });

    test('single quote gets a simple snapshot line', () {
      final lines = BidComparison.fromQuotes([quotes.first]).summaryLines();
      expect(lines, hasLength(1));
      expect(lines.first, contains('only quotation'));
    });
  });
}
