import 'package:flutter/material.dart';

import 'package:flutter_meedu/ui.dart';
import 'package:flutter_video_player/flutter_video_player.dart';
import 'package:flutter_video_player/src/helpers/responsive.dart';

import 'player_button.dart';

class MuteSoundButton extends StatelessWidget {
  const MuteSoundButton({required this.responsive, super.key});

  final Responsive responsive;

  @override
  Widget build(BuildContext context) {
    final controller = FlutterVideoPlayerController.of(context);
    return RxBuilder((__) {
      String iconPath = 'assets/icons/mute.png';
      Widget? customIcon = controller.customIcons.mute;

      if (!controller.mute.value) {
        iconPath = 'assets/icons/sound.png';
        customIcon = controller.customIcons.sound;
      }

      return PlayerButton(
        size: responsive.ip(controller.fullscreen.value ? 5 : 7),
        circle: false,
        backgrounColor: Colors.transparent,
        iconColor: Colors.white,
        iconPath: iconPath,
        customIcon: customIcon,
        onPressed: () {
          controller.setMute(!controller.mute.value);
        },
      );
    });
  }
}
