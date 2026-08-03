import 'package:flutter/material.dart';

/// Geometry tokens for iConstruct's signature offset panel.
///
/// Insets scale with the screen so the same shell fits compact phones without
/// the oversized mockup gutters that used to clip content or leave side gaps.
class IConstructPanel {
  const IConstructPanel._();

  static const Color navy = Color(0xFF1E3042);
  static const Color darkBlue = Color(0xFF2C3E50);
  static const Color cream = Color(0xFFEDE4D4);
  static const Color creamSoft = Color(0xFFE0D7C9);
  static const Color midBlue = Color(0xFF648DB6);

  /// How far the side rail sits into the cream gutter.
  static double railLeftOf(BuildContext context) {
    final left = leftInsetOf(context);
    return (left * 0.12).clamp(6.0, 8.0);
  }

  /// Cream gutter on the left of every panel. Wide enough for the filter rail.
  static double leftInsetOf(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    // ~14% of width, kept large enough for the 44px filter buttons.
    return (width * 0.145).clamp(56.0, 64.0);
  }

  /// Height of the cream header controls band (below the status bar).
  static double headerHeightOf(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return (height * 0.08).clamp(68.0, 80.0);
  }

  /// Panel starts just under the cream header band.
  static double topInsetOf(BuildContext context) =>
      headerHeightOf(context) + 12;

  /// Clearance for the floating pill navigation.
  static double bottomInsetOf(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return 72 + (bottomPad > 0 ? 8 : 16);
  }

  /// Corner radius scaled down from the mockup's 60 so cards fit small screens.
  static double cornerRadiusOf(BuildContext context) {
    final side = MediaQuery.sizeOf(context).shortestSide;
    return (side * 0.11).clamp(40.0, 52.0);
  }

  static BorderRadius flushRadiusOf(BuildContext context) {
    final r = Radius.circular(cornerRadiusOf(context));
    return BorderRadius.only(
      topLeft: r,
      topRight: r,
      bottomLeft: r,
      bottomRight: Radius.zero,
    );
  }

  static BorderRadius topRadiusOf(BuildContext context) {
    final r = Radius.circular(cornerRadiusOf(context));
    return BorderRadius.only(topLeft: r, topRight: r);
  }

  /// Inner padding that keeps content readable inside the narrower panel.
  static EdgeInsets contentPaddingOf(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final left = width < 360 ? 16.0 : 18.0;
    final right = width < 360 ? 12.0 : 14.0;
    return EdgeInsets.fromLTRB(left, 22, right, 20);
  }

  /// Panel top inset including the status bar, for full-bleed stacks.
  static double panelTopOf(BuildContext context) =>
      MediaQuery.paddingOf(context).top + topInsetOf(context);

  /// Width available to a side rail sitting in the cream gutter.
  static double railWidthOf(BuildContext context) =>
      leftInsetOf(context) - railLeftOf(context) - 6;

  // ---------------------------------------------------------------------------
  // Legacy fixed aliases — prefer the *Of(context) helpers above.
  // Kept so older call sites compile while screens migrate to the shell.
  // ---------------------------------------------------------------------------
  static const double leftInset = 60;
  static const double topInset = 92;
  static const double bottomInset = 80;
  static const double railLeft = 8;
  static const double headerHeight = 80;

  static const BorderRadius radius = BorderRadius.only(
    topLeft: Radius.circular(48),
    topRight: Radius.circular(48),
    bottomLeft: Radius.circular(48),
  );

  static const BorderRadius flushRadius = BorderRadius.only(
    topLeft: Radius.circular(48),
    topRight: Radius.circular(48),
    bottomLeft: Radius.circular(48),
    bottomRight: Radius.zero,
  );

  static const BorderRadius topRadius = BorderRadius.only(
    topLeft: Radius.circular(48),
    topRight: Radius.circular(48),
  );

  static const EdgeInsets contentPadding = EdgeInsets.fromLTRB(18, 22, 14, 20);

  static double panelTop(BuildContext context) => panelTopOf(context);
}

/// Full-bleed cream layer the offset panel sits on.
///
/// Right edge is deliberately sharp so a rounded blob never leaves a strip of
/// gradient showing beside the navy panel.
class CreamBackdrop extends StatelessWidget {
  const CreamBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    final blobHeight = (height * 0.55).clamp(420.0, 520.0);
    final radius = IConstructPanel.cornerRadiusOf(context);

    return Positioned(
      left: 0,
      right: 0,
      top: -height * 0.18,
      height: blobHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: IConstructPanel.cream,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(radius),
            bottomLeft: Radius.circular(radius),
          ),
        ),
      ),
    );
  }
}

/// Cream header band that always paints edge-to-edge, including under the
/// status bar, so the rounded top-right of the navy panel never reveals a gap.
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

/// Wraps offset-panel screens so the stack can paint to the physical left/right
/// edges. Vertical safe padding is still applied; horizontal SafeArea is what
/// was leaving the gray side strip beside the navy panel.
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
      // Top is handled by [CreamHeaderBand] so the cream reaches the status bar.
      top: false,
      child: child,
    );
  }
}
