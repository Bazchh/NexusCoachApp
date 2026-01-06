 import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../../app/app_colors.dart';
import '../../app/app_strings.dart';
import '../../models/session_models.dart';
import '../../services/minimap_reminder_controller.dart';
import '../../services/nexus_api.dart';
import '../../services/overlay_controller.dart';
import '../../services/tts_controller.dart';
import '../../services/ward_reminder_controller.dart';
import '../settings/language_voice_screen.dart';
import '../settings/privacy_screen.dart';
import 'widgets/end_button.dart';
import 'widgets/primary_action.dart';
import 'widgets/slider_tile.dart';
import 'widgets/top_row.dart';

part 'coach_home_helpers.dart';
part 'coach_home_overlay.dart';
part 'coach_home_prefs.dart';
part 'coach_home_session.dart';
part 'coach_home_settings.dart';
part 'coach_home_tutorial.dart';
part 'coach_home_voice.dart';

const String _apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000',
);

class CoachHome extends StatefulWidget {
  const CoachHome({super.key});

  @override
  State<CoachHome> createState() => _CoachHomeState();
}

enum _FeedbackRating { good, bad }

class _CoachHomeState extends State<CoachHome> with WidgetsBindingObserver {
  final NexusApi _api = NexusApi(_apiBaseUrl);
  final String _deviceId = DateTime.now().millisecondsSinceEpoch.toString();
  final List<HistoryEntry> _history = [];
  final TextEditingController _textController = TextEditingController();
  final SpeechToText _speech = SpeechToText();

  // Tutorial keys
  final GlobalKey _keyStartButton = GlobalKey();
  final GlobalKey _keySettingsButton = GlobalKey();
  final GlobalKey _keyOverlayDemo = GlobalKey();
  TutorialCoachMark? _tutorialCoachMark;
  bool _showOverlayDemo = false;
  static const _keyTutorialSeen = 'tutorial_seen';

  String? _sessionId;
  bool _sessionActive = false;
  bool _busy = false;
  bool _sending = false;
  bool _voiceListening = false;

  bool _coachPaused = false;
  double _micSensitivity = 0.7;
  double _coachVolume = 0.8;
  double _speechRate = 0.5;
  String _language = 'en-US';
  String _voice = 'Feminina';
  bool _minimapReminder = false;
  double _minimapInterval = 45;
  bool _wardReminder = false;
  static const int _wardIntervalFixed = 50; // Fixo em 50 segundos
  bool _overlayAutoStart = true;
  bool _overlayPermissionGranted = false;
  bool _overlayActive = false;
  String? _sessionChampion;
  String? _sessionLane;

  static const _keyCoachPaused = 'coach_paused';
  static const _keyMicSensitivity = 'mic_sensitivity';
  static const _keyCoachVolume = 'coach_volume';
  static const _keySpeechRate = 'speech_rate';
  static const _keyLanguage = 'language';
  static const _keyVoice = 'voice';
  static const _keyMinimapReminder = 'minimap_reminder';
  static const _keyMinimapInterval = 'minimap_interval';
  static const _keyWardReminder = 'ward_reminder';
  static const _keyOverlayAutoStart = 'overlay_auto_start';
  static const _keySessionId = 'session_id';
  static const _keySessionActive = 'session_active';
  static const _keySessionChampion = 'session_champion';
  static const _keySessionLane = 'session_lane';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
    _requestMicPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _textController.dispose();
    _speech.stop();
    TtsController.dispose();
    OverlayController.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _handleAppResumed();
    } else if (state == AppLifecycleState.paused) {
      _handleAppPaused();
    }
  }

  AppStrings get _strings => AppStrings.of(_language);

  String get _statusLabel {
    if (_sending || _busy) {
      return _strings.statusThinking;
    }
    if (_coachPaused) {
      return _strings.statusPaused;
    }
    if (_sessionActive) {
      return _strings.statusListening;
    }
    return _strings.statusIdle;
  }

  @override
  Widget build(BuildContext context) {
    final strings = _strings;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.background, AppColors.backgroundAlt],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: TopRow(
                    statusLabel: _statusLabel,
                    settingsTooltip: strings.settingsTitle,
                    onSettingsTap: () => _openSettingsSheet(context, strings),
                    settingsKey: _keySettingsButton,
                  ),
                ),
                // Widget de demonstração do overlay para o tutorial
                if (_showOverlayDemo)
                  Positioned(
                    right: 24,
                    top: 104,
                    child: _OverlayDemo(key: _keyOverlayDemo),
                  ),
                Align(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PrimaryAction(
                        label: _sessionActive
                            ? strings.sessionActiveLabel
                            : strings.startButton,
                        enabled: !_sessionActive && !_busy,
                        onPressed: _sessionActive || _busy
                            ? null
                            : () => _openStartSheet(context, strings),
                        buttonKey: _keyStartButton,
                      ),
                      const SizedBox(height: 28),
                      EndButton(
                        enabled: _sessionActive && !_busy,
                        label: strings.endButton,
                        onPressed: _sessionActive ? _endSession : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
