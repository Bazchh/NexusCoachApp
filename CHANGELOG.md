# Changelog

Todas as mudancas notaveis deste projeto serao documentadas neste arquivo.

O formato e baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/).

## [Unreleased]

## [0.1.0] - 2025-01

### Adicionado

#### Flutter App
- Estrutura inicial do app Flutter
- Tela principal "Coach Ao Vivo" (coach_home)
- Sistema de cores e tema personalizado
- Strings internacionalizadas (PT-BR e EN-US)

#### Componentes UI
- TopRow: header com status e botao de configuracoes
- PrimaryAction: botao principal iniciar/parar sessao
- QuickInput: campo de entrada de texto rapido
- HistoryCard: exibicao de historico de conversas
- EndButton: botao para encerrar sessao
- SliderTile: controle deslizante para intervalos

#### Servicos Nativos (Android/Kotlin)
- MainActivity com Platform Channels
- OverlayService: botao flutuante sobre outros apps
  - Arraste pela tela
  - Toggle masculino/feminino (M/W)
  - Comunicacao bidirecional com Flutter
- MinimapReminderService: alertas periodicos de minimapa
  - Intervalo configuravel (5-60 segundos)
- WardReminderService: alertas de ward
  - Intervalo fixo de 50 segundos

#### Tutorial Guiado
- Implementacao com tutorial_coach_mark
- 3 etapas: Botao iniciar, Configuracoes, Overlay demo
- Overlay demo em Flutter para demonstracao
- Persistencia de estado (mostra apenas na primeira vez)

#### Telas de Configuracoes
- LanguageVoiceScreen: idioma e configuracoes de voz
- PrivacyScreen: politica de privacidade

#### Integracao
- Cliente HTTP para comunicacao com NexusCoachApi
- Modelos de dados para sessao e respostas

### Permissoes Android
- SYSTEM_ALERT_WINDOW para overlay
- FOREGROUND_SERVICE para servicos em background
- RECORD_AUDIO para reconhecimento de voz
- INTERNET para comunicacao com API
