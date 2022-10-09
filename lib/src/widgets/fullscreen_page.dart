import 'package:flutter/material.dart';
import 'package:flutter_meedu/ui.dart';
import 'package:flutter_video_player/flutter_video_player.dart';

class VideoPlayerFullscreenPage extends StatefulWidget {
  const VideoPlayerFullscreenPage({required this.controller, super.key});

  final FlutterVideoPlayerController controller;

  @override
  State<VideoPlayerFullscreenPage> createState() =>
      _VideoPlayerFullscreenPageState();
}

class _VideoPlayerFullscreenPageState extends State<VideoPlayerFullscreenPage> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      body: RxBuilder(
        (__) {
          return SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: FittedBox(
              fit: widget.controller.videoFit.value,
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: FlutterVideoPlayer(
                  controller: widget.controller,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    widget.controller.fullScreenClosed();
  }
}
