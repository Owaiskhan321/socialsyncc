import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/local_video_preview.dart';
import '../../../core/widgets/media_fullscreen_viewer.dart';
import '../../../core/widgets/platform_icon.dart';
import '../../../data/repositories/app_data.dart';

/// Authentic-looking social feed preview for each platform.
class PlatformPostPreviewCard extends StatelessWidget {
  const PlatformPostPreviewCard({
    super.key,
    required this.platformId,
    required this.platformName,
    required this.accountLabel,
    required this.accountHandle,
    required this.title,
    required this.caption,
    required this.mediaFiles,
    required this.mediaIsVideo,
    required this.scheduleLabel,
  });

  final String platformId;
  final String platformName;
  final String accountLabel;
  final String accountHandle;
  final String title;
  final String caption;
  final List<File> mediaFiles;
  final bool mediaIsVideo;
  final String scheduleLabel;

  String get _displayTitle =>
      title.trim().isEmpty ? 'Untitled post' : title.trim();

  String get _displayCaption =>
      caption.trim().isEmpty ? 'No caption yet.' : caption.trim();

  String get _handle {
    final raw = accountHandle.trim();
    if (raw.isNotEmpty) return raw.replaceFirst(RegExp(r'^@'), '');
    final label = accountLabel.trim();
    if (label.isNotEmpty && label.toLowerCase() != 'your account') {
      return label.replaceFirst(RegExp(r'^@'), '');
    }
    return 'account';
  }

  @override
  Widget build(BuildContext context) {
    final data = _PreviewData(
      platformId: platformId,
      platformName: platformName,
      accountLabel: accountLabel,
      handle: _handle,
      title: _displayTitle,
      caption: _displayCaption,
      mediaFiles: mediaFiles,
      mediaIsVideo: mediaIsVideo,
      scheduleLabel: scheduleLabel,
    );

    return switch (platformId) {
      'instagram' => _InstagramCard(data: data),
      'facebook' => _FacebookCard(data: data),
      'linkedin' || 'linkedin_organization' => _LinkedInCard(data: data),
      'x' => _XCard(data: data),
      'tiktok' => _TikTokCard(data: data),
      'youtube' => _YouTubeCard(data: data),
      'pinterest' => _PinterestCard(data: data),
      'threads' => _ThreadsCard(data: data),
      'snapchat' => _SnapchatCard(data: data),
      'google' => _GoogleBusinessCard(data: data),
      _ => _GenericCard(data: data),
    };
  }
}

class _PreviewData {
  const _PreviewData({
    required this.platformId,
    required this.platformName,
    required this.accountLabel,
    required this.handle,
    required this.title,
    required this.caption,
    required this.mediaFiles,
    required this.mediaIsVideo,
    required this.scheduleLabel,
  });

  final String platformId;
  final String platformName;
  final String accountLabel;
  final String handle;
  final String title;
  final String caption;
  final List<File> mediaFiles;
  final bool mediaIsVideo;
  final String scheduleLabel;
}

// ─── Instagram ───────────────────────────────────────────────────────────────

class _InstagramCard extends StatelessWidget {
  const _InstagramCard({required this.data});
  final _PreviewData data;

  @override
  Widget build(BuildContext context) {
    return _Shell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(
              children: [
                _AvatarRing(platformId: data.platformId, size: 34),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    data.handle,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF262626),
                    ),
                  ),
                ),
                _ScheduleChip(label: data.scheduleLabel),
                const Icon(Icons.more_horiz, color: Color(0xFF262626), size: 22),
              ],
            ),
          ),
          _Media(
            files: data.mediaFiles,
            isVideo: data.mediaIsVideo,
            height: 320,
            fit: BoxFit.cover,
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(
              children: [
                FaIcon(FontAwesomeIcons.heart, size: 22, color: Color(0xFF262626)),
                SizedBox(width: 16),
                FaIcon(FontAwesomeIcons.comment, size: 22, color: Color(0xFF262626)),
                SizedBox(width: 16),
                FaIcon(FontAwesomeIcons.paperPlane, size: 20, color: Color(0xFF262626)),
                Spacer(),
                FaIcon(FontAwesomeIcons.bookmark, size: 20, color: Color(0xFF262626)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${data.handle} ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF262626),
                      fontSize: 13,
                    ),
                  ),
                  TextSpan(
                    text: data.caption,
                    style: const TextStyle(
                      color: Color(0xFF262626),
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 2, 12, 12),
            child: Text(
              'View all comments',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF8E8E8E)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Facebook ────────────────────────────────────────────────────────────────

class _FacebookCard extends StatelessWidget {
  const _FacebookCard({required this.data});
  final _PreviewData data;

  @override
  Widget build(BuildContext context) {
    return _Shell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Avatar(platformId: data.platformId, size: 40),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.accountLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF050505),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Row(
                        children: [
                          Text(
                            'Just now · ',
                            style: TextStyle(fontSize: 12, color: Color(0xFF65676B)),
                          ),
                          Icon(Icons.public, size: 12, color: Color(0xFF65676B)),
                        ],
                      ),
                    ],
                  ),
                ),
                _ScheduleChip(label: data.scheduleLabel),
                const Icon(Icons.more_horiz, color: Color(0xFF65676B)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data.title != 'Untitled post') ...[
                  Text(
                    data.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF050505),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  data.caption,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF050505),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          _Media(
            files: data.mediaFiles,
            isVideo: data.mediaIsVideo,
            height: 220,
            fit: BoxFit.cover,
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                Icon(Icons.thumb_up_alt, size: 14, color: Color(0xFF1877F2)),
                SizedBox(width: 4),
                Text('Like', style: TextStyle(fontSize: 12, color: Color(0xFF65676B))),
                Spacer(),
                Text('Comment', style: TextStyle(fontSize: 12, color: Color(0xFF65676B))),
                Spacer(),
                Text('Share', style: TextStyle(fontSize: 12, color: Color(0xFF65676B))),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE4E6EB)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                _FbAction(Icons.thumb_up_outlined, 'Like'),
                _FbAction(Icons.chat_bubble_outline, 'Comment'),
                _FbAction(Icons.share_outlined, 'Share'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FbAction extends StatelessWidget {
  const _FbAction(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF65676B)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF65676B),
          ),
        ),
      ],
    );
  }
}

// ─── LinkedIn ────────────────────────────────────────────────────────────────

class _LinkedInCard extends StatelessWidget {
  const _LinkedInCard({required this.data});
  final _PreviewData data;

  @override
  Widget build(BuildContext context) {
    return _Shell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Avatar(platformId: data.platformId, size: 48, radius: 8),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.accountLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF191919),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data.platformId == 'linkedin_organization'
                            ? 'Company · Followers'
                            : 'Professional · 1st',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Row(
                        children: [
                          Text(
                            'Just now · ',
                            style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
                          ),
                          Icon(Icons.public, size: 12, color: Color(0xFF666666)),
                        ],
                      ),
                    ],
                  ),
                ),
                _ScheduleChip(label: data.scheduleLabel),
                const Icon(Icons.more_horiz, color: Color(0xFF666666)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data.title != 'Untitled post') ...[
                  Text(
                    data.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF191919),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  data.caption,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF191919),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          _Media(
            files: data.mediaFiles,
            isVideo: data.mediaIsVideo,
            height: 200,
            fit: BoxFit.cover,
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                Text('👍 💡', style: TextStyle(fontSize: 12)),
                SizedBox(width: 4),
                Text('24', style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
                Spacer(),
                Text('3 comments', style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _LiAction(Icons.thumb_up_outlined, 'Like'),
                _LiAction(Icons.chat_bubble_outline, 'Comment'),
                _LiAction(Icons.repeat, 'Repost'),
                _LiAction(Icons.send_outlined, 'Send'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiAction extends StatelessWidget {
  const _LiAction(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF666666)),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF666666),
          ),
        ),
      ],
    );
  }
}

// ─── X (Twitter) ─────────────────────────────────────────────────────────────

class _XCard extends StatelessWidget {
  const _XCard({required this.data});
  final _PreviewData data;

  @override
  Widget build(BuildContext context) {
    return _Shell(
      borderColor: const Color(0xFFEFF3F4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Avatar(platformId: data.platformId, size: 40),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: data.accountLabel,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F1419),
                                ),
                              ),
                              TextSpan(
                                text: ' @${data.handle} · now',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF536471),
                                ),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _ScheduleChip(label: data.scheduleLabel),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data.caption,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF0F1419),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _Media(
                      files: data.mediaFiles,
                      isVideo: data.mediaIsVideo,
                      height: 190,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _XAction(Icons.chat_bubble_outline, '12'),
                      _XAction(Icons.repeat, '4'),
                      _XAction(Icons.favorite_border, '48'),
                      _XAction(Icons.bar_chart, '1.2K'),
                      Icon(Icons.share_outlined, size: 16, color: Color(0xFF536471)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _XAction extends StatelessWidget {
  const _XAction(this.icon, this.count);
  final IconData icon;
  final String count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF536471)),
        const SizedBox(width: 6),
        Text(count, style: const TextStyle(fontSize: 12, color: Color(0xFF536471))),
      ],
    );
  }
}

// ─── TikTok ──────────────────────────────────────────────────────────────────

class _TikTokCard extends StatelessWidget {
  const _TikTokCard({required this.data});
  final _PreviewData data;

  @override
  Widget build(BuildContext context) {
    return _Shell(
      color: Colors.black,
      borderColor: const Color(0xFF222222),
      child: SizedBox(
        height: 420,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _Media(
              files: data.mediaFiles,
              isVideo: data.mediaIsVideo,
              height: 420,
              fit: BoxFit.cover,
              darkPlaceholder: true,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Color(0xCC000000),
                  ],
                  stops: [0, 0.55, 1],
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: _ScheduleChip(label: data.scheduleLabel, dark: true),
            ),
            Positioned(
              right: 10,
              bottom: 90,
              child: Column(
                children: [
                  _Avatar(platformId: data.platformId, size: 44),
                  const SizedBox(height: 18),
                  const _TtSide(Icons.favorite, '24.8K'),
                  const SizedBox(height: 16),
                  const _TtSide(Icons.chat_bubble, '812'),
                  const SizedBox(height: 16),
                  const _TtSide(Icons.bookmark, '3.1K'),
                  const SizedBox(height: 16),
                  const _TtSide(Icons.share, 'Share'),
                ],
              ),
            ),
            Positioned(
              left: 12,
              right: 72,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '@${data.handle}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data.caption,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Icon(Icons.music_note, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Original sound',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TtSide extends StatelessWidget {
  const _TtSide(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
      ],
    );
  }
}

// ─── YouTube ─────────────────────────────────────────────────────────────────

class _YouTubeCard extends StatelessWidget {
  const _YouTubeCard({required this.data});
  final _PreviewData data;

  @override
  Widget build(BuildContext context) {
    return _Shell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              _Media(
                files: data.mediaFiles,
                isVideo: data.mediaIsVideo,
                height: 200,
                fit: BoxFit.cover,
              ),
              Container(
                width: 54,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xCCFF0000),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: _ScheduleChip(label: data.scheduleLabel, dark: true),
              ),
              const Positioned(
                right: 8,
                bottom: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xCC000000),
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      '0:42',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Avatar(platformId: data.platformId, size: 36),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.title == 'Untitled post' ? data.caption : data.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F0F0F),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${data.accountLabel} · 0 views · Just now',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF606060),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.more_vert, color: Color(0xFF606060), size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pinterest ───────────────────────────────────────────────────────────────

class _PinterestCard extends StatelessWidget {
  const _PinterestCard({required this.data});
  final _PreviewData data;

  @override
  Widget build(BuildContext context) {
    return _Shell(
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: _Media(
                  files: data.mediaFiles,
                  isVideo: data.mediaIsVideo,
                  height: 280,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Row(
                  children: [
                    _ScheduleChip(label: data.scheduleLabel, dark: true),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE60023),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title == 'Untitled post' ? data.caption : data.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _Avatar(platformId: data.platformId, size: 28),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        data.accountLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111111),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Threads ─────────────────────────────────────────────────────────────────

class _ThreadsCard extends StatelessWidget {
  const _ThreadsCard({required this.data});
  final _PreviewData data;

  @override
  Widget build(BuildContext context) {
    return _Shell(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                _Avatar(platformId: data.platformId, size: 36),
                Container(
                  width: 2,
                  height: 80,
                  margin: const EdgeInsets.only(top: 8),
                  color: const Color(0xFFE0E0E0),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data.handle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF101010),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'now',
                        style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: _ScheduleChip(label: data.scheduleLabel),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data.caption,
                    style: const TextStyle(
                      fontSize: 14.5,
                      color: Color(0xFF101010),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _Media(
                      files: data.mediaFiles,
                      isVideo: data.mediaIsVideo,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Icon(Icons.favorite_border, size: 20, color: Color(0xFF101010)),
                      SizedBox(width: 16),
                      Icon(Icons.chat_bubble_outline, size: 20, color: Color(0xFF101010)),
                      SizedBox(width: 16),
                      Icon(Icons.repeat, size: 20, color: Color(0xFF101010)),
                      SizedBox(width: 16),
                      Icon(Icons.send_outlined, size: 20, color: Color(0xFF101010)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Snapchat ────────────────────────────────────────────────────────────────

class _SnapchatCard extends StatelessWidget {
  const _SnapchatCard({required this.data});
  final _PreviewData data;

  @override
  Widget build(BuildContext context) {
    return _Shell(
      color: Colors.black,
      borderColor: const Color(0xFF222222),
      child: SizedBox(
        height: 400,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _Media(
              files: data.mediaFiles,
              isVideo: data.mediaIsVideo,
              height: 400,
              fit: BoxFit.cover,
              darkPlaceholder: true,
            ),
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  _Avatar(platformId: data.platformId, size: 36),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      data.accountLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
                      ),
                    ),
                  ),
                  _ScheduleChip(label: data.scheduleLabel, dark: true),
                ],
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 20,
              child: Text(
                data.caption,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  shadows: [Shadow(blurRadius: 8, color: Colors.black87)],
                ),
              ),
            ),
            Positioned(
              right: 14,
              bottom: 90,
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFFC00),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Google Business ─────────────────────────────────────────────────────────

class _GoogleBusinessCard extends StatelessWidget {
  const _GoogleBusinessCard({required this.data});
  final _PreviewData data;

  @override
  Widget build(BuildContext context) {
    return _Shell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
            child: Row(
              children: [
                _Avatar(platformId: data.platformId, size: 40),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.accountLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF202124),
                        ),
                      ),
                      const Text(
                        'Google Business Profile · Just now',
                        style: TextStyle(fontSize: 12, color: Color(0xFF5F6368)),
                      ),
                    ],
                  ),
                ),
                _ScheduleChip(label: data.scheduleLabel),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data.title != 'Untitled post') ...[
                  Text(
                    data.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF202124),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  data.caption,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF3C4043),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          _Media(
            files: data.mediaFiles,
            isVideo: data.mediaIsVideo,
            height: 180,
            fit: BoxFit.cover,
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1A73E8),
                      side: const BorderSide(color: Color(0xFFDADCE0)),
                    ),
                    child: const Text('Call'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1A73E8),
                      side: const BorderSide(color: Color(0xFFDADCE0)),
                    ),
                    child: const Text('Share'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Generic fallback ────────────────────────────────────────────────────────

class _GenericCard extends StatelessWidget {
  const _GenericCard({required this.data});
  final _PreviewData data;

  @override
  Widget build(BuildContext context) {
    return _Shell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                PlatformIcon(id: data.platformId, size: 36),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.accountLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gray900,
                        ),
                      ),
                      Text(
                        data.platformName,
                        style: const TextStyle(fontSize: 12, color: AppColors.gray500),
                      ),
                    ],
                  ),
                ),
                _ScheduleChip(label: data.scheduleLabel),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Text(
              data.caption,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.gray700,
                height: 1.4,
              ),
            ),
          ),
          _Media(
            files: data.mediaFiles,
            isVideo: data.mediaIsVideo,
            height: 180,
            fit: BoxFit.cover,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ─── Shared building blocks ──────────────────────────────────────────────────

class _Shell extends StatelessWidget {
  const _Shell({
    required this.child,
    this.color = Colors.white,
    this.borderColor = const Color(0xFFE5E7EB),
    this.radius = 16,
  });

  final Widget child;
  final Color color;
  final Color borderColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _ScheduleChip extends StatelessWidget {
  const _ScheduleChip({required this.label, this.dark = false});

  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: dark
            ? Colors.black.withValues(alpha: 0.45)
            : AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: dark ? Colors.white : AppColors.primary,
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.platformId,
    required this.size,
    this.radius,
  });

  final String platformId;
  final double size;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius ?? size / 2),
      child: PlatformIcon(id: platformId, size: size),
    );
  }
}

class _AvatarRing extends StatelessWidget {
  const _AvatarRing({required this.platformId, required this.size});

  final String platformId;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: _Avatar(platformId: platformId, size: size),
      ),
    );
  }
}

class _Media extends StatelessWidget {
  const _Media({
    required this.files,
    required this.isVideo,
    required this.height,
    required this.fit,
    this.darkPlaceholder = false,
  });

  final List<File> files;
  final bool isVideo;
  final double height;
  final BoxFit fit;
  final bool darkPlaceholder;

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      return CachedNetworkImage(
        imageUrl: AppData.previewImageUrl,
        height: height,
        width: double.infinity,
        fit: fit,
        placeholder: (_, _) => Container(
          height: height,
          color: darkPlaceholder ? const Color(0xFF111111) : AppColors.gray100,
        ),
        errorWidget: (_, _, _) => Container(
          height: height,
          color: darkPlaceholder ? const Color(0xFF111111) : AppColors.gray100,
        ),
      );
    }

    if (isVideo) {
      return ColoredBox(
        color: Colors.black,
        child: LocalVideoPreview(
          file: files.first,
          height: height,
          width: double.infinity,
          borderRadius: 0,
          showControls: true,
          fit: BoxFit.contain,
          onExpand: () => openLocalMediaViewer(
            context,
            files: files,
            isVideo: true,
          ),
        ),
      );
    }

    if (files.length == 1) {
      return GestureDetector(
        onTap: () => openLocalMediaViewer(context, files: files),
        child: ColoredBox(
          color: darkPlaceholder ? const Color(0xFF111111) : AppColors.gray100,
          child: Image.file(
            files.first,
            height: height,
            width: double.infinity,
            fit: fit,
          ),
        ),
      );
    }

    return _Carousel(files: files, height: height, fit: fit);
  }
}

class _Carousel extends StatefulWidget {
  const _Carousel({
    required this.files,
    required this.height,
    required this.fit,
  });

  final List<File> files;
  final double height;
  final BoxFit fit;

  @override
  State<_Carousel> createState() => _CarouselState();
}

class _CarouselState extends State<_Carousel> {
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: widget.height,
          width: double.infinity,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.files.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => openLocalMediaViewer(
                context,
                files: widget.files,
                initialIndex: i,
              ),
              child: Image.file(
                widget.files[i],
                height: widget.height,
                width: double.infinity,
                fit: widget.fit,
              ),
            ),
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${_index + 1}/${widget.files.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}