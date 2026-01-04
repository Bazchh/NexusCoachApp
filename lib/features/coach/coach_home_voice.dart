// ignore_for_file: invalid_use_of_protected_member
part of 'coach_home.dart';

extension _CoachHomeStateVoice on _CoachHomeState {
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
      await _stopVoiceInputAndSend();
      return;
    }

    final available = await _speech.initialize(
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'done') {
          if (_voiceListening && mounted) {
            _restartListening();
          }
        }
      },
      onError: (error) {
        if (!mounted) return;
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
        setState(() => _textController.text = recognized);
      },
    );
  }

  Future<void> _restartListening() async {
    if (!_voiceListening || !mounted) return;
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
}
