import 'package:flutter/material.dart';

import '../../data/models/models.dart';
import '../theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, this.compact = false});

  final PostStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      PostStatus.draft => ('Draft', AppColors.gray100, AppColors.gray500),
      PostStatus.scheduled => ('Scheduled', AppColors.blue50, AppColors.primary),
      PostStatus.publishing => ('Publishing', AppColors.blue50, AppColors.primary),
      PostStatus.published => ('Published', AppColors.green50, AppColors.success),
      PostStatus.partial => ('Partial', AppColors.amber50, AppColors.warning),
      PostStatus.failed => ('Failed', AppColors.red50, AppColors.danger),
      PostStatus.cancelled => ('Cancelled', AppColors.gray100, AppColors.gray400),
    };
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
