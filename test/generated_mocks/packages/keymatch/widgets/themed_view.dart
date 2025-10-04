import 'package:flutter/material.dart';

class ThemedView extends StatelessWidget {
  final Color? color;
  final Widget? child;

  const ThemedView({
    this.color,
    this.child,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = color ?? Theme.of(context).colorScheme.background;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
      ),
      child: child,
    );
  }
}
