import 'package:flutter/material.dart';
import 'package:flutter_meedu/ui.dart';
import 'package:flutter_video_player/flutter_video_player.dart';
import 'package:flutter_video_player/src/helpers/responsive.dart';
import 'package:flutter_video_player/src/helpers/utils.dart';
import 'package:flutter_video_player/src/widgets/fullscreen_button.dart';
import 'package:flutter_video_player/src/widgets/mute_sound_button.dart';
import 'package:flutter_video_player/src/widgets/playa_back_speed.dart';
import 'package:flutter_video_player/src/widgets/video_fit_button.dart';



import '../../player_slider.dart';

class PrimaryBottomControls extends StatelessWidget {
  final Responsive responsive;
  const PrimaryBottomControls({Key? key, required this.responsive})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _ = FlutterVideoPlayerController.of(context);
    final fontSize = responsive.ip(2.5);
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: fontSize > 16 ? 16 : fontSize,
    );
    return Positioned(
      left: 5,
      right: 0,
      bottom: 20,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // START VIDEO POSITION
          RxBuilder(
              //observables: [_.duration, _.position],
              (__) {
            return Text(
              _.duration.value.inMinutes >= 60
                  ? printDurationWithHours(_.position.value)
                  : printDuration(_.position.value),
              style: textStyle,
            );
          }),
          // END VIDEO POSITION
          const SizedBox(width: 10),
          const Expanded(child: PlayerSlider()),
          const SizedBox(width: 10),
          // START VIDEO DURATION
          RxBuilder(
            //observables: [_.duration],
            (__) => Text(
              _.duration.value.inMinutes >= 60
                  ? printDurationWithHours(_.duration.value)
                  : printDuration(_.duration.value),
              style: textStyle,
            ),
          ),
          // END VIDEO DURATION
          const SizedBox(width: 15),
          if (_.bottomRight != null) ...[
            _.bottomRight!,
            const SizedBox(width: 5)
          ],

          //if (_.enabledButtons.pip) PipButton(responsive: responsive),

          if (_.enabledButtons.videoFit) VideoFitButton(responsive: responsive),
          if (_.enabledButtons.playBackSpeed)
            PlayBackSpeedButton(responsive: responsive, textStyle: textStyle),
          if (_.enabledButtons.muteAndSound)
            MuteSoundButton(responsive: responsive),

          if (_.enabledButtons.fullscreen)
            FullscreenButton(size: responsive.ip(_.fullscreen.value ? 5 : 7))
        ],
      ),
    );
  }
}
