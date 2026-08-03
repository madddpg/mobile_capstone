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
}

/// The cream blob the offset panel overlaps.
///
/// Spans the full width of whatever screen it lands on — pinning it to a fixed
/// width leaves a bare strip on the right of wider phones.
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
          borderRadius: BorderRadius.all(Radius.circular(50)),
        ),
      ),
    );
  }
}
