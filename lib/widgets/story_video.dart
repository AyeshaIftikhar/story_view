import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../utils.dart';
import '../controller/story_controller.dart';
import '../utils/video_loader.dart';

class StoryVideo extends StatefulWidget {
  final StoryController? storyController;
  final VideoLoader videoLoader;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  StoryVideo(
    this.videoLoader, {
    Key? key,
    this.storyController,
    this.loadingWidget,
    this.errorWidget,
  }) : super(key: key ?? UniqueKey());

  static StoryVideo url(
    String url, {
    StoryController? controller,
    Map<String, dynamic>? requestHeaders,
    Key? key,
    Widget? loadingWidget,
    Widget? errorWidget,
  }) {
    return StoryVideo(
      VideoLoader(
        url,
        url.endsWith('.m3u8'),
        requestHeaders: requestHeaders,
      ),
      storyController: controller,
      key: key,
      loadingWidget: loadingWidget,
      errorWidget: errorWidget,
    );
  }

  @override
  State<StatefulWidget> createState() {
    return StoryVideoState();
  }
}

class StoryVideoState extends State<StoryVideo> {
  Future<void>? playerLoader;

  StreamSubscription? _streamSubscription;

  VideoPlayerController? playerController;
  ChewieController? chewieController;

  @override
  void initState() {
    super.initState();
    initializeVideo();
  }

  initializeVideo() async {
    try {
      widget.storyController!.pause();

      widget.videoLoader.loadVideo(() async {
        if (widget.videoLoader.state == LoadState.success) {
          playerController = widget.videoLoader.isHLS
              ? VideoPlayerController.networkUrl(
                  Uri.parse(widget.videoLoader.url),
                  httpHeaders:
                      widget.videoLoader.requestHeaders as Map<String, String>,
                )
              : VideoPlayerController.file(widget.videoLoader.videoFile!);

          // Ensure the player is initialized
          await playerController!.initialize();

          // Initialize the ChewieController
          chewieController = ChewieController(
            videoPlayerController: playerController!,
            autoInitialize: true,
            autoPlay: true,
            looping: true,
            showControls: true,
          );

          // Resume the story controller playback
          widget.storyController?.play();
          debugPrint('video initialized');
          // Listen to the video player controller for playback state changes
          // and update the Chewie controller accordingly
          if (widget.storyController != null) {
            _streamSubscription = widget.storyController!.playbackNotifier
                .listen((playbackState) {
              if (playbackState == PlaybackState.pause) {
                chewieController!.videoPlayerController.pause();
              } else {
                chewieController!.videoPlayerController.play();
              }
            });
          }
          // Update the state to reflect the video initialization
          // and notify the story controller
          if (mounted) setState(() {});
          debugPrint('✅ Video initialized successfully.');
        } else {
          debugPrint('❌ Video loading failed.');
          if (mounted) setState(() {});
        }
      });
    } catch (e, trace) {
      debugPrint('❌ Error initializing video: $e');
      debugPrint('🛠 StackTrace: $trace');
    }
  }

  Widget getContentView() {
    if (widget.videoLoader.state == LoadState.success &&
        chewieController != null &&
        chewieController!.videoPlayerController.value.isInitialized) {
      return Center(
        child: AspectRatio(
          aspectRatio:
              chewieController!.videoPlayerController.value.aspectRatio,
          child: Chewie(controller: chewieController!),
        ),
      );
    }

    return widget.videoLoader.state == LoadState.loading
        ? Center(
            child: widget.loadingWidget ??
                const SizedBox(
                  width: 70,
                  height: 70,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3,
                  ),
                ),
          )
        : Center(
            child: widget.errorWidget ??
                const Text(
                  "Media failed to load.",
                  style: TextStyle(color: Colors.white),
                ),
          );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      height: double.infinity,
      width: double.infinity,
      child: Center(child: getContentView()),
    );
  }

  @override
  void dispose() {
    // Dispose of the controllers and subscriptions
    playerController?.dispose();
    chewieController?.dispose();
    _streamSubscription?.cancel();
    super.dispose();
  }
}
