// ignore_for_file: invalid_use_of_protected_member
part of 'coach_home.dart';

extension _CoachHomeStateHelpers on _CoachHomeState {
  String _laneLabel(String lane, AppStrings strings) {
    switch (lane) {
      case 'top':
        return strings.laneTop;
      case 'mid':
        return strings.laneMid;
      case 'bot':
        return strings.laneBot;
      case 'jungle':
        return strings.laneJungle;
      case 'support':
        return strings.laneSupport;
      default:
        return lane;
    }
  }

  Future<void> _syncMinimapReminder() async {
    final shouldRun = _minimapReminder && _sessionActive && !_coachPaused;
    if (shouldRun) {
      await MinimapReminderController.start(
        intervalSeconds: _minimapInterval.round(),
        message: _strings.minimapReminderMessage,
        locale: _language,
      );
    } else {
      await MinimapReminderController.stop();
    }
  }

  Future<void> _syncWardReminder() async {
    final shouldRun = _wardReminder && _sessionActive && !_coachPaused;
    if (shouldRun) {
      await WardReminderController.start(
        intervalSeconds: _CoachHomeState._wardIntervalFixed,
        message: _strings.wardReminderMessage,
        locale: _language,
      );
    } else {
      await WardReminderController.stop();
    }
  }

  Future<void> _initTts() async {
    final isMale = _voice == 'Masculina';
    await TtsController.init(
      volume: _coachVolume,
      speechRate: _speechRate,
      language: _language,
      isMale: isMale,
    );
  }

  Future<void> _speakResponse(String text) async {
    if (_coachPaused || _coachVolume == 0) return;
    await TtsController.stop();
    await TtsController.speak(text);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.surface,
      ),
    );
  }
}
