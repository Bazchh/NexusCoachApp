// ignore_for_file: invalid_use_of_protected_member
part of 'coach_home.dart';

extension _CoachHomeStateSettings on _CoachHomeState {
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
                          _saveBool(_CoachHomeState._keyCoachPaused, value);
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
                          _saveDouble(_CoachHomeState._keyMicSensitivity, value);
                        },
                      ),
                      const SizedBox(height: 8),
                      SliderTile(
                        title: strings.coachVolumeTitle,
                        value: _coachVolume,
                        onChanged: (value) {
                          setSheetState(() => _coachVolume = value);
                          setState(() => _coachVolume = value);
                          _saveDouble(_CoachHomeState._keyCoachVolume, value);
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
                          _saveDouble(_CoachHomeState._keySpeechRate, value);
                          TtsController.setSpeechRate(value);
                        },
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        value: _minimapReminder,
                        onChanged: (value) async {
                          setSheetState(() => _minimapReminder = value);
                          setState(() => _minimapReminder = value);
                          _saveBool(_CoachHomeState._keyMinimapReminder, value);
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
                            _saveDouble(_CoachHomeState._keyMinimapInterval, value);
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
                          _saveBool(_CoachHomeState._keyWardReminder, value);
                          await _syncWardReminder();
                        },
                        title: Text(strings.wardReminderTitle),
                        subtitle: Text(
                          '${strings.wardReminderSubtitle} (${_CoachHomeState._wardIntervalFixed}s)',
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
                          _saveBool(_CoachHomeState._keyOverlayAutoStart, value);
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
                            _saveString(_CoachHomeState._keyLanguage, result.language);
                            _saveString(_CoachHomeState._keyVoice, result.voice);
                            await _syncMinimapReminder();
                            await _syncWardReminder();
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
}
