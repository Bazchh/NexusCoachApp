import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../../../app/app_strings.dart';
import '../../../models/session_models.dart';

class HistoryCard extends StatelessWidget {
  const HistoryCard({super.key, required this.history, required this.strings});

  final List<HistoryEntry> history;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: _HistoryContent(history: history, strings: strings),
        ),
      ),
    );
  }
}

class _HistoryContent extends StatelessWidget {
  const _HistoryContent({required this.history, required this.strings});

  final List<HistoryEntry> history;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Text(
        strings.historyEmpty,
        style: const TextStyle(fontSize: 14, color: AppColors.textMuted, height: 1.4),
      );
    }

    final visible = history.length > 3
        ? history.sublist(history.length - 3)
        : history;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.historyTitle,
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 8),
        for (final item in visible) ...[
          Text(
            '${item.role}: ${item.text}',
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 4),
        ],
      ],
    );
  }
}
