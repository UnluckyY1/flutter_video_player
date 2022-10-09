import 'package:flutter/material.dart';
import 'package:helpers/helpers/transition.dart';

class CustomOpacityTransition extends StatelessWidget {
  const CustomOpacityTransition({
    required this.visible,
    required this.child,
    super.key,
  });

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return OpacityTransition(
      curve: Curves.ease,
      duration: const Duration(milliseconds: 100),
      visible: visible,
      child: child,
    );
  }
}
