import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_meedu/ui.dart';
import 'package:flutter_video_player/flutter_video_player.dart';
import 'package:flutter_video_player/src/helpers/responsive.dart';
import 'package:flutter_video_player/src/widgets/closed_caption_view.dart';
import 'package:flutter_video_player/src/widgets/styles/primary/primary_player_controls.dart';
import 'package:flutter_video_player/src/widgets/styles/secondary/secondary_player_controls.dart';

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
    required this.controller,
    this.header,
    this.bottomRight,
    this.customIcons,
    super.key,
  });

  @override
  State<FlutterVideoPlayer> createState() => _FlutterVideoPlayerState();
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
              FlutterVideoPlayerController controller = widget.controller;
              final responsive = Responsive(
                constraints.maxWidth,
                constraints.maxHeight,
              );

              if (widget.customIcons != null) {
                controller.customIcons = widget.customIcons!(responsive);
              }

              if (widget.header != null) {
                controller.header =
                    widget.header!(context, controller, responsive);
              }

              if (widget.bottomRight != null) {
                controller.bottomRight =
                    widget.bottomRight!(context, controller, responsive);
              }

              return Stack(
                alignment: Alignment.center,
                children: [
                  if (controller.isDesktop)
                    RxBuilder(
                        //observables: [_.videoFit],
                        (__) {
                      //print("NATIVE HAS BEEN REBUILT ${_.videoPlayerControllerWindows}");
                      controller.dataStatus.status.value;
                      if (controller.videoPlayerControllerWindows == null) {
                        return const Text('Loading');
                      }

                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          Video(
                            player: controller.videoPlayerControllerWindows!,
                            showControls: false,
                          ),
                        ],
                      );
                    })
                  else
                    RxBuilder(
                        //observables: [_.videoFit],
                        (__) {
                      controller.dataStatus.status.value;
                      if (kDebugMode) {
                        print('Fit is ${widget.controller.videoFit.value}');
                      }
                      return SizedBox.expand(
                        child: FittedBox(
                          fit: widget.controller.videoFit.value,
                          child: SizedBox(
                            width: controller.videoPlayerController != null
                                ? controller
                                    .videoPlayerController!.value.size.width
                                : 640,
                            height: controller.videoPlayerController != null
                                ? controller
                                    .videoPlayerController!.value.size.height
                                : 480,
                            child: controller.videoPlayerController != null
                                ? VideoPlayer(controller.videoPlayerController!)
                                : const SizedBox(),
                          ),
                        ),
                      );
                    }),
                  ClosedCaptionView(responsive: responsive),
                  if (controller.controlsEnabled &&
                      controller.controlsStyle == ControlsStyle.primary)
                    PrimaryVideoPlayerControls(
                      responsive: responsive,
                    ),
                  if (controller.controlsEnabled &&
                      controller.controlsStyle == ControlsStyle.secondary)
                    SecondaryVideoPlayerControls(
                      responsive: responsive,
                    ),
                ],
              );
            },
          )),
    );
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
