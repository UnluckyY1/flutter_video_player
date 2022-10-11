import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_meedu/meedu.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_video_player/flutter_video_player.dart';
import 'package:flutter_video_player/src/widgets/fullscreen_page.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:wakelock/wakelock.dart';

enum ControlsStyle { primary, secondary }

class FlutterVideoPlayerController {
  /// the video_player controller
  VideoPlayerController? _videoPlayerController;
  Player? _videoPlayerControllerWindows;
  //final _pipManager = PipManager();
  StreamSubscription? _playerEventSubs;

  /// Screen Manager to define the overlays and device orientation when the player enters in fullscreen mode
  final ScreenManager screenManager;

  /// use this class to change the default icons with your custom icons
  CustomIcons customIcons;

  /// use this class to hide some buttons in the player
  EnabledButtons enabledButtons;

  /// the playerStatus to notify the player events like paused,playing or stopped
  /// [playerStatus] has a [status] observable
  final VideoPlayerStatus playerStatus = VideoPlayerStatus();

  /// the dataStatus to notify the load sources events
  /// [dataStatus] has a [status] observable
  final VideoPlayerDataStatus dataStatus = VideoPlayerDataStatus();
  final Color colorTheme;
  final bool controlsEnabled;
  String? _errorText;
  String? get errorText => _errorText;
  Widget? loadingWidget, header, bottomRight;
  final ControlsStyle controlsStyle;
  //final bool pipEnabled, showPipButton;

  String? tag;

  // OBSERVABLES
  final Rx<Duration> _position = Rx(Duration.zero);
  final Rx<Duration> _sliderPosition = Rx(Duration.zero);
  final Rx<Duration> _duration = Rx(Duration.zero);
  final Rx<int> _swipeDuration = 0.obs;
  Rx<int> doubleTapCount = 0.obs;
  final Rx<double> _currentVolume = 1.0.obs;
  final Rx<double> _playbackSpeed = 1.0.obs;
  final Rx<double> _currentBrightness = 0.0.obs;
  final Rx<List<DurationRange>> _buffered = Rx([]);
  Rx<double> bufferedPercent = Rx(0.0);
  final Rx<bool> _closedCaptionEnabled = false.obs;
  final Rx<bool> _mute = false.obs;
  final Rx<bool> _fullscreen = false.obs;
  final Rx<bool> _showControls = true.obs;
  final Rx<bool> _showSwipeDuration = false.obs;
  final Rx<bool> _showVolumeStatus = false.obs;
  final Rx<bool> _showBrightnessStatus = false.obs;

  Rx<bool> videoFitChanged = false.obs;
  final Rx<BoxFit> _videoFit = Rx(BoxFit.fill);
  //Rx<double> scale = 1.0.obs;
  Rx<bool> rewindIcons = false.obs;
  Rx<bool> forwardIcons = false.obs;
  // NO OBSERVABLES
  bool _isSliderMoving = false;
  bool _looping = false;
  bool _autoplay = false;
  double _volumeBeforeMute = 0;
  double mouseMoveInitial = 0;
  Timer? _timer;
  Timer? _timerForSeek;
  Timer? _timerForVolume;
  Timer? _timerForGettingVolume;
  Timer? timerForTrackingMouse;
  Timer? videoFitChangedTimer;
  Rx<bool> bufferingVideoDuration = false.obs;
  void Function()? onVideoPlayerClosed;
  List<BoxFit> fits = [
    BoxFit.contain,
    BoxFit.cover,
    BoxFit.fill,
    BoxFit.fitHeight,
    BoxFit.fitWidth,
    BoxFit.scaleDown
  ];

  // GETS
  StreamSubscription? postionStream;
  StreamSubscription? volumeStream;
  StreamSubscription? playBackStream;
  StreamSubscription? bufferStream;

  /// use this stream to listen the player data events like none, loading, loaded, error
  Stream<DataStatus> get onDataStatusChanged => dataStatus.status.stream;

  /// use this stream to listen the player data events like stopped, playing, paused
  Stream<PlayerStatus> get onPlayerStatusChanged => playerStatus.status.stream;

  /// current position of the player
  Rx<Duration> get position => _position;

  /// use this stream to listen the changes in the video position
  Stream<Duration> get onPositionChanged => _position.stream;

  /// duration of the video
  Rx<Duration> get duration => _duration;

  /// use this stream to listen the changes in the video duration
  Stream<Duration> get onDurationChanged => _duration.stream;

  /// [mute] is true if the player is muted
  Rx<bool> get mute => _mute;
  Stream<bool> get onMuteChanged => _mute.stream;

  /// [fullscreen] is true if the player is in fullscreen mode
  Rx<bool> get fullscreen => _fullscreen;
  Stream<bool> get onFullscreenChanged => _fullscreen.stream;

  /// [showControls] is true if the player controls are visible
  Rx<bool> get showControls => _showControls;
  Stream<bool> get onShowControlsChanged => _showControls.stream;

  /// [showSwipeDuration] is true if the player controls are visible
  Rx<bool> get showSwipeDuration => _showSwipeDuration;
  Stream<bool> get onShowSwipeDurationChanged => _showSwipeDuration.stream;

  /// [showSwipeDuration] is true if the player controls are visible
  Rx<bool> get showVolumeStatus => _showVolumeStatus;
  Stream<bool> get onShowVolumeStatusChanged => _showVolumeStatus.stream;

  /// [showSwipeDuration] is true if the player controls are visible
  Rx<bool> get showBrightnessStatus => _showBrightnessStatus;
  Stream<bool> get onShowBrightnessStatusChanged =>
      _showBrightnessStatus.stream;

  /// [swipeDuration] is true if the player controls are visible
  Rx<int> get swipeDuration => _swipeDuration;
  Stream<int> get onSwipeDurationChanged => _swipeDuration.stream;

  /// [volume] is true if the player controls are visible
  Rx<double> get volume => _currentVolume;
  Stream<double> get onVolumeChanged => _currentVolume.stream;

  /// [volume] is true if the player controls are visible
  Rx<double> get brightness => _currentBrightness;
  Stream<double> get onBrightnessChanged => _currentBrightness.stream;

  /// [sliderPosition] the video slider position
  Rx<Duration> get sliderPosition => _sliderPosition;
  Stream<Duration> get onSliderPositionChanged => _sliderPosition.stream;

  /// [bufferedLoaded] buffered Loaded for network resources
  Rx<List<DurationRange>> get buffered => _buffered;
  Stream<List<DurationRange>> get onBufferedChanged => _buffered.stream;

  /// [videoPlayerController] instace of VideoPlayerController
  VideoPlayerController? get videoPlayerController => _videoPlayerController;

  /// [videoPlayerController] instace of VideoPlayerController
  Player? get videoPlayerControllerWindows => _videoPlayerControllerWindows;

  /// the playback speed default value is 1.0
  double get playbackSpeed => _playbackSpeed.value;

  /// [looping] is true if the player is looping
  bool get looping => _looping;

  /// [autoPlay] is true if the player has enabled the autoplay
  bool get autoplay => _autoplay;

  Rx<bool> get closedCaptionEnabled => _closedCaptionEnabled;
  Stream<bool> get onClosedCaptionEnabledChanged =>
      _closedCaptionEnabled.stream;

  bool isDesktop = false;

  /// [isInPipMode] is true if pip mode is enabled
  //Rx<bool> get isInPipMode => _pipManager.isInPipMode;
  //Stream<bool?> get onPipModeChanged => _pipManager.isInPipMode.stream;

  Rx<bool> isBuffering = false.obs;
  SharedPreferences? prefs;

  /// returns the os version
  //Future<double> get osVersion async {
  //return _pipManager.osVersion;
  //}

  /// returns true if the pip mode can used on the current device, the initial value will be false after check if pip is available
  //Rx<bool> get pipAvailable => _pipAvailable;

  /// return fit of the Video,By default it is set to [BoxFit.contain]
  Rx<BoxFit> get videoFit => _videoFit;

  /// creates an instance of [MeeduPlayerControlle]
  ///
  /// [screenManager] the device orientations and overlays
  /// [placeholder] widget to show when the player is loading a video
  /// [controlsEnabled] if the player must show the player controls
  /// [errorText] message to show when the load process failed
  FlutterVideoPlayerController({
    this.screenManager = const ScreenManager(),
    this.colorTheme = Colors.white,
    Widget? loadingWidget,
    this.controlsEnabled = true,
    String? errorText,
    this.controlsStyle = ControlsStyle.primary,
    this.header,
    this.bottomRight,
    //this.pipEnabled = false,
    //this.showPipButton = false,
    this.customIcons = const CustomIcons(),
    this.enabledButtons = const EnabledButtons(),
    this.onVideoPlayerClosed,
  }) {
    getUserPreferenceForFit();

    _errorText = errorText;
    tag = DateTime.now().microsecondsSinceEpoch.toString();
    this.loadingWidget = loadingWidget ??
        SpinKitWave(
          size: 30,
          color: colorTheme,
        );
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      isDesktop = true;
    }
    //check each
    if (!isDesktop) {
      VolumeController().listener((newVolume) {
        volume.value = newVolume;
      });
    }

    _playerEventSubs = onPlayerStatusChanged.listen(
      (PlayerStatus status) {
        if (status == PlayerStatus.playing) {
          Wakelock.enable();
        } else {
          Wakelock.disable();
        }
      },
    );
  }
  Future<void> registerHotKeys() async {
    if (HotKeyManager.instance.registeredHotKeyList.isEmpty) {
      HotKey arrowUP = HotKey(
        KeyCode.arrowUp,
        scope: HotKeyScope.inapp,
      );
      HotKey arrowDown = HotKey(
        KeyCode.arrowDown,
        scope: HotKeyScope.inapp,
      );
      HotKey arrowRight = HotKey(
        KeyCode.arrowRight,
        scope: HotKeyScope.inapp,
      );
      HotKey arrowLeft = HotKey(
        KeyCode.arrowLeft,
        scope: HotKeyScope.inapp,
      );
      HotKey escape = HotKey(
        KeyCode.escape,
        scope: HotKeyScope.inapp,
      );
      HotKey enter = HotKey(
        KeyCode.enter,
        scope: HotKeyScope.inapp,
      );
      HotKey spaceBar = HotKey(
        KeyCode.space,
        scope: HotKeyScope.inapp,
      );
      HotKey dot = HotKey(
        KeyCode.numpadDecimal,
        scope: HotKeyScope.inapp,
      );
      await HotKeyManager.instance.register(
        arrowUP,
        keyDownHandler: (hotKey) {
          if (kDebugMode) print('onKeyDown+${hotKey.toJson()}');
          setVolume(volume.value + 0.05);
        },
      );
      await HotKeyManager.instance.register(
        arrowDown,
        keyDownHandler: (hotKey) {
          if (kDebugMode) print('onKeyDown+${hotKey.toJson()}');
          setVolume(volume.value - 0.05);
        },
      );
      await HotKeyManager.instance.register(
        arrowRight,
        keyDownHandler: (hotKey) {
          if (kDebugMode) print('onKeyDown+${hotKey.toJson()}');
          seekTo(position.value + const Duration(seconds: 5));
        },
      );
      await HotKeyManager.instance.register(
        arrowLeft,
        keyDownHandler: (hotKey) {
          if (kDebugMode) print('onKeyDown+${hotKey.toJson()}');
          seekTo(position.value - const Duration(seconds: 5));
        },
      );

      await HotKeyManager.instance.register(
        escape,
        keyDownHandler: (hotKey) {
          if (kDebugMode) print('onKeyDown+${hotKey.toJson()}');
          screenManager.setWindowsFullScreen(false, this);
        },
      );
      await HotKeyManager.instance.register(
        enter,
        keyDownHandler: (hotKey) {
          if (kDebugMode) print('onKeyDown+${hotKey.toJson()}');
          screenManager.setWindowsFullScreen(!_fullscreen.value, this);
        },
      );
      await HotKeyManager.instance.register(
        spaceBar,
        keyDownHandler: (hotKey) {
          if (kDebugMode) print('onKeyDown+${hotKey.toJson()}');
          if (playerStatus.playing) {
            pause();
          } else {
            play();
          }
        },
      );
      await HotKeyManager.instance.register(
        dot,
        keyDownHandler: (hotKey) {
          toggleVideoFit();
        },
      );
    } else {
      if (kDebugMode) print('hotkeys are registered ');
    }
    //await HotKeyManager.instance.unregister(_hotKey);
  }

  Future<String> extractAudioAndVideoTs(
    String m3u8, {
    String initialSubtitle = '',
    String Function(String quality)? formatter,
    bool descending = true,
  }) async {
    Dio dio = Dio();
    (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
        (HttpClient client) {
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };
    dio.options.connectTimeout = 5 * 1000;

    dio.interceptors.add(RetryInterceptor(
      dio: dio,
      logPrint: print, // specify log function (optional)
      retries: 10, // retry count (optional)
      retryDelays: const [
        // set delays between retries (optional)
        Duration(seconds: 1), // wait 1 sec before first retry
        Duration(seconds: 2), // wait 2 sec before second retry
        Duration(seconds: 3), // wait 3 sec before third retry
      ],
    ));

//REGULAR EXPRESIONS//
    final RegExp netRegxUrl = RegExp(r'^(http|https):\/\/([\w.]+\/?)\S*');
    final RegExp netRegx2 = RegExp(r'(.*)\r?\/');
    final RegExp regExpPlaylist = RegExp(
      r'#EXT-X-STREAM-INF:(?:.*,RESOLUTION=(\d+x\d+))?,?(.*)\r?\n(.*)',
      caseSensitive: false,
      multiLine: true,
    );
    final RegExp regExpAudio = RegExp(
      r'''^#EXT-X-MEDIA:TYPE=AUDIO(?:.*,URI="(.*m3u8.*)")''',
      caseSensitive: false,
      multiLine: true,
    );
    final RegExp regExpListOfLinks =
        RegExp('#EXTINF:.+?\n+(.+)', multiLine: true, caseSensitive: false);
    Response res = await dio.get(m3u8);
    //GET m3u8 file
    String content = '';
    if (res.statusCode == 200) {
      content = res.data;

//Find matches
      List<RegExpMatch> playlistMatches =
          regExpPlaylist.allMatches(content).toList();
      List<RegExpMatch> audioMatches = regExpAudio.allMatches(content).toList();
      //List<RegExpMatch> ListOfLinks = regExpListOfLinks.allMatches(content).toList();
      Map<String, String> sourceUrls = {};

      final List<String> audioUrls = [];

      for (final RegExpMatch playlistMatch in playlistMatches) {
        final RegExpMatch? playlist = netRegx2.firstMatch(m3u8);
        final String sourceURL = (playlistMatch.group(3)).toString();
        final String quality = (playlistMatch.group(1)).toString();
        final bool isNetwork = netRegxUrl.hasMatch(sourceURL);
        String playlistUrl = sourceURL;

        if (!isNetwork) {
          final String? dataURL = playlist!.group(0);
          playlistUrl = '$dataURL$sourceURL';
        }

        //Find audio url
        for (final RegExpMatch audioMatch in audioMatches) {
          final String audio = (audioMatch.group(1)).toString();
          final bool isNetwork = netRegxUrl.hasMatch(audio);
          final RegExpMatch? match = netRegx2.firstMatch(playlistUrl);
          String audioUrl = audio;

          if (!isNetwork && match != null) {
            audioUrl = '${match.group(0)}$audio';
          }
          audioUrls.add(audioUrl);
        }

        sourceUrls[quality] = playlistUrl;
      }
      //print("here");
      List<String> qualityKeys = sourceUrls.keys.toList();
      qualityKeys.sort((a, b) {
        try {
          return int.parse(a.split('x')[0])
              .compareTo(int.parse(b.split('x')[0]));
        } catch (_) {
          if (kDebugMode) print('error comparing qualities hls,$_');
          return -1;
        }
      });
      if (sourceUrls.isEmpty) {
        //input was playlist
        List<RegExpMatch> listOfLinks =
            regExpListOfLinks.allMatches(content).toList();
        String baseUrl = m3u8;
        for (final element in listOfLinks) {
          final bool isNetwork = netRegxUrl.hasMatch(element.group(1) ?? '');
          if (!isNetwork) {
            content.replaceAll(element.group(1) ?? '',
                "${baseUrl.substring(0, baseUrl.lastIndexOf('/'))}/${element.group(1) ?? ""}");
          }
        }
        return content;
      }

      //print(downloadLinks);
      return '';
    } else {
      return '';
    }
  }

  /// create a new video_player controller
  VideoPlayerController _createVideoController(DataSource dataSource) {
    switch (dataSource.type) {
      case DataSourceType.asset:
        return VideoPlayerController.asset(
          dataSource.source!,
          closedCaptionFile: dataSource.closedCaptionFile,
          package: dataSource.package,
        );

      case DataSourceType.network:
        return VideoPlayerController.network(
          dataSource.source!,
          formatHint: dataSource.formatHint,
          videoPlayerOptions: VideoPlayerOptions(),
          closedCaptionFile: dataSource.closedCaptionFile,
          httpHeaders: dataSource.httpHeaders ?? {},
        );

      default:
        return VideoPlayerController.file(
          dataSource.file!,
          closedCaptionFile: dataSource.closedCaptionFile,
        );
    }
  }

  /// create a new video_player controller
  Player _createVideoControllerWindows(DataSource dataSource, Duration seekTo) {
    Random random = Random();
    int randomNumber = random.nextInt(1000);
    String refer = '';
    if (dataSource.type == DataSourceType.network) {
      if (dataSource.httpHeaders != null) {
        refer = dataSource.httpHeaders!['Referer'] ?? '';
      }
    }

    Player player = Player(
      id: randomNumber,
      commandlineArguments: [
        //"-vvv",
        '--http-referrer=$refer',
        '--http-reconnect',
        '--sout-livehttp-caching',
        '--network-caching=60000',
        '--file-caching=60000'
      ],
      //registerTexture: !Platform.isWindows
    ); // create a new video controller

    player = setPlayerDataSource(dataSource, player, seekTo);
    return player;
  }

  Player setPlayerDataSource(DataSource dataSource, Player player, seekTo) {
    duration.value = Duration.zero;

    switch (dataSource.type) {
      case DataSourceType.asset:
        player.open(
          Media.asset(dataSource.source!),
          autoStart: _autoplay,
        );
        break;
      case DataSourceType.network:
        player.open(
          Media.network(
            dataSource.source!,
            timeout: const Duration(seconds: 10),
          ),
          autoStart: _autoplay,
        );
        break;
      default:
        player.open(
          Media.file(
            dataSource.file!,
          ),
          autoStart: _autoplay,
        );
        break;
    }

    if (seekTo != Duration.zero) {
      this.seekTo(seekTo);
    }

    return player;
  }

  /// initialize the video_player controller and load the data source
  Future _initializePlayer({
    Duration seekTo = Duration.zero,
  }) async {
    if (seekTo != Duration.zero) {
      if (kDebugMode) print('Called seek function to$seekTo');
      await this.seekTo(seekTo);
    }

    // if the playbackSpeed is not the default value
    if (_playbackSpeed.value != 1.0) {
      await setPlaybackSpeed(_playbackSpeed.value);
    }

    if (_looping) {
      await setLooping(_looping);
    }

    if (_autoplay) {
      // if the autoplay is enabled
      await play();
    }
  }

  Future<void> removeWindowsListener() async {
    await postionStream?.cancel();
    await volumeStream?.cancel();
    await playBackStream?.cancel();
    await bufferStream?.cancel();
    postionStream = null;
    volumeStream = null;
    playBackStream = null;
    bufferStream = null;
  }

  void _listener({Player? player}) {
    if (player != null) {
      dataStatus.status.stream.listen((event) {
        if (event == DataStatus.loading) {
          playerStatus.status.value = PlayerStatus.paused;
        }
      });
      postionStream ??= player.positionStream.listen((event) {
        _duration.value = _videoPlayerControllerWindows!.position.duration!;
        _position.value = event.position!;
        if (_duration.value.inSeconds != 0) {
          if (dataStatus.status.value == DataStatus.loading) {
            dataStatus.status.value = DataStatus.loaded;
          }
        }
        if (!_isSliderMoving) {
          _sliderPosition.value = event.position!;
        }
        // check if the player has been finished
        if (_position.value.inSeconds >= duration.value.inSeconds &&
            !playerStatus.stopped) {
          playerStatus.status.value = PlayerStatus.stopped;
        }
      });
      volumeStream ??= player.generalStream.listen((GeneralState state) {
        volume.value = state.volume;
        //state.rate;
      });
      playBackStream ??= player.playbackStream.listen((event) {
        if (event.isPlaying) {
          playerStatus.status.value = PlayerStatus.playing;
        } else {
          if (event.isCompleted) {
            playerStatus.status.value = PlayerStatus.stopped;
          } else {
            playerStatus.status.value = PlayerStatus.paused;
          }
        }
      });
      bufferStream ??= player.bufferingProgressStream.listen((event) {
        bufferedPercent.value = (event / 100);
        _buffered.value = [
          (DurationRange(
              Duration.zero,
              Duration(
                  seconds: (bufferedPercent.value * _duration.value.inSeconds)
                      .round())))
        ];
        isBuffering.value =
            (playerStatus.status.value == PlayerStatus.playing) &&
                (event != 100);
      });
    } else {
      final value = _videoPlayerController!.value;
      // set the current video position
      final position = value.position;
      _position.value = position;
      if (!_isSliderMoving) {
        _sliderPosition.value = position;
      }

      // set the video buffered loaded
      final buffered = value.buffered;

      if (buffered.isNotEmpty) {
        _buffered.value = buffered;
        isBuffering.value = value.isPlaying &&
            position.inSeconds >= buffered.last.end.inSeconds;
        bufferedPercent.value =
            buffered.last.end.inSeconds / duration.value.inSeconds;
      }

      // save the volume value
      final volume = value.volume;
      if (!mute.value && _volumeBeforeMute != volume) {
        _volumeBeforeMute = volume;
      }

      // check if the player has been finished
      if (_position.value.inSeconds >= duration.value.inSeconds &&
          !playerStatus.stopped) {
        playerStatus.status.value = PlayerStatus.stopped;
      }
    }
  }

  /// set the video data source
  ///
  /// [autoPlay] if this is true the video automatically start
  Future<void> setDataSource(
    DataSource dataSource, {
    bool autoplay = true,
    bool looping = false,
    Duration seekTo = Duration.zero,
  }) async {
    try {
      _autoplay = autoplay;
      _looping = looping;
      dataStatus.status.value = DataStatus.loading;
      if (isDesktop) {
        if (_videoPlayerControllerWindows != null &&
            _videoPlayerControllerWindows!.playback.isPlaying) {
          await pause(notify: false);
        }
      } else {
        // if we are playing a video
        if (_videoPlayerController != null &&
            _videoPlayerController!.value.isPlaying) {
          await pause(notify: false);
        }
      }

      // save the current video controller to be disposed in the next frame
      VideoPlayerController? oldController = _videoPlayerController;
      Player? oldControllerWindows = _videoPlayerControllerWindows;

      // create a new video_player controller using the dataSource
      if (isDesktop) {
        _videoPlayerControllerWindows =
            _createVideoControllerWindows(dataSource, seekTo);

        if (oldControllerWindows != null) {
          await removeWindowsListener();
          oldControllerWindows
              .dispose(); // dispose the previous video controller
        }

        /// notify that video was loaded
        dataStatus.status.value = DataStatus.loaded;

        _listener(player: _videoPlayerControllerWindows);
      } else {
        _videoPlayerController = _createVideoController(dataSource);

        await _videoPlayerController!.initialize();

        if (oldController != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            oldController.removeListener(_listener);
            await oldController
                .dispose(); // dispose the previous video controller
          });
        }
        // set the video duration

        _duration.value = _videoPlayerController!.value.duration;

        /// notify that video was loaded
        dataStatus.status.value = DataStatus.loaded;

        // listen the video player events
        _videoPlayerController!.addListener(_listener);
      }

      await _initializePlayer(seekTo: seekTo);
    } catch (e, s) {
      if (kDebugMode) {
        print(e);
        print(s);
      }
      _errorText ??= _videoPlayerController!.value.errorDescription;
      dataStatus.status.value = DataStatus.error;
    }
  }

  /// play the current video
  ///
  /// [repeat] if is true the player go to Duration.zero before play
  Future<void> play({bool repeat = false}) async {
    if (repeat) {
      await seekTo(Duration.zero);
    }
    if (isDesktop) {
      _videoPlayerControllerWindows?.play();
      await getCurrentVolume();
    } else {
      await _videoPlayerController?.play();
      await getCurrentVolume();
      await getCurrentBrightness();
    }
    playerStatus.status.value = PlayerStatus.playing;
    screenManager.setOverlays(false);
    _hideTaskControls();
  }

  /// pause the current video
  ///
  /// [notify] if is true and the events is not null we notifiy the event
  Future<void> pause({bool notify = true}) async {
    if (isDesktop) {
      _videoPlayerControllerWindows?.pause();
      playerStatus.status.value = PlayerStatus.paused;
    } else {
      await _videoPlayerController?.pause();
      playerStatus.status.value = PlayerStatus.paused;
    }
  }

  /// seek the current video position
  Future<void> seekTo(Duration position) async {
    _position.value = position;
    if (kDebugMode) {
      print('duration in seek function is ${duration.value.toString()}');
    }
    if (duration.value.inSeconds != 0) {
      if (position <= duration.value) {
        if (isDesktop) {
          _videoPlayerControllerWindows?.seek(position);
        } else {
          await _videoPlayerController?.seekTo(position);
        }
      } else {
        if (isDesktop) {
          _videoPlayerControllerWindows
              ?.seek(duration.value - const Duration(milliseconds: 100));
        } else {
          await _videoPlayerController
              ?.seekTo(duration.value - const Duration(milliseconds: 100));
        }
      }
      if (playerStatus.stopped) {
        play();
      }
    } else {
      _timerForSeek?.cancel();
      _timerForSeek =
          Timer.periodic(const Duration(milliseconds: 200), (Timer t) async {
        //_timerForSeek = null;
        if (kDebugMode) print('SEEK CALLED');
        if (duration.value.inSeconds != 0) {
          if (position <= duration.value) {
            if (isDesktop) {
              _videoPlayerControllerWindows?.seek(position);
            } else {
              await _videoPlayerController?.seekTo(position);
            }
          } else {
            if (isDesktop) {
              _videoPlayerControllerWindows
                  ?.seek(duration.value - const Duration(milliseconds: 100));
            } else {
              await _videoPlayerController
                  ?.seekTo(duration.value - const Duration(milliseconds: 100));
            }
          }
          if (playerStatus.stopped) {
            play();
          }
          t.cancel();
          _timerForSeek = null;
        }
      });
    }
  }

  /// Sets the playback speed of [this].
  ///
  /// [speed] indicates a speed value with different platforms accepting
  /// different ranges for speed values. The [speed] must be greater than 0.
  ///
  /// The values will be handled as follows:
  /// * On web, the audio will be muted at some speed when the browser
  ///   determines that the sound would not be useful anymore. For example,
  ///   "Gecko mutes the sound outside the range `0.25` to `5.0`" (see https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/playbackRate).
  /// * On Android, some very extreme speeds will not be played back accurately.
  ///   Instead, your video will still be played back, but the speed will be
  ///   clamped by ExoPlayer (but the values are allowed by the player, like on
  ///   web).
  /// * On iOS, you can sometimes not go above `2.0` playback speed on a video.
  ///   An error will be thrown for if the option is unsupported. It is also
  ///   possible that your specific video cannot be slowed down, in which case
  ///   the plugin also reports errors.
  Future<void> setPlaybackSpeed(double speed) async {
    if (isDesktop) {
    } else {
      await _videoPlayerController?.setPlaybackSpeed(speed);
      _playbackSpeed.value = speed;
    }
  }

  Future<void> togglePlaybackSpeed() async {
    List<double> allowedSpeeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.50, 1.75, 2.0];
    if (allowedSpeeds.indexOf(_playbackSpeed.value) <
        allowedSpeeds.length - 1) {
      setPlaybackSpeed(
          allowedSpeeds[allowedSpeeds.indexOf(_playbackSpeed.value) + 1]);
    } else {
      setPlaybackSpeed(allowedSpeeds[0]);
    }
  }

  /// Sets whether or not the video should loop after playing once
  Future<void> setLooping(bool looping) async {
    await _videoPlayerController?.setLooping(looping);
    _looping = looping;
  }

  void onChangedSliderStart() {
    _isSliderMoving = true;
  }

  onChangedSlider(double v) {
    _sliderPosition.value = Duration(seconds: v.floor());
  }

  void onChangedSliderEnd() {
    _isSliderMoving = false;
  }

  /// set the video player to mute or sound
  ///
  /// [enabled] if is true the video player is muted
  Future<void> setMute(bool enabled) async {
    if (enabled) {
      if (_videoPlayerController != null) {
        _volumeBeforeMute = _videoPlayerController!.value.volume;
      } else {
        _volumeBeforeMute = _videoPlayerControllerWindows!.general.volume;
      }
    }
    _mute.value = enabled;
    await setVolume(enabled ? 0 : _volumeBeforeMute);
  }

  /// fast Forward (10 seconds)
  Future<void> fastForward() async {
    final to = position.value.inSeconds + 10;
    if (duration.value.inSeconds > to) {
      await seekTo(Duration(seconds: to));
    }
  }

  /// rewind (10 seconds)
  Future<void> rewind() async {
    final to = position.value.inSeconds - 10;
    await seekTo(Duration(seconds: to < 0 ? 0 : to));
  }

  Future<void> getCurrentBrightness() async {
    if (!isDesktop) {
      try {
        _currentBrightness.value = await ScreenBrightness().current;
      } catch (e) {
        if (kDebugMode) print(e);
        throw 'Failed to get current brightness';
        //return 0;
      }
    }
  }

  Future<void> getCurrentVolume() async {
    if (isDesktop) {
      if (duration.value.inSeconds != 0) {
        try {
          _currentVolume.value = _videoPlayerControllerWindows!.general.volume;
        } catch (e) {
          if (kDebugMode) print('currentVolume $e');
          rethrow;
        }
      } else {
        _timerForGettingVolume?.cancel();
        _timerForGettingVolume =
            Timer.periodic(const Duration(milliseconds: 250), (Timer t) async {
          _timerForGettingVolume = null;
          if (duration.value.inSeconds != 0) {
            try {
              _currentVolume.value =
                  _videoPlayerControllerWindows!.general.volume;
            } catch (e) {
              if (kDebugMode) print('currentVolume $e');
              //throw 'Failed to get current volume';
              //return 0;
            }
          }
        });
      }
    } else {
      try {
        _currentVolume.value = await VolumeController().getVolume();
      } catch (e) {
        if (kDebugMode) print('currentVolume $e');
        //throw 'Failed to get current brightness';
        //return 0;
      }
    }
    //return 0;
  }

  Future<void> setBrightness(double brightnes) async {
    if (!isDesktop) {
      try {
        brightness.value = brightnes;
        ScreenBrightness().setScreenBrightness(brightnes);
        setUserPreferenceForBrightness();
      } catch (e) {
        if (kDebugMode) print(e);
        throw 'Failed to set brightness';
      }
    }
  }

  /// Sets the audio volume
  /// [volume] indicates a value between 0.0 (silent) and 1.0 (full volume) on a
  /// linear scale.
  Future<void> setVolume(double volumeNew) async {
    if (isDesktop) {
      if (volumeNew <= 0) {
        volumeNew = 0;
      }
      if (volumeNew >= 1) {
        volumeNew = 1;
      }
      try {
        volume.value = volumeNew;
        showVolumeStatus.value = true;
        _videoPlayerControllerWindows!.setVolume(volumeNew);
        _timerForVolume?.cancel();
        _timerForVolume = Timer(const Duration(milliseconds: 500), () {
          showVolumeStatus.value = false;
          _timerForVolume = null;
        });
      } catch (e) {
        if (kDebugMode) print(e);
        throw 'Failed to get current volume';
        //return 0;
      }
    } else {
      //assert(volumeNew >= 0.0 && volumeNew <= 1.0); // validate the param
      try {
        volume.value = volumeNew;
        VolumeController().setVolume(volumeNew, showSystemUI: false);
      } catch (_) {
        if (kDebugMode) print(_);
      }
    }
    //await _videoPlayerController?.setVolume(volume);
  }

  Future<void> resetBrightness() async {
    if (!isDesktop) {
      try {
        await ScreenBrightness().resetScreenBrightness();
      } catch (e) {
        if (kDebugMode) print(e);
        throw 'Failed to reset brightness';
      }
    }
  }

  /// show or hide the player controls
  set controls(bool visible) {
    //print("controls called");
    if (fullscreen.value) {
      //print("Closed");
      screenManager.setOverlays(visible);
    }
    _showControls.value = visible;
    _timer?.cancel();
    if (visible) {
      _hideTaskControls();
    }
  }

  /// create a tasks to hide controls after certain time
  void _hideTaskControls() {
    if (isDesktop) {
      _timer = Timer(const Duration(seconds: 2), () {
        controls = false;
        _timer = null;
        swipeDuration.value = 0;
        showSwipeDuration.value = false;
        mouseMoveInitial = 0;
      });
    } else {
      _timer = Timer(const Duration(seconds: 5), () {
        if (kDebugMode) print('hidden');
        controls = false;
        _timer = null;
        swipeDuration.value = 0;
        showSwipeDuration.value = false;
      });
    }
  }

  /// show the player in fullscreen mode
  Future<void> goToFullscreen(
    BuildContext context, {
    bool applyOverlaysAndOrientations = true,
  }) async {
    if (applyOverlaysAndOrientations) {
      if (isDesktop) {
        screenManager.setWindowsFullScreen(true, this);
      } else {
        screenManager.setFullScreenOverlaysAndOrientations();
      }
    }
    _fullscreen.value = true;
    final route = MaterialPageRoute(
      builder: (_) => VideoPlayerFullscreenPage(controller: this),
    );

    await Navigator.push(context, route);
  }

  /// launch a video using the fullscreen apge
  ///
  /// [dataSource]
  /// [autoplay]
  /// [looping]
  Future<void> launchAsFullscreen(
    BuildContext context, {
    required DataSource dataSource,
    bool autoplay = false,
    bool looping = false,
    Widget? header,
    Widget? bottomRight,
    Duration seekTo = Duration.zero,
  }) async {
    this.header = header;
    this.bottomRight = bottomRight;
    setDataSource(
      dataSource,
      autoplay: autoplay,
      looping: looping,
      seekTo: seekTo,
    );
    if (isDesktop) {
      registerHotKeys();
    }
    if (!isDesktop) {
      getUserPreferenceForBrightness();
    }
    await goToFullscreen(context);
  }

  /// dispose the video_player controller
  Future<void> dispose([AsyncCallback? restoreHotkeysCallback]) async {
    if (isDesktop) {
      _timer?.cancel();
      _timerForVolume?.cancel();
      _timerForGettingVolume?.cancel();
      timerForTrackingMouse?.cancel();
      _timerForSeek?.cancel();
      videoFitChangedTimer?.cancel();

      _position.close();
      _playerEventSubs?.cancel();
      _sliderPosition.close();
      _duration.close();
      _buffered.close();
      _closedCaptionEnabled.close();
      _mute.close();
      _fullscreen.close();
      _showControls.close();
      HotKeyManager.instance
          .unregisterAll()
          .then((value) => restoreHotkeysCallback?.call());
      playerStatus.status.close();
      dataStatus.status.close();
      removeWindowsListener();
      _videoPlayerControllerWindows?.dispose();
      _videoPlayerControllerWindows = null;
    } else {
      if (_videoPlayerController != null) {
        _timer?.cancel();
        _timerForVolume?.cancel();
        _timerForGettingVolume?.cancel();
        timerForTrackingMouse?.cancel();
        _timerForSeek?.cancel();
        videoFitChangedTimer?.cancel();
        _position.close();
        _playerEventSubs?.cancel();
        _sliderPosition.close();
        _duration.close();
        _buffered.close();
        _closedCaptionEnabled.close();
        _mute.close();
        _fullscreen.close();
        _showControls.close();
        playerStatus.status.close();
        dataStatus.status.close();
        _videoPlayerController?.removeListener(_listener);
        await _videoPlayerController?.dispose();
        _videoPlayerController = null;
      }
    }
  }

  /// enable or diable the visibility of ClosedCaptionFile
  void onClosedCaptionEnabled(bool enabled) {
    _closedCaptionEnabled.value = enabled;
  }

  Future<void> setUserPreferenceForFit() async {
    prefs = await SharedPreferences.getInstance();
    await prefs?.setString('fit', _videoFit.value.name);
  }

  Future<void> getUserPreferenceForFit() async {
    prefs = await SharedPreferences.getInstance();
    String fitValue = (prefs?.getString('fit')) ?? 'fill';
    _videoFit.value = fits.firstWhere((element) => element.name == fitValue);
    if (kDebugMode) print('Last fit used was ${_videoFit.value.name}');
  }

  Future<void> setUserPreferenceForBrightness() async {
    prefs = await SharedPreferences.getInstance();
    await prefs?.setDouble('brightness', brightness.value);
  }

  Future<void> getUserPreferenceForBrightness() async {
    prefs = await SharedPreferences.getInstance();
    double brightnessValue = (prefs?.getDouble('brightness')) ?? 0.5;
    setBrightness(brightnessValue);
    if (kDebugMode) print('Last Brightness used was $brightnessValue');
  }

  /// Toggle Change the videofit accordingly
  void toggleVideoFit() {
    videoFitChangedTimer?.cancel();
    videoFitChanged.value = true;
    if (fits.indexOf(_videoFit.value) < fits.length - 1) {
      _videoFit.value = fits[fits.indexOf(_videoFit.value) + 1];
    } else {
      _videoFit.value = fits[0];
    }
    if (kDebugMode) print(_videoFit.value);
    videoFitChangedTimer = Timer(const Duration(seconds: 1), () {
      if (kDebugMode) print('hidden videoFit Changed');
      videoFitChangedTimer = null;
      videoFitChanged.value = false;
      setUserPreferenceForFit();
    });
  }

  /// Change Video Fit accordingly
  void onVideoFitChange(BoxFit fit) {
    _videoFit.value = fit;
  }

  Future<void> videoSeekToNextSeconds(int seconds, bool playing) async {
    int position = 0;
    if (isDesktop) {
      position = _videoPlayerControllerWindows!.position.position!.inSeconds;
    } else {
      position = _videoPlayerController!.value.position.inSeconds;
    }
    await seekTo(Duration(seconds: position + seconds));
    if (playing) {
      await play();
    }
  }

  Future<void> fullScreenClosed([AsyncCallback? restoreHotkeysCallback]) async {
    if (kDebugMode) print('Video player closed');
    fullscreen.value = false;
    if (isDesktop) {
      screenManager.setWindowsFullScreen(false, this);
      HotKeyManager.instance
          .unregisterAll()
          .then((value) => restoreHotkeysCallback?.call());
    } else {
      screenManager.setDefaultOverlaysAndOrientations();
    }
  }

  Future<void> videoPlayerClosed(
      [AsyncCallback? restoreHotkeysCallback]) async {
    if (kDebugMode) print('Video player closed');
    fullscreen.value = false;
    resetBrightness();
    if (isDesktop) {
      screenManager.setWindowsFullScreen(false, this);
      HotKeyManager.instance
          .unregisterAll()
          .then((value) => restoreHotkeysCallback?.call());
    } else {
      screenManager.setDefaultOverlaysAndOrientations();
    }
    _timer?.cancel();
    _timerForVolume?.cancel();
    _timerForGettingVolume?.cancel();
    timerForTrackingMouse?.cancel();
    _timerForSeek?.cancel();
    videoFitChangedTimer?.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _position.value = Duration.zero;
      _timer?.cancel();
      pause();
      Wakelock.disable();
      if (isDesktop) {
        removeWindowsListener();
        _videoPlayerControllerWindows?.dispose();
        _videoPlayerControllerWindows = null;
      } else {
        _videoPlayerController?.removeListener(_listener);
        await _videoPlayerController?.dispose();
        _videoPlayerController = null;
      }
      //disposeVideoPlayerController();
      if (onVideoPlayerClosed != null) {
        if (kDebugMode) print('Called');
        onVideoPlayerClosed!();
      } else {
        if (kDebugMode) print('Didnt get Called');
      }
    });
  }

  static FlutterVideoPlayerController of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<FlutterVideoPlayerProvider>()!
        .controller;
  }
}
