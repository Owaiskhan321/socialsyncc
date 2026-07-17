import 'package:flutter/material.dart';

import '../../data/repositories/app_data.dart';
import '../theme/app_colors.dart';

class PlatformIcon extends StatelessWidget {
  const PlatformIcon({super.key, required this.id, this.size = 24});

  final String id;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = AppData.platformById(id);
    if (p == null) return const SizedBox.shrink();
    final initial = AppData.initials[id] ?? id[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Color(p.color),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Text(
        initial,
        style: TextStyle(
          color: AppColors.white,
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}
