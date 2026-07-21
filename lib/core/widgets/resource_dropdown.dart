import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../../data/models/api_models.dart';
import 'platform_icon.dart';

/// Custom bottom-sheet style resource picker (pages / boards / channels).
class ResourceDropdown extends StatelessWidget {
  const ResourceDropdown({
    super.key,
    required this.label,
    required this.platformId,
    required this.items,
    required this.selectedId,
    required this.onChanged,
    this.hint = 'Select…',
  });

  final String label;
  final String platformId;
  final List<NamedResource> items;
  final String? selectedId;
  final ValueChanged<String> onChanged;
  final String hint;

  NamedResource? get _selected {
    if (items.isEmpty) return null;
    if (selectedId == null) return items.first;
    for (final item in items) {
      if (item.id == selectedId) return item;
    }
    return items.first;
  }

  Future<void> _openPicker(BuildContext context) async {
    if (items.isEmpty) return;
    final chosen = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.55,
          ),
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gray200,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    PlatformIcon(id: platformId, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gray900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isOn = item.id == (_selected?.id ?? selectedId);
                    return Material(
                      color: isOn ? AppColors.blue50 : AppColors.gray50,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.of(ctx).pop(item.id),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              _Avatar(
                                imageUrl: item.imageUrl,
                                platformId: platformId,
                                size: 40,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.gray900,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (item.subtitle != null &&
                                        item.subtitle!.isNotEmpty &&
                                        item.subtitle != item.name)
                                      Text(
                                        item.subtitle!,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.gray500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              if (isOn)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
    if (chosen != null) onChanged(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.gray500,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: items.isEmpty ? null : () => _openPicker(context),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.gray200),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (selected != null)
                  _Avatar(
                    imageUrl: selected.imageUrl,
                    platformId: platformId,
                    size: 34,
                  )
                else
                  PlatformIcon(id: platformId, size: 34),
                const SizedBox(width: 10),
                Expanded(
                  child: selected == null
                      ? Text(
                          items.isEmpty ? 'No options available' : hint,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.gray400,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selected.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.gray900,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (selected.subtitle != null &&
                                selected.subtitle!.isNotEmpty &&
                                selected.subtitle != selected.name)
                              Text(
                                selected.subtitle!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.gray500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: items.isEmpty ? AppColors.gray300 : AppColors.gray500,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.imageUrl,
    required this.platformId,
    required this.size,
  });

  final String? imageUrl;
  final String platformId;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            width: size,
            height: size,
            color: AppColors.gray100,
          ),
          errorWidget: (_, __, ___) => PlatformIcon(id: platformId, size: size),
        ),
      );
    }
    return PlatformIcon(id: platformId, size: size);
  }
}
