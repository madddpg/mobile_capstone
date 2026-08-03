import 'package:flutter/material.dart';

/// Geometry for iConstruct's signature **offset panel**.
///
/// Inspired by the posted-project details card: navy sheet shifted right with a
/// cream gutter on the left, rounded on the left only, flush to the right edge.
class IConstructPanel {
  const IConstructPanel._();

  static const Color navy = Color(0xFF1E3042);
  static const Color darkBlue = Color(0xFF2C3E50);
  static const Color cream = Color(0xFFEDE4D4);
  static const Color creamSoft = Color(0xFFE0D7C9);
  static const Color midBlue = Color(0xFF648DB6);

  /// Left cream gutter — matches posted-details `left: 60`.
  static double leftInsetOf(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return (width * 0.155).clamp(52.0, 64.0);
  }

  /// How far a side rail sits into the cream gutter.
  static double railLeftOf(BuildContext context) =>
      (leftInsetOf(context) * 0.12).clamp(6.0, 8.0);

  static double railWidthOf(BuildContext context) =>
      leftInsetOf(context) - railLeftOf(context) - 6;

  /// Cream header controls band (below the status bar).
  static double headerHeightOf(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return (height * 0.09).clamp(72.0, 88.0);
  }

  /// Space under the header before the offset panel (posted-details uses ~90).
  static double topInsetOf(BuildContext context) =>
      headerHeightOf(context) + 12;

  /// Clearance for the floating pill navigation.
  static double bottomInsetOf(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return 72 + (bottomPad > 0 ? 8 : 16);
  }

  /// Left-side rounding used by the offset card (~55 in the reference).
  static double cornerRadiusOf(BuildContext context) {
    final side = MediaQuery.sizeOf(context).shortestSide;
    return (side * 0.13).clamp(44.0, 56.0);
  }

  /// Flush-right offset card: rounded on the left only.
  static BorderRadius offsetRadiusOf(BuildContext context) {
    final r = Radius.circular(cornerRadiusOf(context));
    return BorderRadius.only(
      topLeft: r,
      bottomLeft: r,
    );
  }

  /// Tall panels that also need a soft top-right when they sit under a header.
  static BorderRadius offsetTallRadiusOf(BuildContext context) {
    final r = Radius.circular(cornerRadiusOf(context));
    return BorderRadius.only(
      topLeft: r,
      topRight: r,
      bottomLeft: r,
    );
  }

  static EdgeInsets contentPaddingOf(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final left = width < 360 ? 20.0 : 24.0;
    final right = width < 360 ? 16.0 : 20.0;
    return EdgeInsets.fromLTRB(left, 28, right, 24);
  }

  static double panelTopOf(BuildContext context) =>
      MediaQuery.paddingOf(context).top + topInsetOf(context);

  // ---------------------------------------------------------------------------
  // Legacy aliases
  // ---------------------------------------------------------------------------
  static const double leftInset = 60;
  static const double topInset = 90;
  static const double bottomInset = 80;
  static const double railLeft = 8;
  static const double headerHeight = 80;

  static const BorderRadius radius = BorderRadius.only(
    topLeft: Radius.circular(55),
    bottomLeft: Radius.circular(55),
  );
  static const BorderRadius flushRadius = BorderRadius.only(
    topLeft: Radius.circular(55),
    bottomLeft: Radius.circular(55),
  );
  static const BorderRadius topRadius = BorderRadius.only(
    topLeft: Radius.circular(55),
    topRight: Radius.circular(55),
  );
  static const EdgeInsets contentPadding = EdgeInsets.fromLTRB(24, 28, 20, 24);

  static BorderRadius cardRadiusOf(BuildContext context) =>
      offsetRadiusOf(context);

  static BorderRadius flushRadiusOf(BuildContext context) =>
      offsetRadiusOf(context);

  static BorderRadius topRadiusOf(BuildContext context) {
    final r = Radius.circular(cornerRadiusOf(context));
    return BorderRadius.only(topLeft: r, topRight: r);
  }

  static double horizontalMarginOf(BuildContext context) =>
      leftInsetOf(context);

  static double maxPanelWidthOf(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static double panelTop(BuildContext context) => panelTopOf(context);
}

/// Cream top shape from the offset-panel reference: soft curve on the
/// bottom-left only, so the navy card can tuck against the right edge.
class CreamBackdrop extends StatelessWidget {
  const CreamBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    final blobHeight = height * 0.45;
    final radius = IConstructPanel.cornerRadiusOf(context) + 4;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: blobHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: IConstructPanel.cream,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(radius),
          ),
        ),
      ),
    );
  }
}

/// Cream header band for back / avatar controls over the cream blob.
class CreamHeaderBand extends StatelessWidget {
  final Widget child;

  const CreamHeaderBand({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final headerHeight = IConstructPanel.headerHeightOf(context);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: topPad + headerHeight,
      child: Padding(
        padding: EdgeInsets.only(top: topPad),
        child: SizedBox(
          height: headerHeight,
          width: double.infinity,
          child: child,
        ),
      ),
    );
  }
}

/// Edge-to-edge horizontally so the flush-right panel never shows a side gap.
class OffsetSafeArea extends StatelessWidget {
  final Widget child;
  final bool bottom;

  const OffsetSafeArea({
    super.key,
    required this.child,
    this.bottom = true,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      left: false,
      right: false,
      bottom: bottom,
      top: false,
      child: child,
    );
  }
}
