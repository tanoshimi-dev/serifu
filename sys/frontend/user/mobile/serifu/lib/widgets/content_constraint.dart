import 'package:flutter/material.dart';

class ContentConstraint extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ContentConstraint({
    super.key,
    required this.child,
    this.maxWidth = 680,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
