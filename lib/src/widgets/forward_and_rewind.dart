import 'package:flutter/material.dart';
import 'package:flutter_video_player/src/widgets/rewind_and_forward_layout.dart';
import 'package:flutter_video_player/src/widgets/ripple_side.dart';
import 'package:flutter_video_player/src/widgets/transitions.dart';

class VideoCoreForwardAndRewind extends StatelessWidget {
  final bool showRewind, showForward;
  final int rewindSeconds, forwardSeconds;

  const VideoCoreForwardAndRewind(
      {required this.showRewind,
      required this.showForward,
      required this.forwardSeconds,
      required this.rewindSeconds,
      super.key});

  @override
  Widget build(BuildContext context) {
    return VideoCoreForwardAndRewindLayout(
      rewind: CustomOpacityTransition(
        visible: showRewind,
        child: ForwardAndRewindRippleSide(
          text: '$rewindSeconds Sec',
          side: RippleSide.left,
        ),
      ),
      forward: CustomOpacityTransition(
        visible: showForward,
        child: ForwardAndRewindRippleSide(
          text: '$forwardSeconds Sec',
          side: RippleSide.right,
        ),
      ),
    );
  }
}
