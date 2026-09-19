import 'dart:io';

import 'package:flutter/material.dart';

import 'app_video_player.dart';

/// Local file video preview — thin wrapper around [AppVideoPlayer].
class LocalVideoPreview extends StatelessWidget {
  const LocalVideoPreview({
    super.key,
    required this.file,
    this.width,
    this.height,
    this.borderRadius = 12,
    this.autoPlay = false,
    this.showControls = true,
    this.fit = BoxFit.contain,
    this.onExpand,
  });

  final File file;
  final double? width;
  final double? height;
  final double borderRadius;
  final bool autoPlay;
  final bool showControls;
  final BoxFit fit;
  final VoidCallback? onExpand;

  @override
  Widget build(BuildContext context) {
    return AppVideoPlayer.file(
      file: file,
      width: width,
      height: height,
      borderRadius: borderRadius,
      autoPlay: autoPlay,
      showControls: showControls,
      fit: fit,
      onExpand: onExpand,
    );
  }
}
