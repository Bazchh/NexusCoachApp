import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/app_colors.dart';

class PrimaryAction extends StatelessWidget {
  const PrimaryAction({
    super.key,
    required this.label,
    required this.onPressed,
    required this.enabled,
    this.buttonKey,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;
  final GlobalKey? buttonKey;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: SizedBox(
          key: buttonKey,
          height: 58,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: enabled ? AppColors.accent : AppColors.surface,
              foregroundColor: AppColors.background,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              label,
              style: GoogleFonts.bebasNeue(
                fontSize: 24,
                letterSpacing: 1.1,
                color: enabled ? AppColors.background : AppColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
