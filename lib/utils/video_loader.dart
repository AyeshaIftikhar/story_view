import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/file.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../utils.dart';

class VideoLoader {
  String url;
  File? videoFile;
  bool isHLS = false;

  Map<String, dynamic>? requestHeaders;

  LoadState state = LoadState.loading;

  VideoLoader(this.url, this.isHLS, {this.requestHeaders});

  void loadVideo(VoidCallback onComplete) {
    state = LoadState.loading;
    debugPrint('fetcheed url: $url');
    debugPrint('isHLS: $isHLS');
    // Check if the URL is an HLS stream
    if (isHLS) {
      state = LoadState.success;
      onComplete();
      return;
    }

    if (videoFile != null) {
      state = LoadState.success;
      onComplete();
    }

    final fileStream = DefaultCacheManager().getFileStream(
      url,
      headers: requestHeaders as Map<String, String>?,
    );

    fileStream.listen((fileResponse) {
      if (fileResponse is FileInfo) {
        if (videoFile == null) {
          state = LoadState.success;
          videoFile = fileResponse.file;
          onComplete();
        }
      }
    });
  }
}
