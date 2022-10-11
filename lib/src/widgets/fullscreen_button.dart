import 'package:flutter/material.dart';
import 'package:flutter_meedu/ui.dart';
import 'package:flutter_video_player/flutter_video_player.dart';

import 'player_button.dart';

class FullscreenButton extends StatelessWidget {
  final double size;

  const FullscreenButton({this.size = 30, super.key});

  @override
  Widget build(BuildContext context) {
    final _ = FlutterVideoPlayerController.of(context);
    return RxBuilder(
      (__) {
        String iconPath = 'assets/icons/minimize.png';
        Widget? customIcon = _.customIcons.minimize;

        if (!_.fullscreen.value) {
          iconPath = 'assets/icons/fullscreen.png';
          customIcon = _.customIcons.fullscreen;
        }
        return PlayerButton(
          size: size,
          circle: false,
          backgrounColor: Colors.transparent,
          iconColor: Colors.white,
          iconPath: iconPath,
          customIcon: customIcon,
          onPressed: () {
            if (_.fullscreen.value) {
              Navigator.pop(context);
              if (_.isDesktop) _.screenManager.setWindowsFullScreen(false, _);
            } else {
              if (_.isDesktop) _.screenManager.setWindowsFullScreen(true, _);

              _.goToFullscreen(context);
            }
          },
        );
      },
    );
  }
}
