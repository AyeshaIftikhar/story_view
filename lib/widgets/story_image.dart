import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../utils.dart';
import '../controller/story_controller.dart';
import '../utils/image_loader.dart';

/// Widget to display animated gifs or still images. Shows a loader while image
/// is being loaded. Listens to playback states from [controller] to pause and
/// forward animated media.
class StoryImage extends StatefulWidget {
  final ImageLoader imageLoader;

  final BoxFit? fit;

  final StoryController? controller;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  StoryImage(
    this.imageLoader, {
    Key? key,
    this.controller,
    this.fit,
    this.loadingWidget,
    this.errorWidget,
  }) : super(key: key ?? UniqueKey());

  /// Use this shorthand to fetch images/gifs from the provided [url]
  factory StoryImage.url(
    String url, {
    StoryController? controller,
    Map<String, dynamic>? requestHeaders,
    BoxFit fit = BoxFit.fitWidth,
    Widget? loadingWidget,
    Widget? errorWidget,
    Key? key,
  }) {
    return StoryImage(
      ImageLoader(url, requestHeaders: requestHeaders),
      controller: controller,
      fit: fit,
      loadingWidget: loadingWidget,
      errorWidget: errorWidget,
      key: key,
    );
  }

  @override
  State<StatefulWidget> createState() => StoryImageState();
}

class StoryImageState extends State<StoryImage> {
  ui.Image? currentFrame;

  Timer? _timer;

  StreamSubscription<PlaybackState>? _streamSubscription;

  @override
  void initState() {
    super.initState();

    if (widget.controller != null) {
      _streamSubscription =
          widget.controller!.playbackNotifier.listen((playbackState) {
        // for the case of gifs we need to pause/play
        if (widget.imageLoader.frames == null) {
          return;
        }

        if (playbackState == PlaybackState.pause) {
          _timer?.cancel();
        } else {
          forward();
        }
      });
    }

    widget.controller?.pause();

    widget.imageLoader.loadImage(() async {
      if (mounted) {
        if (widget.imageLoader.state == LoadState.success) {
          widget.controller?.play();
          forward();
        } else {
          // refresh to show error
          if (mounted) setState(() {});
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _streamSubscription?.cancel();

    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  void forward() async {
    _timer?.cancel();

    if (widget.controller != null &&
        widget.controller!.playbackNotifier.stream.value ==
            PlaybackState.pause) {
      return;
    }

    final nextFrame = await widget.imageLoader.frames!.getNextFrame();

    currentFrame = nextFrame.image;

    if (nextFrame.duration > const Duration(milliseconds: 0)) {
      _timer = Timer(nextFrame.duration, forward);
    }

    if (mounted) setState(() {});
  }

  Widget getContentView() {
    switch (widget.imageLoader.state) {
      case LoadState.success:
        return Center(child: RawImage(image: currentFrame, fit: widget.fit));
      case LoadState.failure:
        return Center(
          child: widget.errorWidget ??
              const Text(
                "Image failed to load.",
                style: TextStyle(color: Colors.white),
              ),
        );
      default:
        return Center(
          child: widget.loadingWidget ??
              const SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Center(child: getContentView()),
    );
  }
}
