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
          _MicButton(
            enabled: micEnabled,
            active: micActive,
            tooltip: micTooltip,
            onTap: onMicTap,
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

/// Botão de microfone com animação de pulso quando ativo
class _MicButton extends StatefulWidget {
  const _MicButton({
    required this.enabled,
    required this.active,
    required this.tooltip,
    required this.onTap,
  });

  final bool enabled;
  final bool active;
  final String tooltip;
  final VoidCallback onTap;

  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(_MicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _controller.repeat(reverse: true);
    } else if (!widget.active && oldWidget.active) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.active
                    ? AppColors.accent.withValues(alpha: 0.2)
                    : Colors.transparent,
              ),
              child: Transform.scale(
                scale: widget.active ? _scaleAnimation.value : 1.0,
                child: Icon(
                  widget.active ? Icons.mic : Icons.mic_none,
                  color: widget.enabled
                      ? (widget.active ? AppColors.accent : AppColors.textMuted)
                      : AppColors.border,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
