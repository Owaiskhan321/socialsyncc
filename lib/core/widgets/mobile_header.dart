import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class MobileHeader extends StatelessWidget {
  const MobileHeader({
    super.key,
    required this.title,
    this.onBack,
    this.rightSlot,
  });

  final String title;
  final VoidCallback? onBack;
  final Widget? rightSlot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.gray100)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: onBack != null
                ? IconButton(
                    onPressed: onBack,
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.chevron_left, size: 26, color: AppColors.gray800),
                  )
                : null,
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.gray900,
              ),
            ),
          ),
          SizedBox(width: 36, child: rightSlot),
        ],
      ),
    );
  }
}
