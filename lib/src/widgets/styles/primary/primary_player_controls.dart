import 'package:flutter/material.dart';
import 'package:flutter_meedu/ui.dart';
import 'package:flutter_video_player/flutter_video_player.dart';
import 'package:flutter_video_player/src/helpers/responsive.dart';
import 'package:flutter_video_player/src/widgets/play_pause_button.dart';
import 'package:flutter_video_player/src/widgets/player_button.dart';
import 'package:flutter_video_player/src/widgets/styles/controls_container.dart';
import 'package:flutter_video_player/src/widgets/styles/primary/bottom_controls.dart';

class PrimaryVideoPlayerControls extends StatelessWidget {
  final Responsive responsive;

  const PrimaryVideoPlayerControls({required this.responsive, super.key});

  @override
  Widget build(BuildContext context) {
    final controller = FlutterVideoPlayerController.of(context);

    return ControlsContainer(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // RENDER A CUSTOM HEADER
          if (controller.header != null)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: controller.header!,
              ),
            ),
          SizedBox(
            height: context.mediaQuerySize.height,
            width: context.mediaQuerySize.width,
          ),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (controller.enabledButtons.rewindAndfastForward) ...[
                PlayerButton(
                  onPressed: controller.rewind,
                  size: responsive.ip(controller.fullscreen.value ? 8 : 12),
                  iconColor: Colors.white,
                  backgrounColor: Colors.transparent,
                  iconPath: 'assets/icons/rewind.png',
                  customIcon: controller.customIcons.rewind,
                ),
                const SizedBox(width: 10),
              ],
              if (controller.enabledButtons.playPauseAndRepeat)
                RxBuilder(
                    //observables: [_.showSwipeDuration],
                    //observables: [_.swipeDuration],
                    (__) {
                  controller.dataStatus.status.value;
                  if (!controller.showSwipeDuration.value &&
                      !controller.dataStatus.error &&
                      !controller.dataStatus.loading &&
                      !controller.isBuffering.value) {
                    return PlayPauseButton(
                      size: responsive.ip(controller.fullscreen.value ? 8 : 13),
                    );
                  } else {
                    return const SizedBox();
                  }
                }),
              if (controller.enabledButtons.rewindAndfastForward) ...[
                const SizedBox(width: 10),
                PlayerButton(
                  onPressed: controller.fastForward,
                  iconColor: Colors.white,
                  backgrounColor: Colors.transparent,
                  size: responsive.ip(controller.fullscreen.value ? 8 : 12),
                  iconPath: 'assets/icons/fast-forward.png',
                  customIcon: controller.customIcons.fastForward,
                ),
              ]
            ],
          ),

          PrimaryBottomControls(responsive: responsive),
        ],
      ),
    );
  }
}
