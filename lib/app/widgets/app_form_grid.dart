import 'package:flutter/material.dart';

import '../utils/responsive_utils.dart';

/// One column on phones, two on tablets. Phone wrapping is unchanged.
class AppFormGrid extends StatelessWidget {
  const AppFormGrid({
    required this.children,
    this.spacing = 12,
    this.fullWidthIndexes = const {},
    super.key,
  });

  final List<Widget> children;
  final double spacing;
  final Set<int> fullWidthIndexes;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = ResponsiveUtils.formColumns(context);
        final pairWidth = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (var index = 0; index < children.length; index++)
              SizedBox(
                width: fullWidthIndexes.contains(index)
                    ? constraints.maxWidth
                    : pairWidth,
                child: children[index],
              ),
          ],
        );
      },
    );
  }
}

/// Lays list cards in 1 / 2 / 3 columns without changing phone stacking.
class AppResponsiveCards extends StatelessWidget {
  const AppResponsiveCards({
    required this.itemCount,
    required this.itemBuilder,
    this.spacing = 8,
    super.key,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = ResponsiveUtils.gridColumns(context);
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (var index = 0; index < itemCount; index++)
              SizedBox(width: width, child: itemBuilder(context, index)),
          ],
        );
      },
    );
  }
}
