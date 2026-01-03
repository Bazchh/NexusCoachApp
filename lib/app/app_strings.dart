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
    required this.overlayPermissionTitle,
    required this.overlayPermissionBody,
    required this.overlayPermissionAction,
    required this.overlayPermissionSnack,
    required this.overlayTestTitle,
    required this.overlayTestSubtitle,
    required this.overlayTestActionStart,
    required this.overlayTestActionStop,
    required this.overlayAutoStartTitle,
    required this.overlayAutoStartSubtitle,
    required this.overlayStatusActive,
    required this.overlayStatusMissing,
    required this.overlayStartError,
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
    required this.wardReminderTitle,
    required this.wardReminderSubtitle,
    required this.wardIntervalTitle,
    required this.wardReminderMessage,
    required this.laneTop,
    required this.laneMid,
    required this.laneBot,
    required this.laneJungle,
    required this.laneSupport,
    required this.feedbackTitle,
    required this.feedbackDescription,
    required this.feedbackGood,
    required this.feedbackBad,
    required this.feedbackThanks,
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
  final String overlayPermissionTitle;
  final String overlayPermissionBody;
  final String overlayPermissionAction;
  final String overlayPermissionSnack;
  final String overlayTestTitle;
  final String overlayTestSubtitle;
  final String overlayTestActionStart;
  final String overlayTestActionStop;
  final String overlayAutoStartTitle;
  final String overlayAutoStartSubtitle;
  final String overlayStatusActive;
  final String overlayStatusMissing;
  final String overlayStartError;
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
  final String wardReminderTitle;
  final String wardReminderSubtitle;
  final String wardIntervalTitle;
  final String wardReminderMessage;
  final String laneTop;
  final String laneMid;
  final String laneBot;
  final String laneJungle;
  final String laneSupport;
  final String feedbackTitle;
  final String feedbackDescription;
  final String feedbackGood;
  final String feedbackBad;
  final String feedbackThanks;

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
    pauseCoachSubtitle: 'Desativa o microfone e as respostas',
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
    overlayPermissionTitle: 'Permitir sobreposição',
    overlayPermissionBody:
        'Para exibir o botão flutuante durante a partida, permita sobrepor outros apps.',
    overlayPermissionAction: 'Abrir permissões',
    overlayPermissionSnack:
        'Ative a permissão de sobreposição para usar o botão flutuante.',
    overlayTestTitle: 'Botão flutuante',
    overlayTestSubtitle: 'Mostrar ou ocultar a bolha na tela.',
    overlayTestActionStart: 'Ativar',
    overlayTestActionStop: 'Desativar',
    overlayAutoStartTitle: 'Botão flutuante automático',
    overlayAutoStartSubtitle:
        'Ativa a bolha do coach enquanto uma partida estiver em andamento.',
    overlayStatusActive: 'Overlay ativo',
    overlayStatusMissing: 'Permissão de sobreposição necessária.',
    overlayStartError: 'Não foi possível abrir o botão flutuante.',
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
        'O NexusCoach não grava áudio bruto. Apenas o texto da sua fala pode ser armazenado para melhorar as respostas. Você pode encerrar a sessão a qualquer momento.',
    privacyDataTitle: 'Dados coletados',
    privacyDataBody:
        '- Texto transcrito da conversa\n'
        '- Feedback da sessão (bom/ruim)\n'
        '- Contexto básico da partida (campeão, lane, fase)',
    minimapReminderTitle: 'Lembrete de minimapa',
    minimapReminderSubtitle: 'Avisar periodicamente para olhar o mapa',
    minimapIntervalTitle: 'Intervalo do lembrete',
    minimapReminderMessage: 'Olhe o minimapa',
    wardReminderTitle: 'Lembrete de ward',
    wardReminderSubtitle: 'Avisar quando a ward estiver pronta',
    wardIntervalTitle: 'Cooldown da ward',
    wardReminderMessage: 'Coloque uma ward',
    laneTop: 'Topo',
    laneMid: 'Meio',
    laneBot: 'Bot',
    laneJungle: 'Selva',
    laneSupport: 'Suporte',
    feedbackTitle: 'Feedback rápido',
    feedbackDescription: 'Como foi a ajuda do coach nesta partida?',
    feedbackGood: 'Foi útil',
    feedbackBad: 'Não ajudou',
    feedbackThanks: 'Obrigado! Registramos o feedback.',
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
    overlayPermissionTitle: 'Allow overlay',
    overlayPermissionBody:
        'To show the floating button during a match, allow drawing over other apps.',
    overlayPermissionAction: 'Open permissions',
    overlayPermissionSnack:
        'Enable overlay permission to use the floating button.',
    overlayTestTitle: 'Floating button',
    overlayTestSubtitle: 'Show or hide the bubble on screen.',
    overlayTestActionStart: 'Enable',
    overlayTestActionStop: 'Disable',
    overlayAutoStartTitle: 'Floating button auto-start',
    overlayAutoStartSubtitle:
        'Keep the coach bubble running whenever a match is active.',
    overlayStatusActive: 'Overlay active',
    overlayStatusMissing: 'Overlay permission required.',
    overlayStartError: 'Could not open the floating button.',
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
        'NexusCoach does not store raw audio. Only the transcribed text may be stored to improve responses. You can end the session at any time.',
    privacyDataTitle: 'Data collected',
    privacyDataBody:
        '- Transcribed conversation text\n'
        '- Session feedback (good/bad)\n'
        '- Basic match context (champion, lane, phase)',
    minimapReminderTitle: 'Minimap reminder',
    minimapReminderSubtitle: 'Periodic reminder to check the map',
    minimapIntervalTitle: 'Reminder interval',
    minimapReminderMessage: 'Check the minimap',
    wardReminderTitle: 'Ward reminder',
    wardReminderSubtitle: 'Remind when ward is ready',
    wardIntervalTitle: 'Ward cooldown',
    wardReminderMessage: 'Place a ward',
    laneTop: 'Top',
    laneMid: 'Mid',
    laneBot: 'Bot',
    laneJungle: 'Jungle',
    laneSupport: 'Support',
    feedbackTitle: 'Quick feedback',
    feedbackDescription: 'How was the coach in this match?',
    feedbackGood: 'It helped',
    feedbackBad: 'Not useful',
    feedbackThanks: 'Thanks! We logged your response.',
  );
}
