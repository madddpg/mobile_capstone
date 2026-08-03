import 'package:flutter/material.dart';

/// Geometry tokens for iConstruct's home-style centered panel.
///
/// Matches the main home card: equal side margins, fully rounded navy sheet,
/// cream top band — scaled slightly smaller so it fits compact phones.
class IConstructPanel {
  const IConstructPanel._();

  static const Color navy = Color(0xFF1E3042);
  static const Color darkBlue = Color(0xFF2C3E50);
  static const Color cream = Color(0xFFEDE4D4);
  static const Color creamSoft = Color(0xFFE0D7C9);
  static const Color midBlue = Color(0xFF648DB6);

  /// Equal left/right margin around the centered navy card (home uses ~30).
  static double horizontalMarginOf(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return (width * 0.06).clamp(18.0, 28.0);
  }

  /// Max card width, aligned with the home main card (330) but a bit smaller.
  static double maxPanelWidthOf(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final available = width - (horizontalMarginOf(context) * 2);
    return available.clamp(0.0, 320.0);
  }

  /// Height of the cream header controls band (below the status bar).
  static double headerHeightOf(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return (height * 0.08).clamp(64.0, 76.0);
  }

  /// Space below the header before the navy card starts.
  static double topInsetOf(BuildContext context) =>
      headerHeightOf(context) + 8;

  /// Clearance for the floating pill navigation.
  static double bottomInsetOf(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return 68 + (bottomPad > 0 ? 8 : 14);
  }

  /// Fully rounded corners like the home `_MainCard` (50 → slightly smaller).
  static double cornerRadiusOf(BuildContext context) {
    final side = MediaQuery.sizeOf(context).shortestSide;
    return (side * 0.10).clamp(36.0, 46.0);
  }

  static BorderRadius cardRadiusOf(BuildContext context) =>
      BorderRadius.circular(cornerRadiusOf(context));

  /// Top-only rounding when a card is meant to feel anchored downward.
  static BorderRadius topRadiusOf(BuildContext context) {
    final r = Radius.circular(cornerRadiusOf(context));
    return BorderRadius.only(topLeft: r, topRight: r);
  }

  static EdgeInsets contentPaddingOf(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final h = width < 360 ? 16.0 : 20.0;
    final v = width < 360 ? 20.0 : 24.0;
    return EdgeInsets.fromLTRB(h, v, h, v);
  }

  /// Panel top inset including the status bar.
  static double panelTopOf(BuildContext context) =>
      MediaQuery.paddingOf(context).top + topInsetOf(context);

  // ---------------------------------------------------------------------------
  // Legacy aliases (older call sites / gradual migration).
  // ---------------------------------------------------------------------------
  static const double leftInset = 24;
  static const double topInset = 84;
  static const double bottomInset = 80;
  static const double railLeft = 8;
  static const double headerHeight = 72;

  static const BorderRadius radius = BorderRadius.all(Radius.circular(42));
  static const BorderRadius flushRadius = BorderRadius.all(Radius.circular(42));
  static const BorderRadius topRadius = BorderRadius.only(
    topLeft: Radius.circular(42),
    topRight: Radius.circular(42),
  );
  static const EdgeInsets contentPadding = EdgeInsets.fromLTRB(20, 24, 20, 20);

  static double leftInsetOf(BuildContext context) =>
      horizontalMarginOf(context);

  static BorderRadius flushRadiusOf(BuildContext context) =>
      cardRadiusOf(context);

  static double panelTop(BuildContext context) => panelTopOf(context);
}

/// Home-style cream top blob the centered navy card sits on.
class CreamBackdrop extends StatelessWidget {
  const CreamBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    final blobHeight = (height * 0.42).clamp(300.0, 380.0);
    final radius = IConstructPanel.cornerRadiusOf(context);

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
            bottomRight: Radius.circular(radius),
          ),
        ),
      ),
    );
  }
}

/// Cream header band under the status bar for avatar / back controls.
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
      child: ColoredBox(
        color: IConstructPanel.cream,
        child: Padding(
          padding: EdgeInsets.only(top: topPad),
          child: SizedBox(
            height: headerHeight,
            width: double.infinity,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Lets the stack paint edge-to-edge horizontally (no gray SafeArea strips).
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
