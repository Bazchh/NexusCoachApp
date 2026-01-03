class AppStrings {
  AppStrings._({
    required this.locale,
    required this.statusIdle,
    required this.statusListening,
    required this.statusPaused,
    required this.statusThinking,
    required this.startButton,
    required this.sessionActiveLabel,
    required this.endButton,
    required this.historyTitle,
    required this.historyEmpty,
    required this.quickInputHint,
    required this.settingsTitle,
    required this.pauseCoachTitle,
    required this.pauseCoachSubtitle,
    required this.micSensitivityTitle,
    required this.coachVolumeTitle,
    required this.languageVoiceTitle,
    required this.privacyTitle,
    required this.startSheetTitle,
    required this.championLabel,
    required this.laneLabel,
    required this.matchupLabel,
    required this.startAction,
    required this.errorChampionRequired,
    required this.errorStartFailed,
    required this.errorEndFailed,
    required this.errorSendFailed,
    required this.errorSessionRequired,
    required this.errorCoachPaused,
    required this.errorMicUnavailable,
    required this.sendTooltip,
    required this.micStartTooltip,
    required this.micStopTooltip,
    required this.systemLabel,
    required this.coachLabel,
    required this.youLabel,
    required this.languageTitle,
    required this.voiceTitle,
    required this.saveLabel,
    required this.languagePortuguese,
    required this.languageEnglish,
    required this.voiceFemale,
    required this.voiceMale,
    required this.privacySummaryTitle,
    required this.privacySummaryBody,
    required this.privacyDataTitle,
    required this.privacyDataBody,
    required this.minimapReminderTitle,
    required this.minimapReminderSubtitle,
    required this.minimapIntervalTitle,
    required this.minimapReminderMessage,
    required this.laneTop,
    required this.laneMid,
    required this.laneBot,
    required this.laneJungle,
    required this.laneSupport,
  });

  final String locale;
  final String statusIdle;
  final String statusListening;
  final String statusPaused;
  final String statusThinking;
  final String startButton;
  final String sessionActiveLabel;
  final String endButton;
  final String historyTitle;
  final String historyEmpty;
  final String quickInputHint;
  final String settingsTitle;
  final String pauseCoachTitle;
  final String pauseCoachSubtitle;
  final String micSensitivityTitle;
  final String coachVolumeTitle;
  final String languageVoiceTitle;
  final String privacyTitle;
  final String startSheetTitle;
  final String championLabel;
  final String laneLabel;
  final String matchupLabel;
  final String startAction;
  final String errorChampionRequired;
  final String errorStartFailed;
  final String errorEndFailed;
  final String errorSendFailed;
  final String errorSessionRequired;
  final String errorCoachPaused;
  final String errorMicUnavailable;
  final String sendTooltip;
  final String micStartTooltip;
  final String micStopTooltip;
  final String systemLabel;
  final String coachLabel;
  final String youLabel;
  final String languageTitle;
  final String voiceTitle;
  final String saveLabel;
  final String languagePortuguese;
  final String languageEnglish;
  final String voiceFemale;
  final String voiceMale;
  final String privacySummaryTitle;
  final String privacySummaryBody;
  final String privacyDataTitle;
  final String privacyDataBody;
  final String minimapReminderTitle;
  final String minimapReminderSubtitle;
  final String minimapIntervalTitle;
  final String minimapReminderMessage;
  final String laneTop;
  final String laneMid;
  final String laneBot;
  final String laneJungle;
  final String laneSupport;

  static AppStrings of(String locale) {
    if (locale.startsWith('en')) {
      return _en;
    }
    return _pt;
  }

  String sessionStarted(String champion, String lane) {
    if (locale.startsWith('en')) {
      return 'Session started: $champion ($lane)';
    }
    return 'Sessão iniciada: $champion ($lane)';
  }

  String get sessionEnded =>
      locale.startsWith('en') ? 'Session ended.' : 'Sessão encerrada.';

  static final _pt = AppStrings._(
    locale: 'pt-BR',
    statusIdle: 'Ocioso',
    statusListening: 'Ouvindo',
    statusPaused: 'Pausado',
    statusThinking: 'Pensando',
    startButton: 'Iniciar partida',
    sessionActiveLabel: 'Partida ativa',
    endButton: 'Encerrar',
    historyTitle: 'Últimas interações',
    historyEmpty: 'Sem interações ainda.',
    quickInputHint: 'Digite para testar',
    settingsTitle: 'Configurações',
    pauseCoachTitle: 'Pausar coach',
    pauseCoachSubtitle: 'Desativa o microfone e respostas',
    micSensitivityTitle: 'Sensibilidade do microfone',
    coachVolumeTitle: 'Volume do coach',
    languageVoiceTitle: 'Idioma e voz',
    privacyTitle: 'Privacidade',
    startSheetTitle: 'Contexto inicial',
    championLabel: 'Campeão',
    laneLabel: 'Rota',
    matchupLabel: 'Matchup (opcional)',
    startAction: 'Iniciar',
    errorChampionRequired: 'Informe o campeão.',
    errorStartFailed: 'Não foi possível iniciar.',
    errorEndFailed: 'Não foi possível encerrar.',
    errorSendFailed: 'Não foi possível enviar.',
    errorSessionRequired: 'Inicie uma partida antes de falar.',
    errorCoachPaused: 'Coach pausado. Ative para continuar.',
    errorMicUnavailable: 'Não foi possível ativar o microfone.',
    sendTooltip: 'Enviar',
    micStartTooltip: 'Falar',
    micStopTooltip: 'Parar',
    systemLabel: 'Sistema',
    coachLabel: 'Coach',
    youLabel: 'Você',
    languageTitle: 'Idioma',
    voiceTitle: 'Voz',
    saveLabel: 'Salvar',
    languagePortuguese: 'Português (pt-BR)',
    languageEnglish: 'Inglês (en-US)',
    voiceFemale: 'Feminina',
    voiceMale: 'Masculina',
    privacySummaryTitle: 'Resumo',
    privacySummaryBody:
        'O NexusCoach não grava áudio bruto. Apenas o texto da sua fala pode '
        'ser armazenado para melhorar as respostas. Você pode encerrar a sessão '
        'a qualquer momento.',
    privacyDataTitle: 'Dados coletados',
    privacyDataBody:
        '- Texto transcrito da conversa\n'
        '- Feedback da sessão (bom/ruim)\n'
        '- Contexto básico da partida (campeão, lane, fase)',
    minimapReminderTitle: 'Lembrete de minimapa',
    minimapReminderSubtitle: 'Avisar periodicamente para olhar o mapa',
    minimapIntervalTitle: 'Intervalo do lembrete',
    minimapReminderMessage: 'Olhe o minimapa',
    laneTop: 'Topo',
    laneMid: 'Meio',
    laneBot: 'Bot',
    laneJungle: 'Selva',
    laneSupport: 'Suporte',
  );
  static final _en = AppStrings._(
    locale: 'en-US',
    statusIdle: 'Idle',
    statusListening: 'Listening',
    statusPaused: 'Paused',
    statusThinking: 'Thinking',
    startButton: 'Start match',
    sessionActiveLabel: 'Match active',
    endButton: 'End',
    historyTitle: 'Latest interactions',
    historyEmpty: 'No interactions yet.',
    quickInputHint: 'Type to test',
    settingsTitle: 'Settings',
    pauseCoachTitle: 'Pause coach',
    pauseCoachSubtitle: 'Disables mic and responses',
    micSensitivityTitle: 'Mic sensitivity',
    coachVolumeTitle: 'Coach volume',
    languageVoiceTitle: 'Language & voice',
    privacyTitle: 'Privacy',
    startSheetTitle: 'Initial context',
    championLabel: 'Champion',
    laneLabel: 'Lane',
    matchupLabel: 'Matchup (optional)',
    startAction: 'Start',
    errorChampionRequired: 'Enter your champion.',
    errorStartFailed: 'Could not start.',
    errorEndFailed: 'Could not end.',
    errorSendFailed: 'Could not send.',
    errorSessionRequired: 'Start a match before speaking.',
    errorCoachPaused: 'Coach is paused. Resume to continue.',
    errorMicUnavailable: 'Microphone unavailable.',
    sendTooltip: 'Send',
    micStartTooltip: 'Speak',
    micStopTooltip: 'Stop',
    systemLabel: 'System',
    coachLabel: 'Coach',
    youLabel: 'You',
    languageTitle: 'Language',
    voiceTitle: 'Voice',
    saveLabel: 'Save',
    languagePortuguese: 'Portuguese (pt-BR)',
    languageEnglish: 'English (en-US)',
    voiceFemale: 'Female',
    voiceMale: 'Male',
    privacySummaryTitle: 'Summary',
    privacySummaryBody:
        'NexusCoach does not store raw audio. Only the transcribed text may be '
        'stored to improve responses. You can end the session at any time.',
    privacyDataTitle: 'Data collected',
    privacyDataBody:
        '- Transcribed conversation text\n'
        '- Session feedback (good/bad)\n'
        '- Basic match context (champion, lane, phase)',
    minimapReminderTitle: 'Minimap reminder',
    minimapReminderSubtitle: 'Periodic reminder to check the map',
    minimapIntervalTitle: 'Reminder interval',
    minimapReminderMessage: 'Check the minimap',
    laneTop: 'Top',
    laneMid: 'Mid',
    laneBot: 'Bot',
    laneJungle: 'Jungle',
    laneSupport: 'Support',
  );
}
