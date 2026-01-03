import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';

class EndButton extends StatelessWidget {
  const EndButton({
    super.key,
    required this.onPressed,
    required this.enabled,
    required this.label,
  });

  final VoidCallback? onPressed;
  final bool enabled;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: enabled ? AppColors.textMuted : AppColors.border,
          textStyle: const TextStyle(fontSize: 14, letterSpacing: 0.8),
        ),
        child: Text(label),
      ),
    );
  }
}
