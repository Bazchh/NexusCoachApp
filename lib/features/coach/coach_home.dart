 import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../app/app_colors.dart';
import '../../app/app_strings.dart';
import '../../models/session_models.dart';
import '../../services/minimap_reminder_controller.dart';
import '../../services/nexus_api.dart';
import '../../services/overlay_controller.dart';
import '../settings/language_voice_screen.dart';
import '../settings/privacy_screen.dart';
import 'widgets/end_button.dart';
import 'widgets/history_card.dart';
import 'widgets/primary_action.dart';
import 'widgets/quick_input.dart';
import 'widgets/slider_tile.dart';
import 'widgets/top_row.dart';

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

  String? _sessionId;
  bool _sessionActive = false;
  bool _busy = false;
  bool _sending = false;
  bool _voiceListening = false;

  bool _coachPaused = false;
  double _micSensitivity = 0.7;
  double _coachVolume = 0.8;
  String _language = 'pt-BR';
  String _voice = 'Feminina';
  bool _minimapReminder = false;
  double _minimapInterval = 45;
  bool _overlayAutoStart = true;
  bool _overlayPermissionGranted = false;
  bool _overlayActive = false;
  String? _sessionChampion;
  String? _sessionLane;

  static const _keyCoachPaused = 'coach_paused';
  static const _keyMicSensitivity = 'mic_sensitivity';
  static const _keyCoachVolume = 'coach_volume';
  static const _keyLanguage = 'language';
  static const _keyVoice = 'voice';
  static const _keyMinimapReminder = 'minimap_reminder';
  static const _keyMinimapInterval = 'minimap_interval';
  static const _keyOverlayAutoStart = 'overlay_auto_start';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _textController.dispose();
    _speech.stop();
    OverlayController.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateOverlayPermission();
      _maybeStartOverlayService();
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    setState(() {
      _coachPaused = prefs.getBool(_keyCoachPaused) ?? _coachPaused;
      _micSensitivity = prefs.getDouble(_keyMicSensitivity) ?? _micSensitivity;
      _coachVolume = prefs.getDouble(_keyCoachVolume) ?? _coachVolume;
      _language = prefs.getString(_keyLanguage) ?? _language;
      _voice = prefs.getString(_keyVoice) ?? _voice;
      _minimapReminder = prefs.getBool(_keyMinimapReminder) ?? _minimapReminder;
      _minimapInterval = prefs.getDouble(_keyMinimapInterval) ?? _minimapInterval;
      _overlayAutoStart =
          prefs.getBool(_keyOverlayAutoStart) ?? _overlayAutoStart;
    });
    await _syncMinimapReminder();
    await _updateOverlayPermission();
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

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _saveDouble(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key, value);
  }

  Future<void> _saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
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
                  ),
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
                      ),
                      const SizedBox(height: 20),
                      if (_sessionActive) ...[
                        QuickInput(
                          controller: _textController,
                          enabled:
                              !_sending && !_busy && !_coachPaused,
                          micEnabled: _sessionActive &&
                              !_sending &&
                              !_busy &&
                              !_coachPaused,
                          micActive: _voiceListening,
                          micTooltip: _voiceListening
                              ? strings.micStopTooltip
                              : strings.micStartTooltip,
                          hint: strings.quickInputHint,
                          sendTooltip: strings.sendTooltip,
                          onSend: _sendTextTurn,
                          onMicTap: _toggleVoiceInput,
                        ),
                        const SizedBox(height: 22),
                      ],
                      HistoryCard(history: _history, strings: strings),
                      const SizedBox(height: 26),
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

  void _openSettingsSheet(BuildContext context, AppStrings strings) {
    final rootContext = context;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        strings.settingsTitle,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        value: _coachPaused,
                        onChanged: (value) async {
                          setSheetState(() => _coachPaused = value);
                          setState(() => _coachPaused = value);
                          _saveBool(_keyCoachPaused, value);
                          if (value) {
                            await _stopVoiceInput();
                          }
                          await _syncMinimapReminder();
                        },
                        title: Text(strings.pauseCoachTitle),
                        subtitle: Text(
                          strings.pauseCoachSubtitle,
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                        activeColor: AppColors.accent,
                      ),
                      const SizedBox(height: 8),
                      SliderTile(
                        title: strings.micSensitivityTitle,
                        value: _micSensitivity,
                        onChanged: (value) {
                          setSheetState(() => _micSensitivity = value);
                          setState(() => _micSensitivity = value);
                          _saveDouble(_keyMicSensitivity, value);
                        },
                      ),
                      const SizedBox(height: 8),
                      SliderTile(
                        title: strings.coachVolumeTitle,
                        value: _coachVolume,
                        onChanged: (value) {
                          setSheetState(() => _coachVolume = value);
                          setState(() => _coachVolume = value);
                          _saveDouble(_keyCoachVolume, value);
                        },
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        value: _minimapReminder,
                        onChanged: (value) async {
                          setSheetState(() => _minimapReminder = value);
                          setState(() => _minimapReminder = value);
                          _saveBool(_keyMinimapReminder, value);
                          await _syncMinimapReminder();
                        },
                        title: Text(strings.minimapReminderTitle),
                        subtitle: Text(
                          strings.minimapReminderSubtitle,
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                        activeColor: AppColors.accent,
                      ),
                      if (_minimapReminder) ...[
                        const SizedBox(height: 8),
                        SliderTile(
                          title: strings.minimapIntervalTitle,
                          value: _minimapInterval,
                          min: 20,
                          max: 90,
                          divisions: 7,
                          label: '${_minimapInterval.round()}s',
                          onChanged: (value) async {
                            setSheetState(() => _minimapInterval = value);
                            setState(() => _minimapInterval = value);
                            _saveDouble(_keyMinimapInterval, value);
                            await _syncMinimapReminder();
                          },
                        ),
                      ],
                      const SizedBox(height: 8),
                      SwitchListTile(
                        value: _overlayAutoStart,
                        onChanged: (value) async {
                          setSheetState(() => _overlayAutoStart = value);
                          setState(() => _overlayAutoStart = value);
                          _saveBool(_keyOverlayAutoStart, value);
                        },
                        title: Text(strings.overlayAutoStartTitle),
                        subtitle: Text(
                          strings.overlayAutoStartSubtitle,
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                        activeColor: AppColors.accent,
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        value: _overlayActive,
                        onChanged: (_) async {
                          await _toggleOverlayService();
                          setState(() {});
                        },
                        title: Text(strings.overlayTestTitle),
                        subtitle: Text(
                          _overlayPermissionGranted
                              ? strings.overlayStatusActive
                              : strings.overlayStatusMissing,
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                        activeColor: AppColors.accent,
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(strings.languageVoiceTitle),
                        subtitle: Text(
                          '$_language - $_voice',
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        onTap: () async {
                          Navigator.of(context).pop();
                          final result = await Navigator.of(rootContext)
                              .push<LanguageVoiceResult>(
                            MaterialPageRoute(
                              builder: (_) => LanguageVoiceScreen(
                                initialLanguage: _language,
                                initialVoice: _voice,
                                strings: strings,
                              ),
                            ),
                          );
                          if (result != null) {
                            setState(() {
                              _language = result.language;
                              _voice = result.voice;
                            });
                            _saveString(_keyLanguage, result.language);
                            _saveString(_keyVoice, result.voice);
                            await _syncMinimapReminder();
                          }
                        },
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(strings.privacyTitle),
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        onTap: () {
                          Navigator.of(context).pop();
                          Future.microtask(() {
                            Navigator.of(rootContext).push(
                              MaterialPageRoute(
                                builder: (_) => PrivacyScreen(strings: strings),
                              ),
                            );
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openStartSheet(BuildContext context, AppStrings strings) {
    final championController = TextEditingController();
    final enemyController = TextEditingController();
    String lane = 'top';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    strings.startSheetTitle,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: championController,
                    decoration: InputDecoration(
                      labelText: strings.championLabel,
                      filled: true,
                      fillColor: AppColors.backgroundAlt,
                      border: const OutlineInputBorder(),
                    ),
                    style: const TextStyle(color: AppColors.textPrimary),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: lane,
                    decoration: InputDecoration(
                      labelText: strings.laneLabel,
                      filled: true,
                      fillColor: AppColors.backgroundAlt,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(value: 'top', child: Text(strings.laneTop)),
                      DropdownMenuItem(value: 'mid', child: Text(strings.laneMid)),
                      DropdownMenuItem(value: 'bot', child: Text(strings.laneBot)),
                      DropdownMenuItem(
                        value: 'jungle',
                        child: Text(strings.laneJungle),
                      ),
                      DropdownMenuItem(
                        value: 'support',
                        child: Text(strings.laneSupport),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setSheetState(() => lane = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: enemyController,
                    decoration: InputDecoration(
                      labelText: strings.matchupLabel,
                      filled: true,
                      fillColor: AppColors.backgroundAlt,
                      border: const OutlineInputBorder(),
                    ),
                    style: const TextStyle(color: AppColors.textPrimary),
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _busy
                        ? null
                        : () {
                            final champion = championController.text.trim();
                            if (champion.isEmpty) {
                              _showError(strings.errorChampionRequired);
                              return;
                            }
                            Navigator.of(sheetContext).pop();
                            _startSession(
                              champion: champion,
                              lane: lane,
                              enemy: enemyController.text.trim(),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.background,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(strings.startAction),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _startSession({
    required String champion,
    required String lane,
    String? enemy,
  }) async {
    final strings = _strings;
    setState(() => _busy = true);
    try {
      final result = await _api.startSession(
        deviceId: _deviceId,
        locale: _language,
        champion: champion,
        lane: lane,
        enemy: enemy?.isEmpty == true ? null : enemy,
      );
      if (!mounted) return;
      setState(() {
        _sessionId = result.sessionId;
        _sessionActive = true;
        _sessionChampion = champion;
        _sessionLane = lane;
        _history
          ..clear()
          ..add(
            HistoryEntry(
              strings.systemLabel,
              strings.sessionStarted(champion, _laneLabel(lane, strings)),
            ),
          );
      });
      await _syncMinimapReminder();
      await _maybeStartOverlayService();
    } on ApiException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError(strings.errorStartFailed);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _endSession() async {
    final strings = _strings;
    final sessionId = _sessionId;
    if (sessionId == null) return;
    final endedChampion = _sessionChampion;
    final endedLane = _sessionLane;
    setState(() => _busy = true);
    await _stopVoiceInput();
    try {
      await _api.endSession(sessionId);
      if (!mounted) return;
      setState(() {
        _sessionId = null;
        _sessionActive = false;
        _sessionChampion = null;
        _sessionLane = null;
        _history.add(HistoryEntry(strings.systemLabel, strings.sessionEnded));
      });
      await _syncMinimapReminder();
      await _stopOverlayService();
      await _promptFeedback(
        sessionId,
        champion: endedChampion,
        lane: endedLane,
      );
    } on ApiException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError(strings.errorEndFailed);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _sendTextTurn() async {
    final strings = _strings;
    final sessionId = _sessionId;
    final text = _textController.text.trim();
    if (sessionId == null || text.isEmpty) return;
    setState(() {
      _sending = true;
      _history.add(HistoryEntry(strings.youLabel, text));
    });
    FocusManager.instance.primaryFocus?.unfocus();
    _textController.clear();

    try {
      final result = await _api.sendTurn(sessionId: sessionId, text: text);
      if (!mounted) return;
      setState(() {
        _history.add(HistoryEntry(strings.coachLabel, result.replyText));
      });
    } on ApiException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError(strings.errorSendFailed);
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _toggleVoiceInput() async {
    final strings = _strings;
    if (!_sessionActive) {
      _showError(strings.errorSessionRequired);
      return;
    }
    if (_coachPaused) {
      _showError(strings.errorCoachPaused);
      return;
    }
    if (_voiceListening) {
      await _stopVoiceInput();
      return;
    }

    final available = await _speech.initialize(
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'notListening' || status == 'done') {
          setState(() => _voiceListening = false);
        }
      },
      onError: (_) {
        if (!mounted) return;
        setState(() => _voiceListening = false);
        _showError(strings.errorMicUnavailable);
      },
    );

    if (!available) {
      _showError(strings.errorMicUnavailable);
      return;
    }

    setState(() => _voiceListening = true);
    await _speech.listen(
      localeId: _language,
      listenFor: const Duration(seconds: 8),
      pauseFor: const Duration(seconds: 2),
      partialResults: true,
      onResult: (result) {
        if (!mounted) return;
        final recognized = result.recognizedWords.trim();
        if (recognized.isEmpty) return;
        if (result.finalResult) {
          _textController.text = recognized;
          _sendTextTurn();
          _stopVoiceInput();
        } else {
          setState(() => _textController.text = recognized);
        }
      },
    );
  }

  Future<void> _stopVoiceInput() async {
    if (!_voiceListening) return;
    await _speech.stop();
    if (mounted) {
      setState(() => _voiceListening = false);
    }
  }

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

  Future<void> _updateOverlayPermission() async {
    final granted = await OverlayController.canDrawOverlays();
    if (!mounted) return;
    setState(() => _overlayPermissionGranted = granted);
  }

  Future<bool> _ensureOverlayPermission() async {
    final strings = _strings;
    final allowed = await OverlayController.canDrawOverlays();
    if (allowed) {
      if (mounted) {
        setState(() => _overlayPermissionGranted = true);
      }
      return true;
    }

    final ask = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(strings.overlayPermissionTitle),
        content: Text(strings.overlayPermissionBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              strings.overlayPermissionAction,
              style: const TextStyle(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
    if (ask == true) {
      await OverlayController.requestPermission();
    }
    await _updateOverlayPermission();
    if (!_overlayPermissionGranted) {
      _showError(strings.overlayPermissionSnack);
      return false;
    }
    return true;
  }

  Future<bool> _startOverlayService({bool minimizeApp = false}) async {
    if (_overlayActive) return true;
    try {
      final started = await OverlayController.start();
      if (!started) {
        _showError(_strings.overlayStartError);
        return false;
      }
      if (mounted) {
        setState(() => _overlayActive = true);
      }
      if (minimizeApp) {
        SystemNavigator.pop();
      }
      return true;
    } catch (_) {
      _showError(_strings.overlayStartError);
      return false;
    }
  }

  Future<void> _stopOverlayService() async {
    if (!_overlayActive) return;
    try {
      await OverlayController.stop();
    } catch (_) {}
    if (mounted) {
      setState(() => _overlayActive = false);
    }
  }

  Future<void> _toggleOverlayService() async {
    if (_overlayActive) {
      await _stopOverlayService();
      return;
    }
    final allowed = await _ensureOverlayPermission();
    if (!allowed) return;
    await _startOverlayService();
  }

  Future<void> _maybeStartOverlayService() async {
    debugPrint(
        'maybeStartOverlayService auto=$_overlayAutoStart session=$_sessionActive overlayActive=$_overlayActive');
    if (!_overlayAutoStart || !_sessionActive || _overlayActive) {
      return;
    }
    final allowed = await _ensureOverlayPermission();
    if (!allowed) return;
    await _startOverlayService(minimizeApp: true);
  }

  Future<void> _promptFeedback(
    String sessionId, {
    String? champion,
    String? lane,
  }) async {
    if (!mounted) return;
    final strings = _strings;
    final choice = await showModalBottomSheet<_FeedbackRating>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.feedbackTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                strings.feedbackDescription,
                style: const TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.of(sheetContext).pop(_FeedbackRating.good),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.background,
                        elevation: 0,
                      ),
                      child: Text(strings.feedbackGood),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.of(sheetContext).pop(_FeedbackRating.bad),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: Text(strings.feedbackBad),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    if (choice == null) return;
    final rating = choice == _FeedbackRating.good ? 'good' : 'bad';
    final payload = <String, String>{};
    if (champion != null) payload['champion'] = champion;
    if (lane != null) payload['lane'] = lane;
    try {
      await _api.submitFeedback(
        sessionId: sessionId,
        rating: rating,
        context: payload.isEmpty ? null : payload,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.feedbackThanks),
          backgroundColor: AppColors.surface,
        ),
      );
    } catch (_) {
      // ignore feedback errors
    }
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
