// ignore_for_file: invalid_use_of_protected_member
part of 'coach_home.dart';

extension _CoachHomeStateOverlay on _CoachHomeState {
  Future<void> _updateOverlayPermission() async {
    final granted = await OverlayController.canDrawOverlays();
    if (!mounted) return;
    setState(() => _overlayPermissionGranted = granted);
  }

  void _handleAppResumed() {
    _stopOverlayService();
    _updateOverlayPermission();
  }

  void _handleAppPaused() {
    _maybeStartOverlayService();
  }

  Future<bool> _ensureOverlayPermission() async {
    final strings = _strings;
    final allowed = await OverlayController.canDrawOverlays();
    if (allowed) {
      if (mounted) {
        setState(() => _overlayPermissionGranted = true);
      }
      return true;
    }

    final ask = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(strings.overlayPermissionTitle),
        content: Text(strings.overlayPermissionBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              strings.overlayPermissionAction,
              style: const TextStyle(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
    if (ask == true) {
      await OverlayController.requestPermission();
    }
    await _updateOverlayPermission();
    if (!_overlayPermissionGranted) {
      _showError(strings.overlayPermissionSnack);
      return false;
    }
    return true;
  }

  Future<bool> _startOverlayService({bool minimizeApp = false}) async {
    if (_overlayActive) return true;
    try {
      final started = await OverlayController.start(
        sessionId: _sessionId,
        apiBaseUrl: _apiBaseUrl,
        locale: _language,
      );
      if (!started) {
        _showError(_strings.overlayStartError);
        return false;
      }
      if (mounted) {
        setState(() => _overlayActive = true);
      }
      if (minimizeApp) {
        await OverlayController.minimizeApp();
      }
      return true;
    } catch (_) {
      _showError(_strings.overlayStartError);
      return false;
    }
  }

  Future<void> _stopOverlayService() async {
    if (!_overlayActive) return;
    try {
      await OverlayController.stop();
    } catch (_) {}
    if (mounted) {
      setState(() => _overlayActive = false);
    }
  }

  Future<void> _toggleOverlayService() async {
    if (_overlayActive) {
      await _stopOverlayService();
      return;
    }
    final allowed = await _ensureOverlayPermission();
    if (!allowed) return;
    await _startOverlayService();
  }

  Future<void> _maybeStartOverlayService({bool minimizeApp = false}) async {
    debugPrint(
      'maybeStartOverlayService auto=$_overlayAutoStart session=$_sessionActive overlayActive=$_overlayActive minimize=$minimizeApp',
    );
    if (!_overlayAutoStart || !_sessionActive || _overlayActive) {
      return;
    }
    final allowed = await _ensureOverlayPermission();
    if (!allowed) return;
    await _startOverlayService(minimizeApp: minimizeApp);
  }
}
