// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_meedu/ui.dart';
import 'package:flutter_video_player/flutter_video_player.dart';

class MeeduPlayerFullscreenPage extends StatefulWidget {
  final FlutterVideoPlayerController controller;

  const MeeduPlayerFullscreenPage({Key? key, required this.controller})
      : super(key: key);

  @override
  _MeeduPlayerFullscreenPageState createState() =>
      _MeeduPlayerFullscreenPageState();
}

class _MeeduPlayerFullscreenPageState extends State<MeeduPlayerFullscreenPage> {
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
    if (kDebugMode) print("disposed");
    widget.controller.videoPlayerClosed();
    super.dispose();
  }
}
