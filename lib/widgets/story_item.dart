// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../controller/story_controller.dart';
import '../painter/indicator_oval.dart';
import 'story_image.dart';
import 'story_video.dart';
import 'story_view.dart';

/// This is a representation of a story item (or page).
class StoryItem {
  /// Specifies how long the page should be displayed. It should be a reasonable
  /// amount of time greater than 0 milliseconds.
  final Duration duration;

  /// Has this page been shown already? This is used to indicate that the page
  /// has been displayed. If some pages are supposed to be skipped in a story,
  /// mark them as shown `shown = true`.
  ///
  /// However, during initialization of the story view, all pages after the
  /// last unshown page will have their `shown` attribute altered to false. This
  /// is because the next item to be displayed is taken by the last unshown
  /// story item.
  bool shown;

  /// The page content
  final Widget view;
  StoryItem(
    this.view, {
    required this.duration,
    this.shown = false,
  });

  /// Short hand to create text-only page.
  ///
  /// [title] is the text to be displayed on [backgroundColor]. The text color
  /// alternates between [Colors.black] and [Colors.white] depending on the
  /// calculated contrast. This is to ensure readability of text.
  ///
  /// Works for inline and full-page stories. See [StoryView.inline] for more on
  /// what inline/full-page means.
  static StoryItem text({
    required String title,
    required Color backgroundColor,
    Key? key,
    TextStyle? textStyle,
    bool shown = false,
    bool roundedTop = false,
    bool roundedBottom = false,
    EdgeInsetsGeometry? textOuterPadding,
    Duration? duration,
  }) {
    double contrast = ContrastHelper.contrast(
      [backgroundColor.red, backgroundColor.green, backgroundColor.blue],
      [255, 255, 255] /** white text */,
    );

    return StoryItem(
      Container(
        key: key,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(roundedTop ? 8 : 0),
            bottom: Radius.circular(roundedBottom ? 8 : 0),
          ),
        ),
        padding: textOuterPadding ??
            const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Center(
          child: Text(
            title,
            style: textStyle?.copyWith(
                  color: contrast > 1.8 ? Colors.white : Colors.black,
                ) ??
                TextStyle(
                  color: contrast > 1.8 ? Colors.white : Colors.black,
                  fontSize: 18,
                ),
            textAlign: TextAlign.center,
          ),
        ),
        //color: backgroundColor,
      ),
      shown: shown,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// Factory constructor for page images. [controller] should be same instance as
  /// one passed to the `StoryView`
  factory StoryItem.pageImage({
    required String url,
    required StoryController controller,
    Key? key,
    BoxFit imageFit = BoxFit.fitWidth,
    Text? caption,
    bool shown = false,
    Map<String, dynamic>? requestHeaders,
    Widget? loadingWidget,
    Widget? errorWidget,
    EdgeInsetsGeometry? captionOuterPadding,
    Duration? duration,
  }) {
    return StoryItem(
      Container(
        key: key,
        color: Colors.black,
        child: Stack(
          children: <Widget>[
            StoryImage.url(
              url,
              controller: controller,
              fit: imageFit,
              requestHeaders: requestHeaders,
              loadingWidget: loadingWidget,
              errorWidget: errorWidget,
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(
                    bottom: 24,
                  ),
                  padding: captionOuterPadding ??
                      const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                  color: caption != null ? Colors.black54 : Colors.transparent,
                  child: caption ?? const SizedBox.shrink(),
                ),
              ),
            )
          ],
        ),
      ),
      shown: shown,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// Shorthand for creating inline image. [controller] should be same instance as
  /// one passed to the `StoryView`
  factory StoryItem.inlineImage({
    required String url,
    Text? caption,
    required StoryController controller,
    Key? key,
    BoxFit imageFit = BoxFit.cover,
    Map<String, dynamic>? requestHeaders,
    bool shown = false,
    bool roundedTop = true,
    bool roundedBottom = false,
    Widget? loadingWidget,
    Widget? errorWidget,
    EdgeInsetsGeometry? captionOuterPadding,
    Duration? duration,
    Widget? bottom,
  }) {
    return StoryItem(
      Center(
        child: ClipRRect(
          key: key,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(roundedTop ? 8 : 0),
            bottom: Radius.circular(roundedBottom ? 8 : 0),
          ),
          child: Container(
            color: Colors.grey[100],
            child: Container(
              color: Colors.black,
              child: Stack(
                children: <Widget>[
                  Center(
                    child: StoryImage.url(
                      url,
                      controller: controller,
                      fit: imageFit,
                      requestHeaders: requestHeaders,
                      loadingWidget: loadingWidget,
                      errorWidget: errorWidget,
                    ),
                  ),
                  if (caption != null)
                    SafeArea(
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 70),
                        padding: captionOuterPadding ??
                            const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 8,
                            ),
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: SizedBox(
                            width: double.infinity,
                            child: caption,
                          ),
                        ),
                      ),
                    ),
                  bottom ?? const SizedBox.shrink(),
                ],
              ),
            ),
          ),
        ),
      ),
      shown: shown,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// Shorthand for creating page video. [controller] should be same instance as
  /// one passed to the `StoryView`
  factory StoryItem.pageVideo(
    String url, {
    required StoryController controller,
    Key? key,
    Duration? duration,
    BoxFit imageFit = BoxFit.fitWidth,
    Widget? caption,
    bool shown = false,
    Map<String, dynamic>? requestHeaders,
    Widget? loadingWidget,
    Widget? errorWidget,
    Widget? bottom,
    required bool looping,
    required bool showControlsOnInit,
    required bool fullScreen,
  }) {
    return StoryItem(
      Center(
        child: Container(
          key: key,
          color: Colors.black,
          child: Stack(
            children: <Widget>[
              Center(
                child: StoryVideo.url(
                  url,
                  controller: controller,
                  requestHeaders: requestHeaders,
                  loadingWidget: loadingWidget,
                  errorWidget: errorWidget,
                  looping: looping,
                  showControlsOnInit: showControlsOnInit,
                  fullScreen: fullScreen,
                ),
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 24),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    color:
                        caption != null ? Colors.black54 : Colors.transparent,
                    child: caption ?? const SizedBox.shrink(),
                  ),
                ),
              ),
              bottom ?? const SizedBox.shrink(),
            ],
          ),
        ),
      ),
      shown: shown,
      duration: duration ?? const Duration(seconds: 10),
    );
  }

  /// Shorthand for creating a story item from an image provider such as `AssetImage`
  /// or `NetworkImage`. However, the story continues to play while the image loads
  /// up.
  factory StoryItem.pageProviderImage(
    ImageProvider image, {
    Key? key,
    BoxFit imageFit = BoxFit.fitWidth,
    String? caption,
    bool shown = false,
    Duration? duration,
  }) {
    return StoryItem(
        Container(
          key: key,
          color: Colors.black,
          child: Stack(
            children: <Widget>[
              Center(
                child: Image(
                  image: image,
                  height: double.infinity,
                  width: double.infinity,
                  fit: imageFit,
                ),
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(
                      bottom: 24,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    color:
                        caption != null ? Colors.black54 : Colors.transparent,
                    child: caption != null
                        ? Text(
                            caption,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          )
                        : const SizedBox(),
                  ),
                ),
              )
            ],
          ),
        ),
        shown: shown,
        duration: duration ?? const Duration(seconds: 3));
  }

  /// Shorthand for creating an inline story item from an image provider such as `AssetImage`
  /// or `NetworkImage`. However, the story continues to play while the image loads
  /// up.
  factory StoryItem.inlineProviderImage(
    ImageProvider image, {
    Key? key,
    Text? caption,
    bool shown = false,
    bool roundedTop = true,
    bool roundedBottom = false,
    Duration? duration,
  }) {
    return StoryItem(
      Container(
        key: key,
        decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(roundedTop ? 8 : 0),
              bottom: Radius.circular(roundedBottom ? 8 : 0),
            ),
            image: DecorationImage(
              image: image,
              fit: BoxFit.cover,
            )),
        child: Container(
          margin: const EdgeInsets.only(
            bottom: 16,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 8,
          ),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: SizedBox(
              width: double.infinity,
              child: caption ?? const SizedBox(),
            ),
          ),
        ),
      ),
      shown: shown,
      duration: duration ?? const Duration(seconds: 3),
    );
  }
}
