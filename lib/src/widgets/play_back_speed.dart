import 'package:flutter/material.dart';
import 'package:flutter_meedu/ui.dart';
import 'package:flutter_video_player/flutter_video_player.dart';
import 'package:flutter_video_player/src/helpers/responsive.dart';

class PlayBackSpeedButton extends StatelessWidget {
  const PlayBackSpeedButton({
    required this.responsive,
    required this.textStyle,
    super.key,
  });

  final Responsive responsive;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    final controller = FlutterVideoPlayerController.of(context);
    return RxBuilder((__) {
      return TextButton(
        style: TextButton.styleFrom(
          padding: EdgeInsets.all(
              responsive.ip(controller.fullscreen.value ? 5 : 7) * 0.25),
        ),
        onPressed: () {
          controller.togglePlaybackSpeed();
        },
        child: Text(
          controller.playbackSpeed.toString(),
          style: textStyle,
        ),
      );
    });
  }
}
