import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';

class QuickInput extends StatelessWidget {
  const QuickInput({
    super.key,
    required this.controller,
    required this.enabled,
    required this.micEnabled,
    required this.micActive,
    required this.micTooltip,
    required this.hint,
    required this.sendTooltip,
    required this.onSend,
    required this.onMicTap,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool micEnabled;
  final bool micActive;
  final String micTooltip;
  final String hint;
  final String sendTooltip;
  final VoidCallback onSend;
  final VoidCallback onMicTap;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              decoration: InputDecoration(
                hintText: hint,
                filled: true,
                fillColor: AppColors.backgroundAlt,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: micEnabled ? onMicTap : null,
            icon: Icon(micActive ? Icons.mic : Icons.mic_none),
            color: micActive ? AppColors.accent : AppColors.textMuted,
            disabledColor: AppColors.border,
            tooltip: micTooltip,
          ),
          IconButton(
            onPressed: enabled ? onSend : null,
            icon: const Icon(Icons.send),
            color: AppColors.accent,
            tooltip: sendTooltip,
          ),
        ],
      ),
    );
  }
}
