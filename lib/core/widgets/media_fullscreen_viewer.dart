import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'app_video_player.dart';

bool mediaUrlLooksLikeVideo(String url) {
  final lower = url.toLowerCase();
  return lower.contains('.mp4') ||
      lower.contains('.mov') ||
      lower.contains('.m4v') ||
      lower.contains('.webm') ||
      lower.contains('/video/');
}

Future<void> openNetworkMediaViewer(
  BuildContext context, {
  required List<String> urls,
  int initialIndex = 0,
  bool isVideo = false,
}) {
  final cleaned = urls.where((u) => u.startsWith('http')).toList();
  if (cleaned.isEmpty) return Future.value();
  return Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (_, __, ___) => _FullscreenMediaPage(
        networkUrls: cleaned,
        initialIndex: initialIndex.clamp(0, cleaned.length - 1),
        forceVideo: isVideo,
      ),
    ),
  );
}

Future<void> openLocalMediaViewer(
  BuildContext context, {
  required List<File> files,
  int initialIndex = 0,
  bool isVideo = false,
}) {
  if (files.isEmpty) return Future.value();
  return Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (_, __, ___) => _FullscreenMediaPage(
        localFiles: files,
        initialIndex: initialIndex.clamp(0, files.length - 1),
        forceVideo: isVideo,
      ),
    ),
  );
}

class _FullscreenMediaPage extends StatefulWidget {
  const _FullscreenMediaPage({
    this.networkUrls = const [],
    this.localFiles = const [],
    this.initialIndex = 0,
    this.forceVideo = false,
  });

  final List<String> networkUrls;
  final List<File> localFiles;
  final int initialIndex;
  final bool forceVideo;

  @override
  State<_FullscreenMediaPage> createState() => _FullscreenMediaPageState();
}

class _FullscreenMediaPageState extends State<_FullscreenMediaPage> {
  late final PageController _controller;
  late int _index;

  bool get _isNetwork => widget.networkUrls.isNotEmpty;
  int get _count =>
      _isNetwork ? widget.networkUrls.length : widget.localFiles.length;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _itemIsVideo(int i) {
    if (widget.forceVideo) return true;
    if (_isNetwork) return mediaUrlLooksLikeVideo(widget.networkUrls[i]);
    final path = widget.localFiles[i].path.toLowerCase();
    return path.endsWith('.mp4') ||
        path.endsWith('.mov') ||
        path.endsWith('.m4v') ||
        path.endsWith('.webm');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: _count,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                if (_itemIsVideo(i)) {
                  if (_isNetwork) {
                    return Center(
                      child: AppVideoPlayer.network(
                        url: widget.networkUrls[i],
                        width: MediaQuery.sizeOf(context).width,
                        height: MediaQuery.sizeOf(context).height * 0.8,
                        borderRadius: 0,
                        fit: BoxFit.contain,
                        showControls: true,
                        autoPlay: true,
                      ),
                    );
                  }
                  return Center(
                    child: AppVideoPlayer.file(
                      file: widget.localFiles[i],
                      width: MediaQuery.sizeOf(context).width,
                      height: MediaQuery.sizeOf(context).height * 0.8,
                      borderRadius: 0,
                      fit: BoxFit.contain,
                      showControls: true,
                      autoPlay: true,
                    ),
                  );
                }

                if (_isNetwork) {
                  return InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Center(
                      child: CachedNetworkImage(
                        imageUrl: widget.networkUrls[i],
                        fit: BoxFit.contain,
                        placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                        errorWidget: (_, __, ___) => const Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white54,
                          size: 48,
                        ),
                      ),
                    ),
                  );
                }

                return InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Center(
                    child: Image.file(
                      widget.localFiles[i],
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
            if (_count > 1)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Text(
                  '${_index + 1} / $_count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
