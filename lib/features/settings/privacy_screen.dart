import 'package:flutter/material.dart';

import '../../app/app_colors.dart';
import '../../app/app_strings.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key, required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: Text(strings.privacyTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.privacySummaryTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              strings.privacySummaryBody,
              style: const TextStyle(height: 1.5, color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            Text(
              strings.privacyDataTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              strings.privacyDataBody,
              style: const TextStyle(height: 1.6, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
