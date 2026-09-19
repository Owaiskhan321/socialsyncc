import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../theme/app_colors.dart';

/// Plays a local file or remote network video with optional play overlay.
class AppVideoPlayer extends StatefulWidget {
  const AppVideoPlayer.file({
    super.key,
    required this.file,
    this.width,
    this.height,
    this.borderRadius = 12,
    this.autoPlay = false,
    this.showControls = true,
    this.fit = BoxFit.contain,
    this.onExpand,
  }) : networkUrl = null;

  const AppVideoPlayer.network({
    super.key,
    required String url,
    this.width,
    this.height,
    this.borderRadius = 12,
    this.autoPlay = false,
    this.showControls = true,
    this.fit = BoxFit.contain,
    this.onExpand,
  })  : networkUrl = url,
        file = null;

  final File? file;
  final String? networkUrl;
  final double? width;
  final double? height;
  final double borderRadius;
  final bool autoPlay;
  final bool showControls;
  final BoxFit fit;
  final VoidCallback? onExpand;

  @override
  State<AppVideoPlayer> createState() => _AppVideoPlayerState();
}

class _AppVideoPlayerState extends State<AppVideoPlayer> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant AppVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldKey = oldWidget.file?.path ?? oldWidget.networkUrl;
    final newKey = widget.file?.path ?? widget.networkUrl;
    if (oldKey != newKey) {
      _disposeController();
      _init();
    }
  }

  Future<void> _init() async {
    setState(() {
      _ready = false;
      _failed = false;
    });
    try {
      final VideoPlayerController controller;
      if (widget.file != null) {
        controller = VideoPlayerController.file(widget.file!);
      } else if (widget.networkUrl != null && widget.networkUrl!.isNotEmpty) {
        controller = VideoPlayerController.networkUrl(
          Uri.parse(widget.networkUrl!),
        );
      } else {
        setState(() => _failed = true);
        return;
      }
      _controller = controller;
      await controller.initialize();
      await controller.setLooping(true);
      if (widget.autoPlay) {
        await controller.play();
      } else {
        await controller.seekTo(const Duration(milliseconds: 80));
      }
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  Future<void> _toggle() async {
    final c = _controller;
    if (c == null || !_ready) return;
    if (c.value.isPlaying) {
      await c.pause();
    } else {
      await c.play();
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.width;
    final h = widget.height;

    if (_failed) {
      return _box(
        width: w,
        height: h,
        child: const Icon(Icons.videocam_off_rounded, color: AppColors.gray500),
      );
    }

    if (!_ready || _controller == null) {
      return _box(
        width: w,
        height: h,
        child: const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final c = _controller!;
    final playing = c.value.isPlaying;
    final size = c.value.size;
    final vw = size.width <= 0 ? 16.0 : size.width;
    final vh = size.height <= 0 ? 9.0 : size.height;

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: SizedBox(
        width: w,
        height: h,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: Colors.black,
              child: FittedBox(
                fit: widget.fit,
                child: SizedBox(
                  width: vw,
                  height: vh,
                  child: VideoPlayer(c),
                ),
              ),
            ),
            if (widget.showControls)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _toggle,
                  onLongPress: widget.onExpand,
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: playing ? 0 : 1,
                      duration: const Duration(milliseconds: 150),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (widget.onExpand != null)
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: widget.onExpand,
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.fullscreen_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _box({
    required double? width,
    required double? height,
    required Widget child,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.gray200,
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

/// Compact video tile for lists (no auto-init heavy player).
class VideoMediaPlaceholder extends StatelessWidget {
  const VideoMediaPlaceholder({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 12,
  });

  final double? width;
  final double? height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.gray200,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: const Center(
        child: Icon(Icons.play_circle_fill_rounded, color: AppColors.gray500, size: 36),
      ),
    );
  }
}
