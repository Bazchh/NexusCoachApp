import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';

class TopRow extends StatelessWidget {
  const TopRow({
    super.key,
    required this.onSettingsTap,
    required this.statusLabel,
    required this.settingsTooltip,
  });

  final VoidCallback onSettingsTap;
  final String statusLabel;
  final String settingsTooltip;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _StatusChip(label: statusLabel),
        IconButton(
          onPressed: onSettingsTap,
          icon: const Icon(Icons.settings),
          color: AppColors.textMuted,
          iconSize: 20,
          splashRadius: 20,
          tooltip: settingsTooltip,
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.background,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
