import 'package:flutter/material.dart';

import '../../app/app_colors.dart';
import '../../app/app_strings.dart';

class LanguageVoiceResult {
  const LanguageVoiceResult({required this.language, required this.voice});

  final String language;
  final String voice;
}

class LanguageVoiceScreen extends StatefulWidget {
  const LanguageVoiceScreen({
    super.key,
    required this.initialLanguage,
    required this.initialVoice,
    required this.strings,
  });

  final String initialLanguage;
  final String initialVoice;
  final AppStrings strings;

  @override
  State<LanguageVoiceScreen> createState() => _LanguageVoiceScreenState();
}

class _LanguageVoiceScreenState extends State<LanguageVoiceScreen> {
  late String _language;
  late String _voice;

  @override
  void initState() {
    super.initState();
    _language = widget.initialLanguage;
    _voice = widget.initialVoice;
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: Text(strings.languageVoiceTitle),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(
                LanguageVoiceResult(language: _language, voice: _voice),
              );
            },
            child: Text(
              strings.saveLabel,
              style: const TextStyle(color: AppColors.accent),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.languageTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            RadioListTile<String>(
              value: 'pt-BR',
              groupValue: _language,
              activeColor: AppColors.accent,
              title: Text(strings.languagePortuguese),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() => _language = value);
              },
            ),
            RadioListTile<String>(
              value: 'en-US',
              groupValue: _language,
              activeColor: AppColors.accent,
              title: Text(strings.languageEnglish),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() => _language = value);
              },
            ),
            const SizedBox(height: 24),
            Text(
              strings.voiceTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            RadioListTile<String>(
              value: 'Feminina',
              groupValue: _voice,
              activeColor: AppColors.accent,
              title: Text(strings.voiceFemale),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() => _voice = value);
              },
            ),
            RadioListTile<String>(
              value: 'Masculina',
              groupValue: _voice,
              activeColor: AppColors.accent,
              title: Text(strings.voiceMale),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() => _voice = value);
              },
            ),
          ],
        ),
      ),
    );
  }
}
