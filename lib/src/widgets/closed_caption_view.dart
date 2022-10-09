import 'package:flutter/material.dart';
import 'package:flutter_meedu/ui.dart';
import 'package:flutter_video_player/flutter_video_player.dart';
import 'package:flutter_video_player/src/helpers/responsive.dart';

class ClosedCaptionView extends StatelessWidget {
  final Responsive responsive;

  const ClosedCaptionView({required this.responsive, super.key});

  @override
  Widget build(BuildContext context) {
    final _ = FlutterVideoPlayerController.of(context);
    return RxBuilder((__) {
      if (!_.closedCaptionEnabled.value) return const SizedBox();

      return StreamBuilder<Duration>(
        initialData: Duration.zero,
        stream: _.onPositionChanged,
        builder: (__, snapshot) {
          if (snapshot.hasError) {
            return const SizedBox();
          }

          final strSubtitle = _.videoPlayerController!.value.caption.text;

          return Positioned(
            left: 60,
            right: 60,
            bottom: 0,
            child: ClosedCaption(
              text: strSubtitle,
              textStyle: TextStyle(
                color: Colors.white,
                fontSize: responsive.ip(2),
              ),
            ),
          );
        },
      );
    });
  }
}
