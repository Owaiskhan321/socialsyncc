import 'package:flutter/material.dart';

import '../../data/models/models.dart';
import '../theme/app_colors.dart';
import 'platform_icon.dart';

/// Compact platform icons with green/red status dots (published / failed).
class PlatformStatusIcons extends StatelessWidget {
  const PlatformStatusIcons({
    super.key,
    required this.post,
    this.iconSize = 22,
    this.spacing = 6,
    this.maxVisible,
  });

  final PostModel post;
  final double iconSize;
  final double spacing;
  final int? maxVisible;

  @override
  Widget build(BuildContext context) {
    final results = post.displayPlatformResults;
    if (results.isEmpty) return const SizedBox.shrink();

    final visible =
        maxVisible == null ? results : results.take(maxVisible!).toList();
    final overflow =
        maxVisible == null ? 0 : (results.length - visible.length).clamp(0, 99);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < visible.length; i++) ...[
          if (i > 0) SizedBox(width: spacing),
          _StatusIcon(result: visible[i], size: iconSize),
        ],
        if (overflow > 0) ...[
          SizedBox(width: spacing),
          Text(
            '+$overflow',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.gray400,
            ),
          ),
        ],
      ],
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.result, required this.size});

  final PostPlatformResult result;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Color? dotColor = switch (result.status) {
      PostStatus.published => AppColors.success,
      PostStatus.failed => AppColors.danger,
      PostStatus.publishing => AppColors.primary,
      PostStatus.partial => AppColors.warning,
      _ => null,
    };
    final dot = (size * 0.38).clamp(7.0, 10.0);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        PlatformIcon(id: result.platformId, size: size),
        if (dotColor != null)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: dot,
              height: dot,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}
