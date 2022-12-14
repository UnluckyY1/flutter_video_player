// ignore_for_file: must_be_immutable

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_meedu/ui.dart';

import 'package:flutter/material.dart';
import 'package:flutter_video_player/flutter_video_player.dart';
import 'package:flutter_video_player/src/helpers/utils.dart';
import 'package:flutter_video_player/src/widgets/forward_and_rewind.dart';
import 'package:flutter_video_player/src/widgets/rewind_and_forward_layout.dart';

class ControlsContainer extends StatelessWidget {
  final Widget child;
  bool playing = false;
  bool gettingNotification = false;
  late Offset horizontalDragStartOffset;
  Offset _dragInitialDelta = Offset.zero;
  Offset _verticalDragStartOffset = Offset.zero;
  //Offset _mouseMoveInitial = Offset.zero;
  //Duration _initialForwardPosition = Duration.zero;
  //Axis _dragDirection = Axis.vertical;

  Offset _horizontalDragStartOffset = Offset.zero;
  final ValueNotifier<double> _currentVolume = ValueNotifier<double>(1.0);
  double _onDragStartVolume = 1;
  double _onDragStartBrightness = 1;
  bool isVolume = false;
  //bool gettingNotification = false;
  final int _defaultSeekAmount = -10;
  Timer? _doubleTapToSeekTimer;
  Timer? _tappedOnce;
  bool tappedTwice = false;

  final ValueNotifier<double> _currentBrightness = ValueNotifier<double>(1.0);
  //final double _minScale = 1.0;
  //double _initialScale = 1.0, _maxScale = 1.0;

  //Duration swipeDuration=Duration(seconds: 0);
  ControlsContainer({required this.child, super.key});
  //------------------------------------//
  //FORWARD AND REWIND (DRAG HORIZONTAL)//
  //------------------------------------//

  void _forwardDragStart(
      Offset globalPosition, FlutterVideoPlayerController controller) async {
    playing = controller.playerStatus.playing;
    controller.pause();
    //_initialForwardPosition = controller.position.value;
    _horizontalDragStartOffset = globalPosition;
    controller.showSwipeDuration.value = true;
  }

  void tappedOnce(FlutterVideoPlayerController _, bool secoundTap) {
    if (secoundTap) {
      _tappedOnce?.cancel();
      _.controls = false;
    } else {
      tappedTwice = true;
      _.controls = !_.showControls.value;
      _tappedOnce?.cancel();
      _tappedOnce = Timer(const Duration(milliseconds: 300), () {
        if (kDebugMode) {
          print(
              '_____________________hidden here 0____________________________');
        }
        tappedTwice = false;
        //_dragInitialDelta = Offset.zero;
      });
    }
  }

  void _rewind(FlutterVideoPlayerController controller) =>
      _showRewindAndForward(0, controller);
  void _forward(FlutterVideoPlayerController controller) =>
      _showRewindAndForward(1, controller);

  void _showRewindAndForward(
      int index, FlutterVideoPlayerController controller) async {
    if (controller.isDesktop) {
      controller.screenManager
          .setWindowsFullScreen(!controller.fullscreen.value, controller);
    } else {
      //controller.videoSeekToNextSeconds(amount);
      if (index == 0) {
        controller.doubleTapCount.value += 1;
      } else {
        controller.doubleTapCount.value -= 1;
      }

      if (controller.doubleTapCount.value < 0) {
        controller.rewindIcons.value = false;
        controller.forwardIcons.value = true;
      } else {
        if (controller.doubleTapCount.value > 0) {
          controller.rewindIcons.value = true;
          controller.forwardIcons.value = false;
        } else {
          controller.rewindIcons.value = false;
          controller.forwardIcons.value = false;
        }
      }

      _doubleTapToSeekTimer?.cancel();
      _doubleTapToSeekTimer = Timer(const Duration(milliseconds: 500), () {
        playing = controller.playerStatus.playing;
        controller.videoSeekToNextSeconds(
            _defaultSeekAmount * controller.doubleTapCount.value, playing);
        if (kDebugMode) print('tapped is false here');
        tappedTwice = false;
        controller.rewindIcons.value = false;
        controller.forwardIcons.value = false;
        controller.doubleTapCount.value = 0;
      });
    }
  }

  void _forwardDragUpdate(
      Offset globalPosition, FlutterVideoPlayerController controller) {
    final double diff = _horizontalDragStartOffset.dx - globalPosition.dx;
    final int duration = controller.duration.value.inSeconds;
    final int position = controller.position.value.inSeconds;
    final int seconds = -(diff / (5000 / duration)).round();
    final int relativePosition = position + seconds;
    if (relativePosition <= duration && relativePosition >= 0) {
      controller.swipeDuration.value = seconds;
    }
  }

  void _forwardDragEnd(FlutterVideoPlayerController controller) async {
    _dragInitialDelta = Offset.zero;
    if (controller.swipeDuration.value != 0) {
      await controller.videoSeekToNextSeconds(
          controller.swipeDuration.value, playing);
    }
    controller.showSwipeDuration.value = false;
  }

  //----------------------------//
  //VIDEO VOLUME (VERTICAL DRAG)//

  void _volumeDragUpdate(
      Offset globalPosition, FlutterVideoPlayerController controller) {
    double diff = _verticalDragStartOffset.dy - globalPosition.dy;
    double volume = (diff / 500) + _onDragStartVolume;
    if (volume >= 0 &&
        volume <= 1 &&
        differenceOfExists((controller.volume.value * 100).round(),
            (volume * 100).round(), 2)) {
      if (kDebugMode) print('Volume$volume');
      //print("current ${(controller.volume.value*100).round()}");
      //print("new ${(volume*100).round()}");
      controller.setVolume(volume);
    }
  }

  void _volumeDragStart(
      Offset globalPosition, FlutterVideoPlayerController controller) {
    controller.showVolumeStatus.value = true;
    controller.showBrightnessStatus.value = false;
    isVolume = true;
    _currentVolume.value = controller.volume.value;
    _onDragStartVolume = _currentVolume.value;
    _verticalDragStartOffset = globalPosition;
  }

  void _volumeDragEnd(FlutterVideoPlayerController controller) {
    _dragInitialDelta = Offset.zero;
    isVolume = false;
    controller.showVolumeStatus.value = false;
  }

  bool differenceOfExists(
      int originalValue, int valueToCompareTo, int difference) {
    bool plus = originalValue + difference < valueToCompareTo ||
        valueToCompareTo == 0 ||
        valueToCompareTo == 100;
    bool minus = originalValue - difference > valueToCompareTo;
    //print("originalValue"+(originalValue).toString());
    //print("valueToCompareTo"+(valueToCompareTo).toString());
    //print("originalValue+difference"+(originalValue+difference).toString());
    //print("originalValue-difference"+(originalValue-difference).toString());
    //print("plus "+plus.toString());
    //print("minus "+minus.toString());
    //print("______________________________________");
    if (plus || minus) {
      return true;
    } else {
      return false;
    }
  }

  void _brightnessDragUpdate(
      Offset globalPosition, FlutterVideoPlayerController controller) {
    double diff = _verticalDragStartOffset.dy - globalPosition.dy;
    double brightness = (diff / 500) + _onDragStartBrightness;
    //print("New");
    //print((controller.brightness.value*100).round());
    //print((brightness*100).round());
    if (brightness >= 0 &&
        brightness <= 1 &&
        differenceOfExists((controller.brightness.value * 100).round(),
            (brightness * 100).round(), 2)) {
      if (kDebugMode) print('brightness $brightness');
      //brightness
      controller.setBrightness(brightness);
    }
  }

  void _brightnessDragStart(
      Offset globalPosition, FlutterVideoPlayerController controller) async {
    controller.showBrightnessStatus.value = true;
    controller.showVolumeStatus.value = false;

    _currentBrightness.value = controller.brightness.value;
    _onDragStartBrightness = _currentBrightness.value;
    _verticalDragStartOffset = globalPosition;
  }

  void _brightnessDragEnd(FlutterVideoPlayerController controller) {
    _dragInitialDelta = Offset.zero;
    controller.showBrightnessStatus.value = false;
    isVolume = false;
  }

  Widget controlsUI(FlutterVideoPlayerController _, BuildContext context) {
    return Stack(children: [
      VideoCoreForwardAndRewindLayout(
        rewind: GestureDetector(
          onTap: () {
            if (_.doubleTapCount.value != 0 || tappedTwice) {
              _rewind(_);
              tappedOnce(_, true);
            } else {
              tappedOnce(_, false);
            }
          },
          //behavior: HitTestBehavior.opaque,
        ),
        forward: GestureDetector(
          onTap: () {
            //print("0 " + tappedTwice.toString());

            if (_.doubleTapCount.value != 0 || tappedTwice) {
              _forward(_);

              tappedOnce(_, true);
            } else {
              tappedOnce(_, false);
            }
          },
          //behavior: HitTestBehavior.,
        ),
      ),
      RxBuilder((__) {
        if (_.isDesktop) {
          return MouseRegion(
              cursor: _.showControls.value
                  ? SystemMouseCursors.basic
                  : SystemMouseCursors.none,
              onHover: (___) {
                if (_.mouseMoveInitial < const Offset(75, 75).distance) {
                  _.mouseMoveInitial = _.mouseMoveInitial + ___.delta.distance;
                } else {
                  _.controls = true;
                }
              },
              child: videoControls(_, context));
        } else {
          return videoControls(_, context);
        }
      }),
      RxBuilder(
        //observables: [_.volume],
        (__) => AnimatedOpacity(
          duration: const Duration(milliseconds: 100),
          opacity: _.showVolumeStatus.value ? 1 : 0,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.all(10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: context.mediaQuerySize.height / 2,
                  width: 35,
                  child: Stack(
                    alignment: AlignmentDirectional.bottomCenter,
                    children: [
                      Container(color: Colors.black38),
                      Container(
                        height:
                            _.volume.value * context.mediaQuerySize.height / 2,
                        color: Colors.blue,
                      ),
                      Container(
                          padding: const EdgeInsets.all(5),
                          child: const Icon(
                            Icons.music_note,
                            color: Colors.white,
                          )),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      RxBuilder(
        //observables: [_.volume],
        (__) => AnimatedOpacity(
          duration: const Duration(milliseconds: 100),
          opacity: _.showBrightnessStatus.value ? 1 : 0,
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.all(10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: context.mediaQuerySize.height / 2,
                  width: 35,
                  child: Stack(
                    alignment: AlignmentDirectional.bottomCenter,
                    children: [
                      Container(color: Colors.black38),
                      Container(
                        height: _.brightness.value *
                            context.mediaQuerySize.height /
                            2,
                        color: Colors.blue,
                      ),
                      Container(
                          padding: const EdgeInsets.all(5),
                          child: const Icon(
                            Icons.wb_sunny,
                            color: Colors.white,
                          )),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      RxBuilder(
        //observables: [_.showSwipeDuration],
        //observables: [_.swipeDuration],
        (__) => Align(
          alignment: Alignment.center,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 100),
            opacity: _.showSwipeDuration.value ? 1 : 0,
            child: Visibility(
              visible: _.showSwipeDuration.value,
              child: Container(
                color: Colors.grey[900],
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _.swipeDuration.value > 0
                        ? '+ ${printDuration(Duration(seconds: _.swipeDuration.value))}'
                        : '- ${printDuration(Duration(seconds: _.swipeDuration.value))}',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      RxBuilder(
        //observables: [_.showSwipeDuration],
        //observables: [_.swipeDuration],
        (__) => Align(
          alignment: Alignment.center,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 100),
            opacity: _.videoFitChanged.value ? 1 : 0,
            child: Visibility(
              visible: _.videoFitChanged.value,
              child: Container(
                color: Colors.grey[900],
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _.videoFit.value.name,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      RxBuilder(
          //observables: [_.showControls],
          (__) {
        _.dataStatus.status.value;
        if (_.dataStatus.error) {
          return Center(
              child: Text(
            _.errorText!,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ));
        } else {
          return Container();
        }
      }),
      RxBuilder(
          //observables: [_.showControls],
          (__) {
        _.dataStatus.status.value;
        if (_.dataStatus.loading || _.isBuffering.value) {
          return Center(
            child: _.loadingWidget,
          );
        } else {
          return Container();
        }
      }),
      RxBuilder(
        //observables: [_.showControls],
        (__) => VideoCoreForwardAndRewind(
          showRewind: _.rewindIcons.value,
          showForward: _.forwardIcons.value,
          rewindSeconds: _defaultSeekAmount * _.doubleTapCount.value,
          forwardSeconds: _defaultSeekAmount * _.doubleTapCount.value,
        ),
      ),
      Positioned.fill(
        bottom: MediaQuery.of(context).size.height * 0.20,
        top: MediaQuery.of(context).size.height * 0.20,
        child: VideoCoreForwardAndRewindLayout(
          rewind: GestureDetector(
            onTap: () {
              if (_.doubleTapCount.value != 0 || tappedTwice) {
                _rewind(_);
                tappedOnce(_, true);
              } else {
                tappedOnce(_, false);
              }
            },
          ),
          forward: GestureDetector(
            onTap: () {
              if (_.doubleTapCount.value != 0 || tappedTwice) {
                _forward(_);
                tappedOnce(_, true);
              } else {
                tappedOnce(_, false);
              }
            },
            //behavior: HitTestBehavior.,
          ),
        ),
      ),
    ]);
  }

  Widget videoControls(FlutterVideoPlayerController _, BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_.isDesktop) {
          if (_.doubleTapCount.value != 0 || tappedTwice) {
            _rewind(_);
            tappedOnce(_, true);
          } else {
            tappedOnce(_, false);
          }
        }
        _.controls = !_.showControls.value;
        _dragInitialDelta = Offset.zero;
      },
      onHorizontalDragUpdate: (DragUpdateDetails details) {
        if (!_.isDesktop) {
          //if (!_.videoPlayerController!.value.isInitialized) {
          //return;
          //}

          //_.controls=true;
          final Offset position = details.localPosition;
          if (_dragInitialDelta == Offset.zero) {
            final Offset delta = details.delta;
            if (details.globalPosition.dx >
                    MediaQuery.of(context).size.width * 0.1 &&
                ((MediaQuery.of(context).size.width -
                            details.globalPosition.dx) >
                        MediaQuery.of(context).size.width * 0.1 &&
                    !gettingNotification)) {
              _forwardDragStart(position, _);
              _dragInitialDelta = delta;
            } else {
              if (kDebugMode) debugPrint('##############out###############');
              gettingNotification = true;
            }
          }
          if (!gettingNotification) {
            _forwardDragUpdate(position, _);
          }
        }

        //_.videoPlayerController!.seekTo(position);
      },
      onHorizontalDragEnd: (DragEndDetails details) {
        if (!_.isDesktop) {
          gettingNotification = false;
          _forwardDragEnd(_);
        }
      },
      onVerticalDragUpdate: (DragUpdateDetails details) {
        if (!_.isDesktop) {
          final Offset position = details.localPosition;
          if (_dragInitialDelta == Offset.zero) {
            if (kDebugMode) print(details.globalPosition.dy);

            if (details.globalPosition.dy >
                    MediaQuery.of(context).size.height * 0.1 &&
                ((MediaQuery.of(context).size.height -
                        details.globalPosition.dy) >
                    MediaQuery.of(context).size.height * 0.1) &&
                !gettingNotification) {
              final Offset delta = details.delta;
              //if(details.globalPosition.dy<30){
              if (details.globalPosition.dx >=
                  MediaQuery.of(context).size.width / 2) {
                _volumeDragStart(position, _);
                _dragInitialDelta = delta;
                //print("right");
              } else {
                if (!_.isDesktop) {
                  _brightnessDragStart(position, _);
                }
                _dragInitialDelta = delta;
                //print("left");
              }
            } else {
              if (kDebugMode) print('out');
              gettingNotification = true;
            }
            //}
          } else {
            if (!gettingNotification) {
              if (isVolume) {
                _volumeDragUpdate(position, _);
              } else {
                if (!_.isDesktop) {
                  _brightnessDragUpdate(position, _);
                }
              }
            }
          }
        }
        //_.videoPlayerController!.seekTo(position);
      },
      onVerticalDragEnd: (DragEndDetails details) {
        if (!_.isDesktop) {
          //if (!_.videoPlayerController!.value.isInitialized) {
          // return;
          //}
          gettingNotification = false;
          if (isVolume) {
            _volumeDragEnd(_);
          } else {
            if (!_.isDesktop) {
              _brightnessDragEnd(_);
            }
          }
        }
      },
      child: AnimatedOpacity(
        opacity: _.showControls.value ? 1 : 0,
        duration: Duration(milliseconds: _.showControls.value ? 150 : 0),
        child: AnimatedContainer(
          duration: Duration(milliseconds: _.showControls.value ? 150 : 0),
          color: _.showControls.value ? Colors.black38 : Colors.transparent,
          child: AbsorbPointer(
            absorbing: !_.showControls.value,
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = FlutterVideoPlayerController.of(context);

    return Positioned.fill(child: controlsUI(controller, context));
  }
}
