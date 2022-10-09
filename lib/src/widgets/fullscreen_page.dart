// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter_meedu/ui.dart';
import 'package:flutter_video_player/flutter_video_player.dart';

class VideoPlayerFullscreenPage extends StatefulWidget {
  final FlutterVideoPlayerController controller;

  const VideoPlayerFullscreenPage({Key? key, required this.controller})
      : super(key: key);

  @override
  _MeeduPlayerFullscreenPageState createState() =>
      _MeeduPlayerFullscreenPageState();
}

class _MeeduPlayerFullscreenPageState extends State<VideoPlayerFullscreenPage> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      body: RxBuilder(
        //observables: [controller.videoFit],
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
  Future<void> dispose() async {
    widget.controller.fullScreenClosed();
    super.dispose();
  }
}
