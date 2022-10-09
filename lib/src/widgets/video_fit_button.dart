import 'package:flutter/material.dart';
import 'package:flutter_meedu/ui.dart';
import 'package:flutter_video_player/flutter_video_player.dart';
import 'package:flutter_video_player/src/helpers/responsive.dart';
import 'player_button.dart';

class VideoFitButton extends StatelessWidget {
  final Responsive responsive;
  const VideoFitButton({required this.responsive, super.key});

  @override
  Widget build(BuildContext context) {
    final controller = FlutterVideoPlayerController.of(context);
    return RxBuilder((__) {
      String iconPath = 'assets/icons/fit.png';
      Widget? customIcon = controller.customIcons.videoFit;

      return PlayerButton(
        size: responsive.ip(controller.fullscreen.value ? 5 : 7),
        circle: false,
        backgrounColor: Colors.transparent,
        iconColor: Colors.white,
        iconPath: iconPath,
        customIcon: customIcon,
        onPressed: () {
          controller.toggleVideoFit();
        },
      );
    });
  }
}
