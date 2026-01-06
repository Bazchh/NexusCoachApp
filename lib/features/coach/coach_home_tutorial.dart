// ignore_for_file: invalid_use_of_protected_member
part of 'coach_home.dart';

extension _CoachHomeStateTutorial on _CoachHomeState {
  void _showTutorial() {
    final strings = _strings;

    setState(() => _showOverlayDemo = true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tutorialCoachMark = TutorialCoachMark(
        targets: _createTutorialTargets(strings),
        colorShadow: AppColors.background,
        opacityShadow: 0.9,
        textSkip: strings.tutorialSkip,
        textStyleSkip: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        paddingFocus: 10,
        focusAnimationDuration: const Duration(milliseconds: 400),
        pulseAnimationDuration: const Duration(milliseconds: 1000),
        onFinish: () => _onTutorialComplete(),
        onSkip: () {
          _onTutorialComplete();
          return true;
        },
      )..show(context: context);
    });
  }

  List<TargetFocus> _createTutorialTargets(AppStrings strings) {
    return [
      TargetFocus(
        identify: 'start_button',
        keyTarget: _keyStartButton,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => _TutorialContent(
              title: strings.tutorialStartTitle,
              description: strings.tutorialStartDesc,
              buttonText: strings.tutorialNext,
              onPressed: () => controller.next(),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'settings_button',
        keyTarget: _keySettingsButton,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => _TutorialContent(
              title: strings.tutorialSettingsTitle,
              description: strings.tutorialSettingsDesc,
              buttonText: strings.tutorialNext,
              onPressed: () => controller.next(),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'overlay_demo',
        keyTarget: _keyOverlayDemo,
        alignSkip: Alignment.bottomRight,
        shape: ShapeLightFocus.Circle,
        radius: 80,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => _TutorialContent(
              title: strings.tutorialOverlayTitle,
              description: strings.tutorialOverlayDesc,
              buttonText: strings.tutorialFinish,
              onPressed: () => controller.next(),
            ),
          ),
        ],
      ),
    ];
  }

  Future<void> _onTutorialComplete() async {
    setState(() => _showOverlayDemo = false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_CoachHomeState._keyTutorialSeen, true);
  }
}

class _OverlayDemo extends StatelessWidget {
  const _OverlayDemo({super.key});

  @override
  Widget build(BuildContext context) {
    const bubbleSize = 56.0;
    const menuSize = 30.0;
    const menuGap = 8.0;
    const menuItems = 6;
    const menuColumnHeight = menuSize * menuItems + menuGap * (menuItems - 1);

    return SizedBox(
      width: 160,
      height: 200,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: (200 - bubbleSize) / 2,
            child: Container(
              width: bubbleSize,
              height: bubbleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF2EFFD4), Color(0xFF0D1419)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: const Color(0xFF1E1E24), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2EFFD4).withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'N',
                  style: TextStyle(
                    color: Color(0xFF05070A),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: (200 - menuColumnHeight) / 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                _MenuButton(label: 'X', enabled: false, size: menuSize),
                SizedBox(height: menuGap),
                _MenuButton(label: 'G', enabled: false, size: menuSize),
                SizedBox(height: menuGap),
                _MenuButton(label: 'S', enabled: false, size: menuSize),
                SizedBox(height: menuGap),
                _MenuButton(label: 'MIC', enabled: false, size: menuSize, textSize: 9),
                SizedBox(height: menuGap),
                _MenuButton(label: 'M', enabled: true, size: menuSize),
                SizedBox(height: menuGap),
                _MenuButton(label: 'W', enabled: false, size: menuSize),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.label,
    required this.enabled,
    this.size = 32,
    this.textSize = 12,
  });

  final String label;
  final bool enabled;
  final double size;
  final double textSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: enabled ? const Color(0xFF1A3D2E) : const Color(0xFF1B1F25),
        border: Border.all(
          color: enabled ? const Color(0xFF2EFFD4) : const Color(0x33FFFFFF),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: enabled ? const Color(0xFF2EFFD4) : const Color(0xFF6B7280),
            fontSize: textSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _TutorialContent extends StatelessWidget {
  const _TutorialContent({
    required this.title,
    required this.description,
    required this.buttonText,
    required this.onPressed,
  });

  final String title;
  final String description;
  final String buttonText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.background,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
