import 'package:flutter/material.dart';

/// Geometry for iConstruct's signature **offset panel**.
///
/// Navy sheet shifted right with a cream gutter on the left, rounded on the
/// left (and top when tall), flush to the right edge — matching the
/// posted-project details / Name Estimate planning look.
class IConstructPanel {
  const IConstructPanel._();

  static const Color navy = Color(0xFF1E3042);
  static const Color darkBlue = Color(0xFF2C3E50);
  static const Color cream = Color(0xFFEDE4D4);
  static const Color creamSoft = Color(0xFFE0D7C9);
  static const Color midBlue = Color(0xFF648DB6);

  static const double pillHeight = 64;
  static const double pillBottomMargin = 12;
  static const double panelNavGap = 10;

  /// Left cream gutter. Widening this pushes the whole offset panel further
  /// right on every screen built with [OffsetPanelShell].
  static double leftInsetOf(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return (width * 0.205).clamp(70.0, 90.0);
  }

  static double railLeftOf(BuildContext context) =>
      (leftInsetOf(context) * 0.12).clamp(6.0, 8.0);

  static double railWidthOf(BuildContext context) =>
      leftInsetOf(context) - railLeftOf(context) - 6;

  static double headerHeightOf(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return (height * 0.085).clamp(70.0, 84.0);
  }

  static double topInsetOf(BuildContext context) =>
      headerHeightOf(context) + 10;

  /// Space reserved under a pinned panel so it sits just above the pill nav
  /// (no double SafeArea — that was leaving the large empty “error gap”).
  static double bottomInsetOf(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return pillHeight + pillBottomMargin + panelNavGap + bottomPad;
  }

  static double cornerRadiusOf(BuildContext context) {
    final side = MediaQuery.sizeOf(context).shortestSide;
    return (side * 0.12).clamp(40.0, 52.0);
  }

  /// Flush-right floating card: rounded left side.
  static BorderRadius offsetRadiusOf(BuildContext context) {
    final r = Radius.circular(cornerRadiusOf(context));
    return BorderRadius.only(topLeft: r, bottomLeft: r);
  }

  /// Tall fill panels (AI): rounded top + bottom-left, flush right.
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
    final left = width < 360 ? 18.0 : 22.0;
    final right = width < 360 ? 14.0 : 18.0;
    return EdgeInsets.fromLTRB(left, 24, right, 20);
  }

  static double panelTopOf(BuildContext context) =>
      MediaQuery.paddingOf(context).top + topInsetOf(context);

  // Legacy aliases
  static const double leftInset = 60;
  static const double topInset = 90;
  static const double bottomInset = 80;
  static const double railLeft = 8;
  static const double headerHeight = 80;

  static const BorderRadius radius = BorderRadius.only(
    topLeft: Radius.circular(48),
    bottomLeft: Radius.circular(48),
  );
  static const BorderRadius flushRadius = BorderRadius.only(
    topLeft: Radius.circular(48),
    bottomLeft: Radius.circular(48),
  );
  static const BorderRadius topRadius = BorderRadius.only(
    topLeft: Radius.circular(48),
    topRight: Radius.circular(48),
  );
  static const EdgeInsets contentPadding = EdgeInsets.fromLTRB(22, 24, 18, 20);

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

/// Cream top shape: curve on the bottom-left, sharp on the right so nothing
/// peeks beside a flush-right navy panel.
class CreamBackdrop extends StatelessWidget {
  const CreamBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    final blobHeight = height * 0.48;
    final radius = IConstructPanel.cornerRadiusOf(context) + 8;

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

/// Full-bleed cream under the status bar + header controls. Also covers the
/// area behind the panel’s top-right radius so no gray/gradient “error gap”
/// appears at that seam.
class CreamHeaderBand extends StatelessWidget {
  final Widget child;

  const CreamHeaderBand({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final headerHeight = IConstructPanel.headerHeightOf(context);
    final coverHeight = IConstructPanel.panelTopOf(context) +
        IConstructPanel.cornerRadiusOf(context);

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: coverHeight,
          child: const ColoredBox(color: IConstructPanel.cream),
        ),
        Positioned(
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
        ),
      ],
    );
  }
}

/// Horizontal edge-to-edge stack. Bottom padding is handled by the shell’s
/// panel/nav geometry — applying SafeArea bottom here stacked a second inset
/// and created the large empty gap above the pill nav.
class OffsetSafeArea extends StatelessWidget {
  final Widget child;
  final bool bottom;

  const OffsetSafeArea({
    super.key,
    required this.child,
    this.bottom = false,
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
