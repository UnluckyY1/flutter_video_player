import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PlayerButton extends StatelessWidget {
  final double size;
  final String iconPath;
  final VoidCallback onPressed;
  final Color backgrounColor, iconColor;
  final bool circle;
  final Widget? customIcon;

  const PlayerButton({
    Key? key,
    this.size = 40,
    required this.iconPath,
    required this.onPressed,
    this.circle = true,
    this.backgrounColor = Colors.white54,
    this.iconColor = Colors.black,
    this.customIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minSize: 20,
      onPressed: onPressed,
      child: customIcon ??
          Container(
            width: size,
            height: size,
            padding: EdgeInsets.all(size * 0.25),
            decoration: BoxDecoration(
              color: backgrounColor,
              shape: circle ? BoxShape.circle : BoxShape.rectangle,
            ),
            child: Image.asset(
              iconPath,
              color: iconColor,
              package: 'flutter_video_player',
            ),
          ),
    );
  }
}
