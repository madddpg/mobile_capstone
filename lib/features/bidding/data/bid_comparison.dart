/// Rules-based comparison of private shop quotations for a builder.
///
/// Catalog list prices stay out of this — we only rank the quotes each shop
/// submitted for the builder's posted estimate.
class BidQuote {
  final String id;
  final String shopName;
  final double estimatedTotal;
  final double deliveryFee;
  final String leadTimeRaw;
  final int materialsCovered;
  final String message;

  const BidQuote({
    required this.id,
    required this.shopName,
    required this.estimatedTotal,
    required this.deliveryFee,
    required this.leadTimeRaw,
    required this.materialsCovered,
    this.message = '',
  });

  /// Total the builder is likely comparing: quote + delivery.
  double get allInTotal => estimatedTotal + deliveryFee;

  /// Rough day count parsed from free-text lead times ("3 days", "1 week").
  int? get leadTimeDays => parseLeadTimeDays(leadTimeRaw);

  factory BidQuote.fromMap(String id, Map<String, dynamic> data) {
    return BidQuote(
      id: id,
      shopName: (data['shopName'] ?? 'Unknown Shop').toString(),
      estimatedTotal: _asDouble(data['estimatedTotal']),
      deliveryFee: _asDouble(data['deliveryFee']),
      leadTimeRaw: (data['estimatedLeadTime'] ?? '').toString(),
      materialsCovered: _materialsCount(data['availableMaterials']),
      message: (data['message'] ?? '').toString(),
    );
  }

  static double _asDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static int _materialsCount(dynamic raw) {
    if (raw is List) return raw.length;
    return 0;
  }

  static int? parseLeadTimeDays(String raw) {
    final text = raw.trim().toLowerCase();
    if (text.isEmpty) return null;

    final number = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(text);
    if (number == null) return null;
    final value = double.tryParse(number.group(1)!);
    if (value == null) return null;

    if (text.contains('week')) return (value * 7).round();
    if (text.contains('month')) return (value * 30).round();
    if (text.contains('hour')) return 1;
    // Default: treat as days.
    return value.round().clamp(1, 365);
  }
}

enum BidHighlight { lowestTotal, fastestLead, mostComplete }

class BidComparison {
  final List<BidQuote> quotes;
  final String? lowestTotalId;
  final String? fastestLeadId;
  final String? mostCompleteId;

  const BidComparison({
    required this.quotes,
    this.lowestTotalId,
    this.fastestLeadId,
    this.mostCompleteId,
  });

  factory BidComparison.fromQuotes(List<BidQuote> quotes) {
    if (quotes.isEmpty) {
      return const BidComparison(quotes: []);
    }

    BidQuote? lowest;
    BidQuote? fastest;
    BidQuote? fullest;

    for (final q in quotes) {
      if (lowest == null || q.allInTotal < lowest.allInTotal) {
        lowest = q;
      } else if (q.allInTotal == lowest.allInTotal &&
          q.materialsCovered > lowest.materialsCovered) {
        lowest = q;
      }

      final days = q.leadTimeDays;
      final bestDays = fastest?.leadTimeDays;
      if (days != null) {
        if (bestDays == null || days < bestDays) {
          fastest = q;
        } else if (days == bestDays && q.allInTotal < (fastest?.allInTotal ?? 0)) {
          fastest = q;
        }
      }

      if (fullest == null || q.materialsCovered > fullest.materialsCovered) {
        fullest = q;
      } else if (q.materialsCovered == fullest.materialsCovered &&
          q.allInTotal < fullest.allInTotal) {
        fullest = q;
      }
    }

    return BidComparison(
      quotes: List.unmodifiable(quotes),
      lowestTotalId: lowest?.id,
      fastestLeadId: fastest?.id,
      mostCompleteId: fullest != null && fullest.materialsCovered > 0
          ? fullest.id
          : null,
    );
  }

  Set<BidHighlight> highlightsFor(String quoteId) {
    final tags = <BidHighlight>{};
    if (quoteId == lowestTotalId) tags.add(BidHighlight.lowestTotal);
    if (quoteId == fastestLeadId) tags.add(BidHighlight.fastestLead);
    if (quoteId == mostCompleteId) tags.add(BidHighlight.mostComplete);
    return tags;
  }

  /// Short plain-English summary for the top of the quotations screen.
  List<String> summaryLines() {
    if (quotes.isEmpty) return const [];
    if (quotes.length == 1) {
      return [
        '${quotes.first.shopName} submitted the only quotation so far '
        '(₱${quotes.first.allInTotal.toStringAsFixed(0)} all-in).',
      ];
    }

    final lines = <String>[
      '${quotes.length} shops quoted. Totals include delivery where provided.',
    ];

    BidQuote? byId(String? id) {
      if (id == null) return null;
      for (final q in quotes) {
        if (q.id == id) return q;
      }
      return null;
    }

    final cheap = byId(lowestTotalId);
    if (cheap != null) {
      lines.add(
        'Lowest all-in: ${cheap.shopName} at ₱${cheap.allInTotal.toStringAsFixed(0)}.',
      );
    }

    final fast = byId(fastestLeadId);
    if (fast != null && fast.leadTimeDays != null) {
      lines.add(
        'Fastest lead time: ${fast.shopName} (~${fast.leadTimeDays} day'
        '${fast.leadTimeDays == 1 ? '' : 's'}).',
      );
    }

    final full = byId(mostCompleteId);
    if (full != null) {
      lines.add(
        'Broadest material cover: ${full.shopName} '
        '(${full.materialsCovered} listed item'
        '${full.materialsCovered == 1 ? '' : 's'}).',
      );
    }

    // Same shop winning multiple tags.
    if (cheap != null &&
        cheap.id == fastestLeadId &&
        cheap.id == mostCompleteId) {
      lines.add(
        '${cheap.shopName} currently leads on price, speed, and coverage — still review line items before accepting.',
      );
    }

    return lines;
  }
}
