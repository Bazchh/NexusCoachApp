// ignore_for_file: invalid_use_of_protected_member
part of 'coach_home.dart';

extension _CoachHomeStateSession on _CoachHomeState {
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
    await TtsController.stop();
    final feedbackPayload = await _promptFeedback();
    final feedbackRating = feedbackPayload?.rating;
    final feedbackComment = feedbackPayload?.comment;

    setState(() => _busy = true);
    await _stopVoiceInput();
    try {
      // Envia endSession COM o feedback (se fornecido)
      await _api.endSession(
        sessionId,
        feedbackRating: feedbackRating,
        feedbackComment: feedbackComment,
      );
      await _finalizeSessionAfterEnd(strings, feedbackRating);
    } on ApiException catch (error) {
      final message = error.message.toLowerCase();
      final alreadyEnded = message.contains('sessão encerrada') ||
          message.contains('session ended') ||
          message.contains('session already ended');
      if (alreadyEnded) {
        await _finalizeSessionAfterEnd(strings, feedbackRating);
      } else {
        _showError(error.message);
      }
    } catch (_) {
      _showError(strings.errorEndFailed);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _finalizeSessionAfterEnd(
    AppStrings strings,
    String? feedbackRating,
  ) async {
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
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.accent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.feedbackThanks,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.backgroundAlt,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          duration: const Duration(seconds: 2),
        ),
      );
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

  /// Mostra modal de feedback e retorna o rating selecionado (ou null se cancelado)
  Future<_FeedbackPayload?> _promptFeedback() async {
    if (!mounted) return null;
    final strings = _strings;
    final commentController = TextEditingController();
    final choice = await showModalBottomSheet<_FeedbackPayload>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      useSafeArea: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).padding.bottom;
        final keyboardInset = MediaQuery.of(sheetContext).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, 20 + bottomInset + keyboardInset),
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
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: strings.feedbackCommentHint,
                  filled: true,
                  fillColor: AppColors.backgroundAlt,
                  border: const OutlineInputBorder(),
                ),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(sheetContext).pop(
                          _FeedbackPayload(
                            rating: 'good',
                            comment: commentController.text.trim(),
                          ),
                        );
                      },
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
                      onPressed: () {
                        Navigator.of(sheetContext).pop(
                          _FeedbackPayload(
                            rating: 'bad',
                            comment: commentController.text.trim(),
                          ),
                        );
                      },
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
    return choice;
  }
}

class _FeedbackPayload {
  const _FeedbackPayload({required this.rating, this.comment});

  final String rating;
  final String? comment;
}
