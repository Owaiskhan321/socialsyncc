import 'package:flutter/material.dart';

import '../../data/models/models.dart';
import '../theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final PostStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      PostStatus.draft => ('Draft', AppColors.gray100, AppColors.gray500),
      PostStatus.scheduled => ('Scheduled', AppColors.blue50, AppColors.primary),
      PostStatus.published => ('Published', AppColors.green50, AppColors.success),
      PostStatus.failed => ('Failed', AppColors.red50, AppColors.danger),
      PostStatus.cancelled => ('Cancelled', AppColors.gray100, AppColors.gray400),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
