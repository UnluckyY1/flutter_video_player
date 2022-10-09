import 'package:flutter/material.dart';
import 'package:flutter_meedu/ui.dart';
import 'package:flutter_video_player/flutter_video_player.dart';
import 'package:flutter_video_player/src/helpers/utils.dart';

class PlayerSlider extends StatelessWidget {
  const PlayerSlider({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = FlutterVideoPlayerController.of(context);
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        LayoutBuilder(builder: (ctx, constraints) {
          return RxBuilder(
            //observables: [_.buffered, _.duration],
            (__) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                color: Colors.white30,
                width: constraints.maxWidth * controller.bufferedPercent.value,
                height: 3,
              );
            },
          );
        }),
        RxBuilder(
          //observables: [_.sliderPosition, _.duration],
          (__) {
            final int value = controller.sliderPosition.value.inSeconds;
            final double max = controller.duration.value.inSeconds.toDouble();
            if (value > max || max <= 0) {
              return Container();
            }
            return Container(
              constraints: const BoxConstraints(
                maxHeight: 30,
              ),
              padding: const EdgeInsets.only(bottom: 8),
              alignment: Alignment.center,
              child: SliderTheme(
                data: SliderThemeData(
                  trackShape: _MSliderTrackShape(),
                  thumbColor: controller.colorTheme,
                  activeTrackColor: controller.colorTheme,
                  trackHeight: 10,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 4.0),
                ),
                child: Slider(
                  min: 0,
                  divisions: controller.duration.value.inSeconds,
                  value: value.toDouble(),
                  onChangeStart: (v) {
                    controller.onChangedSliderStart();
                  },
                  onChangeEnd: (v) {
                    controller.onChangedSliderEnd();
                    controller.seekTo(
                      Duration(seconds: v.floor()),
                    );
                  },
                  label: printDuration(controller.sliderPosition.value),
                  max: max,
                  onChanged: controller.onChangedSlider,
                ),
              ),
            );
          },
        )
      ],
    );
  }
}

class _MSliderTrackShape extends RoundedRectSliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    SliderThemeData? sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    const double trackHeight = 1;
    final double trackLeft = offset.dx;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2 + 4;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}
