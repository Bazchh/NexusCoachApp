import 'package:flutter_tts/flutter_tts.dart';

/// Controller para Text-to-Speech usando API nativa do Android
class TtsController {
  TtsController._();

  static final FlutterTts _tts = FlutterTts();
  static bool _initialized = false;
  static double _volume = 1.0;
  static double _speechRate = 0.5;
  static String _language = 'en-US';
  static bool _isMale = false;

  /// Inicializa o TTS com as configurações padrão
  static Future<void> init({
    double volume = 1.0,
    double speechRate = 0.5,
    String language = 'en-US',
    bool isMale = false,
  }) async {
    _volume = volume;
    _speechRate = speechRate;
    _language = language;
    _isMale = isMale;

    await _tts.setVolume(_volume);
    await _tts.setSpeechRate(_speechRate);
    await _tts.setLanguage(_language);
    await _selectVoice();

    _initialized = true;
  }

  /// Seleciona a voz baseado no idioma e gênero
  static Future<void> _selectVoice() async {
    final voices = await _tts.getVoices;
    if (voices == null) return;

    final voiceList = List<Map<dynamic, dynamic>>.from(voices);

    // Filtra vozes pelo idioma
    final langVoices = voiceList.where((v) {
      final locale = v['locale']?.toString() ?? '';
      return locale.startsWith(_language.split('-')[0]);
    }).toList();

    if (langVoices.isEmpty) return;

    // Tenta encontrar voz do gênero desejado
    // Android geralmente não expõe gênero diretamente, mas podemos tentar
    // por nome (alguns contêm "male"/"female" ou nomes femininos/masculinos)
    Map<dynamic, dynamic>? selectedVoice;

    for (final voice in langVoices) {
      final name = (voice['name']?.toString() ?? '').toLowerCase();
      if (_isMale) {
        if (name.contains('male') && !name.contains('female')) {
          selectedVoice = voice;
          break;
        }
      } else {
        if (name.contains('female') || name.contains('mulher')) {
          selectedVoice = voice;
          break;
        }
      }
    }

    // Se não encontrou por gênero, usa a primeira disponível
    selectedVoice ??= langVoices.first;

    final voiceName = selectedVoice['name']?.toString();
    if (voiceName != null) {
      await _tts.setVoice({'name': voiceName, 'locale': _language});
    }
  }

  /// Atualiza o volume (0.0 a 1.0)
  static Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _tts.setVolume(_volume);
  }

  /// Atualiza a velocidade da fala (0.0 a 1.0, onde 0.5 é normal)
  static Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.0, 1.0);
    await _tts.setSpeechRate(_speechRate);
  }

  /// Atualiza o idioma
  static Future<void> setLanguage(String language) async {
    _language = language;
    await _tts.setLanguage(_language);
    await _selectVoice();
  }

  /// Atualiza o gênero da voz
  static Future<void> setGender({required bool isMale}) async {
    _isMale = isMale;
    await _selectVoice();
  }

  /// Fala o texto fornecido
  static Future<void> speak(String text) async {
    if (!_initialized) {
      await init();
    }
    if (text.trim().isEmpty) return;
    await _tts.speak(text);
  }

  /// Para a fala atual
  static Future<void> stop() async {
    await _tts.stop();
  }

  /// Verifica se está falando
  static Future<bool> get isSpeaking async {
    // flutter_tts não tem getter direto, retornamos false por segurança
    return false;
  }

  /// Libera recursos
  static Future<void> dispose() async {
    await _tts.stop();
    _initialized = false;
  }
}
