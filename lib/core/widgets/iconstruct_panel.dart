import 'package:flutter/material.dart';

/// Geometry of iConstruct's signature offset panel.
///
/// The navy sheet is pushed well off the left edge so the cream backdrop — and
/// anything that peeks out from behind it, like the filter rail — stays visible.
/// It then runs flush to the right edge with oversized corners and a squared
/// bottom-right, which is what makes the panel feel offset rather than centered.
class IConstructPanel {
  const IConstructPanel._();

  /// Cream gutter kept on the left of every panel. Wide enough for the filter
  /// rail to sit in, and for the panel to clearly read as shifted.
  static const double leftInset = 72;

  /// Panel starts just under the cream header band.
  static const double topInset = 110;

  /// Clearance for the floating pill navigation.
  static const double bottomInset = 80;

  /// How far the side rail sits into the cream gutter.
  static const double railLeft = 8;

  /// Height of the cream header controls band (below the status bar).
  static const double headerHeight = 96;

  static const Color navy = Color(0xFF1E3042);
  static const Color cream = Color(0xFFEDE4D4);
  static const Color creamSoft = Color(0xFFE0D7C9);

  /// Signature panel: oversized top corners, rounded bottom-left, flush right.
  static const BorderRadius radius = BorderRadius.only(
    topLeft: Radius.circular(60),
    topRight: Radius.circular(60),
    bottomLeft: Radius.circular(60),
  );

  /// Same as [radius] but with a squared bottom-right — the glitch cut used when
  /// the panel sits flush against the right edge of the screen.
  static const BorderRadius flushRadius = BorderRadius.only(
    topLeft: Radius.circular(60),
    topRight: Radius.circular(60),
    bottomLeft: Radius.circular(60),
    bottomRight: Radius.zero,
  );

  /// Panels that run to the bottom of the screen, like the AI chat.
  static const BorderRadius topRadius = BorderRadius.only(
    topLeft: Radius.circular(60),
    topRight: Radius.circular(60),
  );

  /// Inner padding that keeps content readable inside the narrower panel.
  static const EdgeInsets contentPadding = EdgeInsets.fromLTRB(20, 28, 14, 24);

  /// Panel top inset including the status bar, for full-bleed stacks.
  static double panelTop(BuildContext context) =>
      MediaQuery.paddingOf(context).top + topInset;
}

/// Full-bleed cream layer the offset panel sits on.
///
/// Right edge is deliberately sharp so a rounded blob never leaves a strip of
/// gradient showing beside the navy panel.
class CreamBackdrop extends StatelessWidget {
  const CreamBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return const Positioned(
      left: 0,
      right: 0,
      top: -200,
      height: 585,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: IConstructPanel.cream,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(50),
            bottomLeft: Radius.circular(50),
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

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: topPad + IConstructPanel.headerHeight,
      child: ColoredBox(
        color: IConstructPanel.cream,
        child: Padding(
          padding: EdgeInsets.only(top: topPad),
          child: SizedBox(
            height: IConstructPanel.headerHeight,
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
