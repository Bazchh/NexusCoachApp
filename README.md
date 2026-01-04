# NexusCoach App

Aplicativo mobile do NexusCoach - Coach de voz inteligente para Wild Rift.

## Sobre

Aplicativo Flutter com servicos nativos Android para coaching em tempo real durante partidas de Wild Rift. O app funciona como um overlay sobre o jogo, permitindo interacao por voz sem sair da partida.

## Funcionalidades

- **Overlay Flutuante** - Botao que fica sobre o jogo para acesso rapido
- **Reconhecimento de Voz** - Fale suas duvidas sem digitar
- **Sintese de Voz (TTS)** - Respostas faladas pelo coach
- **Lembrete de Minimapa** - Alertas periodicos para olhar o mapa
- **Lembrete de Ward** - Alerta a cada 50 segundos para colocar ward
- **Tutorial Guiado** - Onboarding interativo para novos usuarios
- **Suporte a Idiomas** - Portugues (BR) e Ingles (US)

## Tecnologias

- Flutter 3.x
- Dart 3.x
- Android Native (Kotlin)
- Platform Channels (Flutter <-> Android)
- SharedPreferences
- HTTP (dio)

## Requisitos

- Flutter SDK 3.0+
- Android SDK 21+ (Android 5.0 Lollipop)
- Android Studio ou VS Code com extensao Flutter

## Instalacao

```bash
# Clonar o repositorio
git clone https://github.com/seu-usuario/NexusCoachApp.git
cd NexusCoachApp

# Instalar dependencias
flutter pub get

# Executar em dispositivo/emulador
flutter run
```

## Configuracao

### Conexao com a API

Configure o endpoint da API em `lib/services/nexus_api.dart`:

```dart
static const String _baseUrl = 'http://seu-servidor:8000';
```

Para desenvolvimento local com dispositivo fisico, use o IP da sua maquina na rede local.

### Permissoes Android

O app requer as seguintes permissoes (ja configuradas no AndroidManifest.xml):

| Permissao | Uso |
|-----------|-----|
| `SYSTEM_ALERT_WINDOW` | Overlay sobre outros apps |
| `FOREGROUND_SERVICE` | Servicos em background |
| `RECORD_AUDIO` | Reconhecimento de voz |
| `INTERNET` | Comunicacao com a API |

## Estrutura do Projeto

```
lib/
├── main.dart                    # Entry point
├── app/
│   ├── nexuscoach_app.dart     # MaterialApp e configuracoes
│   ├── app_colors.dart         # Tema de cores
│   └── app_strings.dart        # Textos internacionalizados
├── features/
│   ├── coach/
│   │   ├── coach_home.dart     # Tela principal + tutorial
│   │   └── widgets/
│   │       ├── top_row.dart        # Header com settings
│   │       ├── primary_action.dart # Botao iniciar/parar
│   │       ├── quick_input.dart    # Input de texto rapido
│   │       ├── history_card.dart   # Card de historico
│   │       ├── end_button.dart     # Botao encerrar
│   │       └── slider_tile.dart    # Slider para intervalos
│   └── settings/
│       ├── language_voice_screen.dart  # Config de idioma/voz
│       └── privacy_screen.dart         # Politica de privacidade
├── services/
│   ├── nexus_api.dart               # Cliente HTTP da API
│   ├── overlay_controller.dart      # Controle do overlay nativo
│   ├── minimap_reminder_controller.dart  # Controle lembretes mapa
│   └── ward_reminder_controller.dart     # Controle lembretes ward
└── models/
    └── session_models.dart          # Modelos de dados

android/app/src/main/kotlin/com/nexuscoach/nexuscoach/
├── MainActivity.kt          # Activity principal + Platform Channels
├── OverlayService.kt        # Servico do botao flutuante
├── MinimapReminderService.kt # Servico de lembretes de mapa
└── WardReminderService.kt    # Servico de lembretes de ward
```

## Arquitetura

### Flutter <-> Android Communication

```
┌─────────────────────────────────────────────────────────┐
│                     Flutter Layer                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ coach_home   │  │ overlay_ctrl │  │ reminder_ctrl│  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│          │                 │                 │          │
│          └─────────────────┼─────────────────┘          │
│                            │                            │
│                   MethodChannel                         │
│              'com.nexuscoach/overlay'                   │
└────────────────────────────┬────────────────────────────┘
                             │
┌────────────────────────────┼────────────────────────────┐
│                     Android Layer                        │
│                            │                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ MainActivity │──│OverlayService│  │ReminderServce│  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│                            │                            │
│                    System Alert Window                  │
│                    (Overlay sobre jogo)                 │
└─────────────────────────────────────────────────────────┘
```

### Overlay Service

O `OverlayService.kt` cria um botao flutuante que:

1. Permanece sobre outros apps (incluindo jogos)
2. Pode ser arrastado pela tela
3. Expande para mostrar opcoes (toggle masculino/feminino)
4. Comunica acoes de volta ao Flutter via broadcast

### Servicos de Lembrete

- **MinimapReminderService**: Toca alerta em intervalo configuravel (5-60s)
- **WardReminderService**: Toca alerta fixo a cada 50 segundos

## Fluxo de Uso

```
1. Usuario abre o app
         │
         ▼
2. Tutorial guiado (primeira vez)
         │
         ▼
3. Seleciona campeao, lane, inimigo
         │
         ▼
4. Toca "Iniciar Partida"
         │
         ▼
5. Overlay aparece sobre o jogo
         │
         ▼
6. Usuario interage por voz
         │
         ▼
7. API processa e responde
         │
         ▼
8. TTS fala a resposta
         │
         ▼
9. Usuario encerra ao fim da partida
```

## Tutorial Guiado

O app inclui um tutorial interativo (spotlight/coach marks) que apresenta:

1. **Botao Iniciar** - Como comecar uma sessao
2. **Configuracoes** - Onde ajustar idioma e voz
3. **Overlay Demo** - Demonstracao do botao flutuante

O tutorial usa a biblioteca `tutorial_coach_mark` e aparece apenas na primeira execucao (salvo em SharedPreferences).

## Build

### Debug

```bash
flutter run --debug
```

### Release APK

```bash
flutter build apk --release
```

O APK sera gerado em `build/app/outputs/flutter-apk/app-release.apk`

### Release Bundle (Play Store)

```bash
flutter build appbundle --release
```

## Testes

```bash
# Testes unitarios
flutter test

# Analise estatica
flutter analyze
```

## Troubleshooting

### Overlay nao aparece

1. Verifique se a permissao "Exibir sobre outros apps" foi concedida
2. Acesse: Configuracoes > Apps > NexusCoach > Permissoes > Exibir sobre outros apps

### Voz nao funciona

1. Verifique permissao de microfone
2. Verifique conexao com a internet
3. Verifique se a API esta rodando

### App fecha ao minimizar

Isso e esperado - o overlay continua funcionando. O app pode ser reaberto a qualquer momento.

## Contribuindo

1. Fork o repositorio
2. Crie uma branch (`git checkout -b feature/nova-funcionalidade`)
3. Commit suas mudancas (`git commit -m 'Adiciona nova funcionalidade'`)
4. Push para a branch (`git push origin feature/nova-funcionalidade`)
5. Abra um Pull Request

## Disclaimer

Este projeto nao e afiliado a Riot Games. Wild Rift e marca registrada da Riot Games.
