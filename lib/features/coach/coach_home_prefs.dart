// ignore_for_file: invalid_use_of_protected_member
part of 'coach_home.dart';

extension _CoachHomeStatePrefs on _CoachHomeState {
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    setState(() {
      _coachPaused = prefs.getBool(_CoachHomeState._keyCoachPaused) ?? _coachPaused;
      _micSensitivity = prefs.getDouble(_CoachHomeState._keyMicSensitivity) ?? _micSensitivity;
      _coachVolume = prefs.getDouble(_CoachHomeState._keyCoachVolume) ?? _coachVolume;
      _speechRate = prefs.getDouble(_CoachHomeState._keySpeechRate) ?? _speechRate;
      _language = prefs.getString(_CoachHomeState._keyLanguage) ?? _language;
      _voice = prefs.getString(_CoachHomeState._keyVoice) ?? _voice;
      _minimapReminder = prefs.getBool(_CoachHomeState._keyMinimapReminder) ?? _minimapReminder;
      _minimapInterval = prefs.getDouble(_CoachHomeState._keyMinimapInterval) ?? _minimapInterval;
      _wardReminder = prefs.getBool(_CoachHomeState._keyWardReminder) ?? _wardReminder;
      _overlayAutoStart = prefs.getBool(_CoachHomeState._keyOverlayAutoStart) ?? _overlayAutoStart;
      _sessionId = prefs.getString(_CoachHomeState._keySessionId);
      _sessionChampion = prefs.getString(_CoachHomeState._keySessionChampion);
      _sessionLane = prefs.getString(_CoachHomeState._keySessionLane);
      _sessionActive = prefs.getBool(_CoachHomeState._keySessionActive) ?? (_sessionId != null);
    });
    await _syncMinimapReminder();
    await _syncWardReminder();
    await _updateOverlayPermission();
    await _initTts();

    // Mostrar tutorial na primeira vez
    final tutorialSeen = prefs.getBool(_CoachHomeState._keyTutorialSeen) ?? false;
    if (!tutorialSeen && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showTutorial();
      });
    }
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
      await prefs.setString(_CoachHomeState._keySessionId, _sessionId!);
    }
    await prefs.setBool(_CoachHomeState._keySessionActive, _sessionActive);
    if (_sessionChampion != null) {
      await prefs.setString(_CoachHomeState._keySessionChampion, _sessionChampion!);
    }
    if (_sessionLane != null) {
      await prefs.setString(_CoachHomeState._keySessionLane, _sessionLane!);
    }
  }

  Future<void> _clearSessionState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_CoachHomeState._keySessionId);
    await prefs.remove(_CoachHomeState._keySessionActive);
    await prefs.remove(_CoachHomeState._keySessionChampion);
    await prefs.remove(_CoachHomeState._keySessionLane);
  }
}
