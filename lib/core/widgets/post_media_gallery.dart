import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_video_player.dart';
import 'media_fullscreen_viewer.dart';

/// Post detail media: video player or swipeable image gallery (no crop).
class PostMediaGallery extends StatefulWidget {
  const PostMediaGallery({
    super.key,
    required this.urls,
    this.isVideo = false,
    this.height = 260,
  });

  final List<String> urls;
  final bool isVideo;
  final double height;

  @override
  State<PostMediaGallery> createState() => _PostMediaGalleryState();
}

class _PostMediaGalleryState extends State<PostMediaGallery> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<String> get _urls =>
      widget.urls.where((u) => u.startsWith('http')).toList();

  Future<void> _openFull(int index) {
    return openNetworkMediaViewer(
      context,
      urls: _urls,
      initialIndex: index,
      isVideo: widget.isVideo,
    );
  }

  @override
  Widget build(BuildContext context) {
    final urls = _urls;
    if (urls.isEmpty) return const SizedBox.shrink();

    final video = widget.isVideo || mediaUrlLooksLikeVideo(urls.first);

    if (video) {
      return GestureDetector(
        onTap: () => _openFull(0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: ColoredBox(
            color: Colors.black,
            child: AppVideoPlayer.network(
              url: urls.first,
              width: double.infinity,
              height: widget.height,
              borderRadius: 18,
              fit: BoxFit.contain,
              showControls: true,
              onExpand: () => _openFull(0),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: ColoredBox(
            color: AppColors.gray100,
            child: SizedBox(
              height: widget.height,
              child: PageView.builder(
                controller: _controller,
                itemCount: urls.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => _openFull(i),
                  child: _ImagePage(url: urls[i], height: widget.height),
                ),
              ),
            ),
          ),
        ),
        if (urls.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < urls.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _index ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _index ? AppColors.primary : AppColors.gray300,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${_index + 1} / ${urls.length}',
            style: const TextStyle(fontSize: 12, color: AppColors.gray500),
          ),
        ],
      ],
    );
  }
}

class _ImagePage extends StatelessWidget {
  const _ImagePage({required this.url, required this.height});

  final String url;
  final double height;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      width: double.infinity,
      height: height,
      fit: BoxFit.contain,
      placeholder: (_, __) => Container(
        height: height,
        color: AppColors.gray100,
        alignment: Alignment.center,
        child: const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (_, __, ___) => Container(
        height: height,
        color: AppColors.gray100,
        child: const Icon(
          Icons.image_outlined,
          color: AppColors.gray400,
          size: 40,
        ),
      ),
    );
  }
}
