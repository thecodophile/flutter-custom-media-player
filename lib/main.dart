import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_player_flutter/const.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:video_player/video_player.dart';


/// A single-file demo screen showing a simple, modern UI around
/// the `video_player` package with a dummy network video.

void main() {
  runApp(const MyApp());
}

class VideoCaption {
  VideoCaption({
    int? end,
    String? part,
    int? start,
    List<Words>? words,
  }) {
    _end = end;
    _part = part;
    _start = start;
    _words = words;
  }

  VideoCaption.fromJson(dynamic json) {
    _end = json['end'];
    _part = json['part'];
    _start = json['start'];
    if (json['words'] != null) {
      _words = [];
      json['words'].forEach((v) {
        _words?.add(Words.fromJson(v));
      });
    }
  }

  int? _end;
  String? _part;
  int? _start;
  List<Words>? _words;

  VideoCaption copyWith({
    int? end,
    String? part,
    int? start,
    List<Words>? words,
  }) =>
      VideoCaption(
        end: end ?? _end,
        part: part ?? _part,
        start: start ?? _start,
        words: words ?? _words,
      );

  int? get end => _end;

  String? get part => _part;

  int? get start => _start;

  List<Words>? get words => _words;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['end'] = _end;
    map['part'] = _part;
    map['start'] = _start;
    if (_words != null) {
      map['words'] = _words?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}
class Words {
  Words({
    String? word,
  }) {
    _word = word;
  }

  Words.fromJson(dynamic json) {
    _word = json['word'];
  }

  String? _word;

  Words copyWith({
    String? word,
  }) =>
      Words(
        word: word ?? _word,
      );

  String? get word => _word;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['word'] = _word;
    return map;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const DummyVideoPlayerScreen(),
    );
  }
}

class DummyVideoPlayerScreen extends StatefulWidget {
  const DummyVideoPlayerScreen({super.key});
  @override
  State<DummyVideoPlayerScreen> createState() => _DummyVideoPlayerScreenState();
}
class _DummyVideoPlayerScreenState extends State<DummyVideoPlayerScreen> {
  late final VideoPlayerController _controller;
  bool _showControls = true;
  double _lastVolume = 1.0;
  double _currentVolume = 1.0;
  double _speed = 1.0;
  bool _showRewind = false;
  bool _showForward = false;
  bool _isFullScreen = false;
  Timer? _hideTimer;
  List<String> videoUrls = [
    "https://player.vimeo.com/external/1062476769.m3u8?s=e7b336626183eda65586ddcdd66a4623119889b2&logging=false"
    "https://player.vimeo.com/external/472283009.m3u8?s=dd26a65748503224f15539da0e54f0cab63ec3ea&logging=false",
    // "https://www.vi-cart-api.acelance.com/uploads/alarm/alarm_1755759454856.mp3"
    // "https://peach.blender.org/wp-content/uploads/title_anouncement/BigBuckBunny_720_10MB.mp4",
    // "https://peach.blender.org/wp-content/uploads/title_anouncement/BigBuckBunny_1080_20MB.mp4",
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4",
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4",
  ];


  List<VideoCaption> _captions = []; // fetched from API


  bool _showCaptions = false;

  bool _showVolumeUI = false;
  bool _showBrightnessUI = false;

  void _toggleCaptions() {
    setState(() {
      _showCaptions = !_showCaptions;
    });
  }

  String? _getCurrentCaptionText() {
    if (!_controller.value.isInitialized || _captions.isEmpty) return null;

    final currentMs = _controller.value.position.inMilliseconds;

    for (final cap in _captions) {
      if ((cap.start ?? 0) <= currentMs && currentMs <= (cap.end ?? 0)) {
        return cap.part;
      }
    }
    return null;
  }

  void _changeVolume(double delta) {
    setState(() {
      _currentVolume = (_currentVolume + delta * 0.005).clamp(0.0, 1.0);
      _controller.setVolume(_currentVolume);
      _showVolumeUI = true;
    });
  }

  double _currentBrightness = 0.5;

  void _changeBrightness(double delta) async {
    _currentBrightness = (_currentBrightness + delta * 0.005).clamp(0.0, 1.0);
    await ScreenBrightness().setScreenBrightness(_currentBrightness);
    setState(() {
      _showBrightnessUI = true;
    });
  }

  void _toggleBrightnessUi() async {
    setState(() {
      _showBrightnessUI = !_showBrightnessUI;
    });
  }

  void _toggleVolumeUi() async {
    setState(() {
      _showVolumeUI = !_showVolumeUI;
    });
  }

  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();

    _captions = (jsonDecode(AppConstants.captionJson) as List)
        .map((item) => VideoCaption.fromJson(item))
        .toList();

    _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrls[0],),)
      ..setLooping(true)
      ..initialize().then((_) {
        _controller.play();
        if (!mounted) return;
        _controller.setVolume(_currentVolume);
        setState(() {});
        _hideTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() => _showControls = false);
          }
        });
      });
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  void _togglePlay() {
    if (!_controller.value.isInitialized) return;
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }
  void _seekBy(Duration offset, bool forward) async {
    if (!_controller.value.isInitialized) return;
    final pos = await _controller.position ?? Duration.zero;
    final dur = _controller.value.duration;
    var target = pos + offset;
    if (target < Duration.zero) target = Duration.zero;
    if (target > dur) target = dur;
    _controller.seekTo(target);
    // show effect
    setState(() {
      if (forward) {
        _showForward = true;
      } else {
        _showRewind = true;
      }
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      setState(() {
        _showForward = false;
        _showRewind = false;
      });
    });
  }
  void _toggleMute() {
    if (!_controller.value.isInitialized) return;
    setState(() {
      if (_currentVolume > 0) {
        _lastVolume = _currentVolume;
        _currentVolume = 0;
      } else {
        _currentVolume = _lastVolume == 0 ? 1.0 : _lastVolume;
      }
      _controller.setVolume(_currentVolume);
    });
  }
  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _hideTimer?.cancel();
      _hideTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _showControls = false);
        }
      });
    }
  }
  void enterFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }
  void exitFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }
  void _toggleScreen() {
    if(_isFullScreen){
      exitFullScreen();
      setState(() {
        _isFullScreen=false;
        // if full screen off then obviously zoomed in version should be off.
        _isZoomed = false;
      });
    }else {
      enterFullScreen();
      setState(() {
        _isFullScreen = true;
      });
    }
  }
  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return h > 0 ? '${two(h)}:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }
  void _skipForward() {}
  void _skipNext()  {
    // if()
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    if(_controller.value.isInitialized){
      print("Controller value -> ${_controller.value}");
    }

    return Scaffold(
      backgroundColor: Colors.black,
      // appBar:AppBar(
      //   backgroundColor: Colors.grey.shade800,
      //   centerTitle: true,
      //   foregroundColor: Colors.white,
      //   title: Text("Video Player", style: TextStyle(color: Colors.white)),
      // ),
      body: SafeArea(
        // constraints: BoxConstraints(
        //     minHeight: MediaQuery.of(context).size.height/4.5
        // ),
        child: AspectRatio(
          aspectRatio: _controller.value.isInitialized
              ? _isFullScreen? screenWidth/screenHeight : _controller.value.aspectRatio
              : 16 / 9,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Video

              _isFullScreen?
              SizedBox(
                height: screenHeight,
                width: screenWidth,
                child: FittedBox(
                  fit: _isZoomed ? BoxFit.cover : BoxFit.contain, // keeps aspect ratio
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child:  _controller.value.isInitialized
                        ? VideoPlayer(_controller)
                        : const _LoadingShimmer(),
                  ),
                ),
              ):
              _controller.value.isInitialized
                  ? VideoPlayer(_controller)
                  : const _LoadingShimmer(),

              // Tap area to toggle controls
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _toggleControls(),

                  onVerticalDragUpdate: (details) {

                    final screenWidth = MediaQuery.of(context).size.width;
                    final dx = details.globalPosition.dx;

                    if (dx < screenWidth / 2) {
                      _changeBrightness(-details.delta.dy);
                    } else {
                      _changeVolume(-details.delta.dy);
                    }
                  },

                  onVerticalDragEnd: (details){
                    final screenWidth = MediaQuery.of(context).size.width;
                    final dx = details.globalPosition.dx;

                    if (dx < screenWidth / 2) {
                      _toggleBrightnessUi();
                    } else {
                      _toggleVolumeUi();
                    }
                  },

                  child: Row(
                    children: [
                      // LEFT SIDE (Rewind)
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onDoubleTap: () => _seekBy(const Duration(seconds: -10),false),
                        ),
                      ),
                      // RIGHT SIDE (Forward)
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onDoubleTap: () => _seekBy(const Duration(seconds: 10),true),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_showRewind)
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(width: 40),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.fast_rewind,
                              color: Colors.white, size: 60),
                          // Text("-10s",
                          //     style: TextStyle(
                          //         color: Colors.white, fontSize: 22)),
                        ],
                      ),
                    ],
                  ),
                ),
              // Forward Effect
              if (_showForward)
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.fast_forward,
                              color: Colors.white, size: 60),
                          // Text("+10s",
                          //     style: TextStyle(
                          //         color: Colors.white, fontSize: 22)),
                        ],
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),

              if (_showVolumeUI)
                _VolumeOverlay(volume: _currentVolume),
              if (_showBrightnessUI)
                _BrightnessOverlay(brightness: _currentBrightness),

              // Center play/pause
              if (_showControls)
                _BlurredControls(
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 50,
                    color: Colors.white,
                    onPressed: _togglePlay,
                    icon: Icon(
                      _controller.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
                  ),
                  skipNext: (){},
                  skipPrevious: (){},
                ),
              // Bottom controls
              if (_showControls)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ValueListenableBuilder(
                            valueListenable: _controller,
                            builder: (_, __, ___) {
                              final pos = _controller.value.position;
                              final dur = _controller.value.duration;
                              String two(int n) => n.toString().padLeft(2, '0');
                              String fmt(Duration d) {
                                final h = d.inHours;
                                final m = d.inMinutes.remainder(60);
                                final s = d.inSeconds.remainder(60);
                                return h > 0
                                    ? '${two(h)}:${two(m)}:${two(s)}'
                                    : '${two(m)}:${two(s)}';
                              }
                              return Text(
                                '${fmt(pos)} / ${fmt(dur)}',
                                style: const TextStyle(color: Colors.white),
                              );
                            },
                          ),

                          _isFullScreen?
                          GestureDetector(
                              onTap: (){
                                setState(() {
                                  _isZoomed = !_isZoomed; // toggle zoom
                                });
                              },
                              child: Icon(Icons.fullscreen,color: Colors.white,))
                              :const SizedBox.shrink(),

                          GestureDetector(
                              onTap: _toggleScreen,
                              child: Icon(_isFullScreen?Icons.fullscreen_exit:
                              Icons.fullscreen,color: Colors.white,))
                        ],
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: VideoProgressIndicator(
                          _controller,
                          allowScrubbing: true,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_showControls)
                Positioned(
                  top: 0,
                  right: 15,
                  child: _ControlsBar(
                    controller: _controller,
                    // onBack: () => _seekBy(const Duration(seconds: -10)),
                    // onFwd: () => _seekBy(const Duration(seconds: 10)),
                    onPlayPause: _togglePlay,
                    onMute: _toggleMute,
                    currentVolume: _currentVolume,
                    onSpeed: (v) async {
                      _speed = v;
                      await _controller.setPlaybackSpeed(v);
                      setState(() {});
                    },
                    onToggleCaptions: _toggleCaptions,
                    showCaptions: _showCaptions,
                  ),
                ),
              Positioned( left:10,top: 10,
                  child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.arrow_back,color: Colors.white,))),


              // Show captions
              if (_showCaptions)
                Positioned(
                  bottom: 50,
                  left: 20,
                  right: 20,
                  child: ValueListenableBuilder(
                    valueListenable: _controller,
                    builder: (_, __, ___) {
                      final text = _getCurrentCaptionText();
                      if (text == null) return const SizedBox.shrink();
                      return Text(
                        text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          backgroundColor: Colors.black54,
                        ),
                      );
                    },
                  ),
                ),

            ],
          ),
        ),
      ),
    );
  }
}


class _ControlsBar extends StatelessWidget {
  const _ControlsBar({
    required this.controller,
    // required this.onBack,
    // required this.onFwd,
    required this.onPlayPause,
    required this.onMute,
    required this.onSpeed,
    required this.currentVolume,
    required this.onToggleCaptions,
    required this.showCaptions,
  });
  final VideoPlayerController controller;
  // final VoidCallback onBack;
  // final VoidCallback onFwd;
  final VoidCallback onPlayPause;
  final VoidCallback onMute;
  final ValueChanged<double> onSpeed;
  final double currentVolume;
  final VoidCallback onToggleCaptions;
  final bool showCaptions;
  @override
  Widget build(BuildContext context) {
    // final value = controller.value;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // IconButton(
            //   onPressed: onBack,
            //   icon: const Icon(Icons.replay_10, color: Colors.white),
            //   tooltip: 'Back 10s',
            // ),
            // const SizedBox(width: 8),
            // IconButton(
            //   onPressed: onFwd,
            //   icon: const Icon(Icons.forward_10, color: Colors.white),
            //   tooltip: 'Forward 10s',
            // ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onMute,
              icon: Icon(
                currentVolume == 0 ? Icons.volume_off : Icons.volume_up,
                color: Colors.white,
              ),
              tooltip: 'Mute/Unmute',
            ),
            const SizedBox(width: 8),
            PopupMenuButton<double>(
              tooltip: 'Playback speed',
              initialValue: controller.value.playbackSpeed,
              onSelected: onSpeed,
              color: Colors.white,
              itemBuilder: (context) => const [
                PopupMenuItem(value: 0.5, child: Text('0.5x')),
                PopupMenuItem(value: 1.0, child: Text('1.0x')),
                PopupMenuItem(value: 1.5, child: Text('1.5x')),
                PopupMenuItem(value: 2.0, child: Text('2.0x')),
              ],
              child: const Icon(Icons.speed, color: Colors.white),
            ),

            IconButton(
              onPressed: onToggleCaptions,
              icon: Icon(
                showCaptions ? Icons.closed_caption : Icons.closed_caption_off,
                color: Colors.white,
              ),
              tooltip: 'Toggle captions',
            ),

          ],
        ),
      ],
    );
  }
}
class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey.shade900,
            Colors.grey.shade800,
            Colors.grey.shade900,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
class _BlurredControls extends StatelessWidget {
  const _BlurredControls({required this.child,
    required this.skipNext,required this.skipPrevious});
  final Widget child;
  final Function skipPrevious;
  final Function skipNext;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.skip_previous,color: Colors.white,size: 25,),
        const SizedBox(width: 30,),
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.25),
            borderRadius: BorderRadius.circular(50),
          ),
          padding: const EdgeInsets.all(0),
          child: child,
        ),
        const SizedBox(width: 30,),
        Icon(Icons.skip_next,color: Colors.white,size: 25,),
      ],
    );
  }
}
class _VolumeOverlay extends StatelessWidget {
  final double volume;
  const _VolumeOverlay({required this.volume});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 40,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            volume > 0 ? Icons.volume_up : Icons.volume_off,
            size: 40,
            color: Colors.white,
          ),
          Text(
            '${(volume * 100).toInt()}%',
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
        ],
      ),
    );
  }
}
class _BrightnessOverlay extends StatelessWidget {
  final double brightness;
  const _BrightnessOverlay({required this.brightness});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 40,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.brightness_6, size: 40, color: Colors.white),
          Text(
            '${(brightness * 100).toInt()}%',
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
        ],
      ),
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:video_player/video_player.dart';
//
// void main() => runApp(const MyApp());
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: AudioPlayerScreen(),
//     );
//   }
// }
//
// class AudioPlayerScreen extends StatefulWidget {
//   const AudioPlayerScreen({super.key});
//
//   @override
//   State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
// }
//
// class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
//   late VideoPlayerController _controller;
//   late Future<void> _initFuture;
//
//   @override
//   void initState() {
//     super.initState();
//
//     _controller = VideoPlayerController.network(
//       "https://www.vi-cart-api.acelance.com/uploads/alarm/alarm_1755759454856.mp3"
//     );
//
//     _initFuture = _controller.initialize().then((_) {
//       _controller.play();
//     });
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("MP3 with video_player")),
//       body: Center(
//         child: FutureBuilder(
//           future: _initFuture,
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.done) {
//               // For audio, just show a dummy UI (since there's no video)
//               return Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Icon(Icons.music_note, size: 80),
//                   Text(
//                     _controller.value.isPlaying ? "Playing" : "Paused",
//                     style: const TextStyle(fontSize: 20),
//                   ),
//                 ],
//               );
//             } else {
//               return const CircularProgressIndicator();
//             }
//           },
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           setState(() {
//             _controller.value.isPlaying
//                 ? _controller.pause()
//                 : _controller.play();
//           });
//         },
//         child: Icon(
//           _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
//         ),
//       ),
//     );
//   }
// }
