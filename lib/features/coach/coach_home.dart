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
  String _language = 'pt-BR';
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

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    setState(() {
      _coachPaused = prefs.getBool(_keyCoachPaused) ?? _coachPaused;
      _micSensitivity = prefs.getDouble(_keyMicSensitivity) ?? _micSensitivity;
      _coachVolume = prefs.getDouble(_keyCoachVolume) ?? _coachVolume;
      _speechRate = prefs.getDouble(_keySpeechRate) ?? _speechRate;
      _language = prefs.getString(_keyLanguage) ?? _language;
      _voice = prefs.getString(_keyVoice) ?? _voice;
      _minimapReminder = prefs.getBool(_keyMinimapReminder) ?? _minimapReminder;
      _minimapInterval = prefs.getDouble(_keyMinimapInterval) ?? _minimapInterval;
      _wardReminder = prefs.getBool(_keyWardReminder) ?? _wardReminder;
      _overlayAutoStart =
          prefs.getBool(_keyOverlayAutoStart) ?? _overlayAutoStart;
      _sessionId = prefs.getString(_keySessionId);
      _sessionChampion = prefs.getString(_keySessionChampion);
      _sessionLane = prefs.getString(_keySessionLane);
      _sessionActive =
          prefs.getBool(_keySessionActive) ?? (_sessionId != null);
    });
    await _syncMinimapReminder();
    await _syncWardReminder();
    await _updateOverlayPermission();
    await _initTts();

    // Mostrar tutorial na primeira vez
    final tutorialSeen = prefs.getBool(_keyTutorialSeen) ?? false;
    if (!tutorialSeen && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showTutorial();
      });
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

  Future<void> _persistSessionState() async {
    final prefs = await SharedPreferences.getInstance();
    if (_sessionId != null) {
      await prefs.setString(_keySessionId, _sessionId!);
    }
    await prefs.setBool(_keySessionActive, _sessionActive);
    if (_sessionChampion != null) {
      await prefs.setString(_keySessionChampion, _sessionChampion!);
    }
    if (_sessionLane != null) {
      await prefs.setString(_keySessionLane, _sessionLane!);
    }
  }

  Future<void> _clearSessionState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySessionId);
    await prefs.remove(_keySessionActive);
    await prefs.remove(_keySessionChampion);
    await prefs.remove(_keySessionLane);
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
                    left: 24,
                    top: 180,
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
                            await TtsController.stop();
                          }
                          await _syncMinimapReminder();
                          await _syncWardReminder();
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
                          TtsController.setVolume(value);
                        },
                      ),
                      const SizedBox(height: 8),
                      SliderTile(
                        title: strings.speechRateTitle,
                        value: _speechRate,
                        min: 0.25,
                        max: 0.75,
                        onChanged: (value) {
                          setSheetState(() => _speechRate = value);
                          setState(() => _speechRate = value);
                          _saveDouble(_keySpeechRate, value);
                          TtsController.setSpeechRate(value);
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
                        value: _wardReminder,
                        onChanged: (value) async {
                          setSheetState(() => _wardReminder = value);
                          setState(() => _wardReminder = value);
                          _saveBool(_keyWardReminder, value);
                          await _syncWardReminder();
                        },
                        title: Text(strings.wardReminderTitle),
                        subtitle: Text(
                          '${strings.wardReminderSubtitle} (${_wardIntervalFixed}s)',
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                        activeColor: AppColors.accent,
                      ),
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
                            await _syncWardReminder();
                            // Atualiza TTS com novo idioma/voz
                            await TtsController.setLanguage(result.language);
                            await TtsController.setGender(
                              isMale: result.voice == 'Masculina',
                            );
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
      await _persistSessionState();
      await _syncMinimapReminder();
      await _syncWardReminder();
      await _maybeStartOverlayService(minimizeApp: true);
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

    // Primeiro coleta o feedback do usuário
    final feedbackRating = await _promptFeedback();

    setState(() => _busy = true);
    await _stopVoiceInput();
    try {
      // Envia endSession COM o feedback (se fornecido)
      await _api.endSession(
        sessionId,
        feedbackRating: feedbackRating,
      );
      if (!mounted) return;
      setState(() {
        _sessionId = null;
        _sessionActive = false;
        _sessionChampion = null;
        _sessionLane = null;
        _history.add(HistoryEntry(strings.systemLabel, strings.sessionEnded));
      });
      await _clearSessionState();
      await _syncMinimapReminder();
      await _syncWardReminder();
      await _stopOverlayService();

      if (feedbackRating != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.feedbackThanks),
            backgroundColor: AppColors.surface,
          ),
        );
      }
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
      // Fala a resposta do coach
      await _speakResponse(result.replyText);
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

    // Toggle: se está ouvindo, para e envia
    if (_voiceListening) {
      await _stopVoiceInputAndSend();
      return;
    }

    // Inicia gravação
    final available = await _speech.initialize(
      onStatus: (status) {
        if (!mounted) return;
        // Não para automaticamente - só quando usuário clicar de novo
        if (status == 'done') {
          // Se parou por timeout/silêncio, reinicia automaticamente
          if (_voiceListening && mounted) {
            _restartListening();
          }
        }
      },
      onError: (error) {
        if (!mounted) return;
        // Ignora erro de "no speech" - continua ouvindo
        if (error.errorMsg == 'error_no_match' ||
            error.errorMsg == 'error_speech_timeout') {
          if (_voiceListening && mounted) {
            _restartListening();
          }
          return;
        }
        setState(() => _voiceListening = false);
        _showError(strings.errorMicUnavailable);
      },
    );

    if (!available) {
      _showError(strings.errorMicUnavailable);
      return;
    }

    setState(() => _voiceListening = true);
    await _startListening();
  }

  Future<void> _startListening() async {
    await _speech.listen(
      localeId: _language,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      onResult: (result) {
        if (!mounted) return;
        final recognized = result.recognizedWords.trim();
        if (recognized.isEmpty) return;
        // Atualiza o texto em tempo real
        setState(() => _textController.text = recognized);
        // NÃO envia automaticamente - usuário controla
      },
    );
  }

  Future<void> _restartListening() async {
    if (!_voiceListening || !mounted) return;
    // Pequeno delay antes de reiniciar
    await Future.delayed(const Duration(milliseconds: 100));
    if (_voiceListening && mounted) {
      await _startListening();
    }
  }

  Future<void> _stopVoiceInputAndSend() async {
    if (!_voiceListening) return;
    await _speech.stop();
    if (mounted) {
      setState(() => _voiceListening = false);
    }
    // Envia o texto acumulado se houver
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      await _sendTextTurn();
    }
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

  Future<void> _syncWardReminder() async {
    final shouldRun = _wardReminder && _sessionActive && !_coachPaused;
    if (shouldRun) {
      await WardReminderController.start(
        intervalSeconds: _wardIntervalFixed,
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
    await TtsController.stop(); // Para fala anterior antes de iniciar nova
    await TtsController.speak(text);
  }

  Future<void> _updateOverlayPermission() async {
    final granted = await OverlayController.canDrawOverlays();
    if (!mounted) return;
    setState(() => _overlayPermissionGranted = granted);
  }

  void _handleAppResumed() {
    // Sempre para o overlay quando o app volta ao foreground
    // (pode já ter sido parado pelo botão de engrenagem no overlay)
    _stopOverlayService();
    _updateOverlayPermission();
  }

  void _handleAppPaused() {
    _maybeStartOverlayService();
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
      final started = await OverlayController.start(
        sessionId: _sessionId,
        apiBaseUrl: _apiBaseUrl,
        locale: _language,
      );
      if (!started) {
        _showError(_strings.overlayStartError);
        return false;
      }
      if (mounted) {
        setState(() => _overlayActive = true);
      }
      if (minimizeApp) {
        await OverlayController.minimizeApp();
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

  Future<void> _maybeStartOverlayService({bool minimizeApp = false}) async {
    debugPrint(
        'maybeStartOverlayService auto=$_overlayAutoStart session=$_sessionActive overlayActive=$_overlayActive minimize=$minimizeApp');
    if (!_overlayAutoStart || !_sessionActive || _overlayActive) {
      return;
    }
    final allowed = await _ensureOverlayPermission();
    if (!allowed) return;
    await _startOverlayService(minimizeApp: minimizeApp);
  }

  /// Mostra modal de feedback e retorna o rating selecionado (ou null se cancelado)
  Future<String?> _promptFeedback() async {
    if (!mounted) return null;
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
    if (choice == null) return null;
    return choice == _FeedbackRating.good ? 'good' : 'bad';
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

  void _showTutorial() {
    final strings = _strings;

    // Mostra o demo do overlay para o tutorial
    setState(() => _showOverlayDemo = true);

    // Aguarda o widget ser renderizado
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
      // 1. Botão Iniciar Partida
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
      // 2. Botão de Configurações
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
      // 3. Demo do Overlay/Botão Flutuante
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
    await prefs.setBool(_keyTutorialSeen, true);
  }
}

/// Widget de demonstração do overlay para o tutorial
class _OverlayDemo extends StatelessWidget {
  const _OverlayDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 136,
      height: 136,
      child: Stack(
        children: [
          // Botões do menu ao redor
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: Center(child: _MenuButton(label: '✕', enabled: false)),
          ),
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: Center(child: _MenuButton(label: '⚙', enabled: false)),
          ),
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Center(child: _MenuButton(label: 'M', enabled: true)),
          ),
          Positioned(
            left: 8,
            top: 0,
            bottom: 0,
            child: Center(child: _MenuButton(label: 'W', enabled: false)),
          ),
          // Bolha central
          Center(
            child: Container(
              width: 56,
              height: 56,
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
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.label, required this.enabled});

  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
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
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Conteúdo padronizado do tutorial
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
