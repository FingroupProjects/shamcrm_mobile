import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Preserves the intended PIN layout and scales the whole composition down
/// only when the available screen height is too small.
class AdaptivePinContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const AdaptivePinContent({
    super.key,
    required this.child,
    this.maxWidth = 390,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.min(constraints.maxWidth, maxWidth);

        return Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: SizedBox(width: width, child: child),
          ),
        );
      },
    );
  }
}

/// Four-row keypad with a stable height that does not grow on wider phones.
class AdaptivePinKeypad extends StatelessWidget {
  final List<Widget> children;
  final double rowExtent;
  final double rowSpacing;

  const AdaptivePinKeypad({
    super.key,
    required this.children,
    this.rowExtent = 92,
    this.rowSpacing = 4,
  }) : assert(children.length <= 12);

  @override
  Widget build(BuildContext context) {
    final rowCount = (children.length / 3).ceil();
    final height =
        rowCount * rowExtent + math.max(0, rowCount - 1) * rowSpacing;

    return SizedBox(
      height: height,
      child: GridView.count(
        padding: EdgeInsets.zero,
        primary: false,
        crossAxisCount: 3,
        mainAxisExtent: rowExtent,
        mainAxisSpacing: rowSpacing,
        physics: const NeverScrollableScrollPhysics(),
        children: children,
      ),
    );
  }
}
