// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_meedu/ui.dart';
import 'package:flutter_video_player/flutter_video_player.dart';
import 'package:flutter_video_player/src/helpers/responsive.dart';
import 'package:flutter_video_player/src/widgets/styles/primary/primary_player_controls.dart';
import 'package:flutter_video_player/src/widgets/styles/secondary/secondary_player_controls.dart';

import 'closed_caption_view.dart';

class FlutterVideoPlayer extends StatefulWidget {
  final FlutterVideoPlayerController controller;

  final Widget Function(
    BuildContext context,
    FlutterVideoPlayerController controller,
    Responsive responsive,
  )? header;

  final Widget Function(
    BuildContext context,
    FlutterVideoPlayerController controller,
    Responsive responsive,
  )? bottomRight;

  final CustomIcons Function(
    Responsive responsive,
  )? customIcons;

  const FlutterVideoPlayer({
    Key? key,
    required this.controller,
    this.header,
    this.bottomRight,
    this.customIcons,
  }) : super(key: key);

  @override
  _FlutterVideoPlayerState createState() => _FlutterVideoPlayerState();
}

class _FlutterVideoPlayerState extends State<FlutterVideoPlayer> {
  @override
  Widget build(BuildContext context) {
    return FlutterVideoPlayerProvider(
      controller: widget.controller,
      child: Container(
          color: Colors.black,
          width: 0.0,
          height: 0.0,
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              FlutterVideoPlayerController _ = widget.controller;
              final responsive = Responsive(
                constraints.maxWidth,
                constraints.maxHeight,
              );

              if (widget.customIcons != null) {
                _.customIcons = widget.customIcons!(responsive);
              }

              if (widget.header != null) {
                _.header = widget.header!(context, _, responsive);
              }

              if (widget.bottomRight != null) {
                _.bottomRight = widget.bottomRight!(context, _, responsive);
              }

              return Stack(
                alignment: Alignment.center,
                children: [
                  if (_.windows)
                    RxBuilder(
                        //observables: [_.videoFit],
                        (__) {
                      //print("NATIVE HAS BEEN REBUILT ${_.videoPlayerControllerWindows}");
                      _.dataStatus.status.value;
                      if (_.videoPlayerControllerWindows == null) {
                        return const Text("Loading");
                      }

                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          /*
                          Platform.isWindows
                              ? NativeVideo(
                                  player: _.videoPlayerControllerWindows!,
                                  showControls: false,
                                )
                              : Video(
                                  player: _.videoPlayerControllerWindows!,
                                  showControls: false,
                                ),
                           */
                          Video(
                            player: _.videoPlayerControllerWindows!,
                            showControls: false,
                          ),
                        ],
                      );
                    })
                  else
                    RxBuilder(
                        //observables: [_.videoFit],
                        (__) {
                      _.dataStatus.status.value;
                      if (kDebugMode) {
                        print("Fit is ${widget.controller.videoFit.value}");
                      }
                      return SizedBox.expand(
                        child: FittedBox(
                          fit: widget.controller.videoFit.value,
                          child: SizedBox(
                            width: _.videoPlayerController != null
                                ? _.videoPlayerController!.value.size.width
                                : 640,
                            height: _.videoPlayerController != null
                                ? _.videoPlayerController!.value.size.height
                                : 480,
                            child: VideoPlayer(_.videoPlayerController!),
                          ),
                        ),
                      );
                    }),
                  ClosedCaptionView(responsive: responsive),
                  if (_.controlsEnabled &&
                      _.controlsStyle == ControlsStyle.primary)
                    PrimaryVideoPlayerControls(
                      responsive: responsive,
                    ),
                  if (_.controlsEnabled &&
                      _.controlsStyle == ControlsStyle.secondary)
                    SecondaryVideoPlayerControls(
                      responsive: responsive,
                    ),
                ],
              );
            },
          )),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class FlutterVideoPlayerProvider extends InheritedWidget {
  final FlutterVideoPlayerController controller;

  const FlutterVideoPlayerProvider({
    Key? key,
    required Widget child,
    required this.controller,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return false;
  }
}
