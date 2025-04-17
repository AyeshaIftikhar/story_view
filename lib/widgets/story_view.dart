import 'dart:async';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/material.dart';

import '../controller/story_controller.dart';
import '../enums/indicator.dart';
import '../enums/progress.dart';
import '../model/page_data.dart';
import '../utils.dart';
import 'pagebar.dart';
import 'story_item.dart';

/// Widget to display stories just like Whatsapp and Instagram. Can also be used
/// inline/inside [ListView] or [Column] just like Google News app. Comes with
/// gestures to pause, forward and go to previous page.
class StoryView extends StatefulWidget {
  /// The pages to displayed.
  final List<StoryItem?> storyItems;

  /// Callback for when a full cycle of story is shown. This will be called
  /// each time the full story completes when [repeat] is set to `true`.
  final VoidCallback? onComplete;

  /// Callback for when a vertical swipe gesture is detected. If you do not
  /// want to listen to such event, do not provide it. For instance,
  /// for inline stories inside ListViews, it is preferrable to not to
  /// provide this callback so as to enable scroll events on the list view.
  final Function(Direction?)? onVerticalSwipeComplete;

  /// Callback for when a story and it index is currently being shown.
  final void Function(StoryItem storyItem, int index)? onStoryShow;

  /// Where the progress indicator should be placed.
  final ProgressPosition progressPosition;

  /// Should the story be repeated forever?
  final bool repeat;

  /// If you would like to display the story as full-page, then set this to
  /// `false`. But in case you would display this as part of a page (eg. in
  /// a [ListView] or [Column]) then set this to `true`.
  final bool inline;

  /// Controls the playback of the stories
  final StoryController controller;

  /// Indicator Color
  final Color? indicatorColor;

  /// Indicator Foreground Color
  final Color? indicatorForegroundColor;

  /// Determine the height of the indicator
  final IndicatorHeight indicatorHeight;

  /// Use this if you want to give outer padding to the indicator
  final EdgeInsetsGeometry indicatorOuterPadding;

  /// Callback for when the story changes.
  final void Function(StoryItem storyItem, int index)? onChanged;

  const StoryView({
    Key? key,
    required this.storyItems,
    required this.controller,
    this.onChanged,
    this.onComplete,
    this.onStoryShow,
    this.progressPosition = ProgressPosition.top,
    this.repeat = false,
    this.inline = false,
    this.onVerticalSwipeComplete,
    this.indicatorColor,
    this.indicatorForegroundColor,
    this.indicatorHeight = IndicatorHeight.large,
    this.indicatorOuterPadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 8,
    ),
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return StoryViewState();
  }
}

class StoryViewState extends State<StoryView> with TickerProviderStateMixin {
  AnimationController? _animationController;
  Animation<double>? _currentAnimation;
  Timer? _nextDebouncer;

  StreamSubscription<PlaybackState>? _playbackSubscription;

  VerticalDragInfo? verticalDragInfo;

  StoryItem? get _currentStory {
    return widget.storyItems.firstWhereOrNull((it) => !it!.shown);
  }

  Widget get _currentView {
    var item = widget.storyItems.firstWhereOrNull((it) => !it!.shown);
    item ??= widget.storyItems.last;
    return item?.view ?? Container();
  }

  @override
  void initState() {
    super.initState();

    // All pages after the first unshown page should have their shown value as
    // false
    final firstPage = widget.storyItems.firstWhereOrNull((it) => !it!.shown);
    if (firstPage == null) {
      for (var it2 in widget.storyItems) {
        it2!.shown = false;
      }
    } else {
      final lastShownPos = widget.storyItems.indexOf(firstPage);
      widget.storyItems.sublist(lastShownPos).forEach((it) {
        it!.shown = false;
      });
    }

    _playbackSubscription =
        widget.controller.playbackNotifier.listen((playbackStatus) {
      switch (playbackStatus) {
        case PlaybackState.play:
          _removeNextHold();
          _animationController?.forward();
          break;

        case PlaybackState.pause:
          _holdNext(); // then pause animation
          _animationController?.stop(canceled: false);
          break;

        case PlaybackState.next:
          _removeNextHold();
          _goForward();
          break;

        case PlaybackState.previous:
          _removeNextHold();
          _goBack();
          break;
      }
    });

    _play();
  }

  @override
  void dispose() {
    _clearDebouncer();

    _animationController?.dispose();
    _playbackSubscription?.cancel();

    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  void _play() {
    _animationController?.dispose();
    // get the next playing page
    final storyItem = widget.storyItems.firstWhere((it) {
      return !it!.shown;
    })!;

    final storyItemIndex = widget.storyItems.indexOf(storyItem);

    if (widget.onStoryShow != null) {
      widget.onStoryShow!(storyItem, storyItemIndex);
    }
    // Trigger the onChanged callback
    if (widget.onChanged != null) {
      widget.onChanged!(storyItem, storyItemIndex);
    }

    _animationController =
        AnimationController(duration: storyItem.duration, vsync: this);

    _animationController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        storyItem.shown = true;
        if (widget.storyItems.last != storyItem) {
          _beginPlay();
        } else {
          // done playing
          _onComplete();
        }
      }
    });

    _currentAnimation =
        Tween(begin: 0.0, end: 1.0).animate(_animationController!);

    widget.controller.play();
  }

  void _beginPlay() {
    if (mounted) setState(() {});
    _play();
  }

  void _onComplete() {
    if (widget.onComplete != null) {
      widget.controller.pause();
      widget.onComplete!();
    }

    if (widget.repeat) {
      for (var it in widget.storyItems) {
        it!.shown = false;
      }

      _beginPlay();
    }
  }

  void _goBack() {
    _animationController!.stop();

    if (_currentStory == null) {
      widget.storyItems.last!.shown = false;
    }

    if (_currentStory == widget.storyItems.first) {
      _beginPlay();
    } else {
      _currentStory!.shown = false;
      int lastPos = widget.storyItems.indexOf(_currentStory);
      final previous = widget.storyItems[lastPos - 1]!;

      previous.shown = false;

      _beginPlay();
    }
  }

  void _goForward() {
    if (_currentStory != widget.storyItems.last) {
      _animationController!.stop();

      // get last showing
      final _last = _currentStory;

      if (_last != null) {
        _last.shown = true;
        if (_last != widget.storyItems.last) {
          _beginPlay();
        }
      }
    } else {
      // this is the last page, progress animation should skip to end
      _animationController!
          .animateTo(1.0, duration: const Duration(milliseconds: 10));
    }
  }

  void _clearDebouncer() {
    _nextDebouncer?.cancel();
    _nextDebouncer = null;
  }

  void _removeNextHold() {
    _nextDebouncer?.cancel();
    _nextDebouncer = null;
  }

  void _holdNext() {
    _nextDebouncer?.cancel();
    _nextDebouncer = Timer(const Duration(milliseconds: 500), () {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Stack(
        children: <Widget>[
          _currentView,
          Visibility(
            visible: widget.progressPosition != ProgressPosition.none,
            child: Align(
              alignment: widget.progressPosition == ProgressPosition.top
                  ? Alignment.topCenter
                  : Alignment.bottomCenter,
              child: SafeArea(
                bottom: widget.inline ? false : true,
                // we use SafeArea here for notched and bezeles phones
                child: Container(
                  padding: widget.indicatorOuterPadding,
                  child: PageBar(
                    widget.storyItems
                        .map((it) => PageData(it!.duration, it.shown))
                        .toList(),
                    _currentAnimation,
                    key: UniqueKey(),
                    indicatorHeight: widget.indicatorHeight,
                    indicatorColor: widget.indicatorColor,
                    indicatorForegroundColor: widget.indicatorForegroundColor,
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            heightFactor: 1,
            child: GestureDetector(
              onTapDown: (details) {
                widget.controller.pause();
              },
              onTapCancel: () => widget.controller.play(),
              onTapUp: (details) {
                // if debounce timed out (not active) then continue anim
                if (_nextDebouncer?.isActive == false) {
                  widget.controller.play();
                } else {
                  widget.controller.next();
                }
              },
              onVerticalDragStart: widget.onVerticalSwipeComplete == null
                  ? null
                  : (details) => widget.controller.pause(),
              onVerticalDragCancel: widget.onVerticalSwipeComplete == null
                  ? null
                  : () => widget.controller.play(),
              onVerticalDragUpdate: widget.onVerticalSwipeComplete == null
                  ? null
                  : (details) {
                      verticalDragInfo ??= VerticalDragInfo();
                      verticalDragInfo!.update(details.primaryDelta!);
                      // TODO: provide callback interface for animation purposes
                    },
              onVerticalDragEnd: widget.onVerticalSwipeComplete == null
                  ? null
                  : (details) {
                      widget.controller.play();
                      // finish up drag cycle
                      if (!verticalDragInfo!.cancel &&
                          widget.onVerticalSwipeComplete != null) {
                        widget.onVerticalSwipeComplete!(
                            verticalDragInfo!.direction);
                      }
                      verticalDragInfo = null;
                    },
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            heightFactor: 1,
            child: SizedBox(
              width: 70,
              child: GestureDetector(
                onTap: () => widget.controller.previous(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
