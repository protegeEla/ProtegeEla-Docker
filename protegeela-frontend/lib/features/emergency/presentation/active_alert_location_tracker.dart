import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_client.dart';
import '../../../core/services/location_service.dart';
import '../../../shared/models/emergency_alert.dart';
import '../../authentication/data/demo_session_repository.dart';
import '../data/emergency_controller.dart';
import '../data/emergency_repository.dart';

/// Refreshes the precise alert location while an alert is active and the app
/// is in the foreground. Background tracking requires a native app and OS
/// background-location permissions; browsers suspend this work in background.
class ActiveAlertLocationTracker extends ConsumerStatefulWidget {
  const ActiveAlertLocationTracker({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ActiveAlertLocationTracker> createState() =>
      _ActiveAlertLocationTrackerState();
}

class _ActiveAlertLocationTrackerState
    extends ConsumerState<ActiveAlertLocationTracker>
    with WidgetsBindingObserver {
  StreamSubscription<void>? _sessionSubscription;
  Timer? _timer;
  EmergencyAlert? _tracked;
  bool _foreground = true;
  bool _capturing = false;
  late bool _authenticated;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final api = ref.read(apiClientProvider);
    _authenticated = api.isAuthenticated;
    _sessionSubscription = api.sessionChanges.listen((_) {
      if (!mounted) return;
      setState(() => _authenticated = api.isAuthenticated);
      if (!_authenticated) _configure(null);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      _restartTimer();
      _capture();
    } else {
      _timer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_authenticated) {
      final alertState = ref.watch(emergencyControllerProvider);
      final demo = ref.watch(demoSessionProvider).valueOrNull == true;
      final next = demo ? null : alertState.valueOrNull?.activeAlert;
      if (_tracked?.id != next?.id) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _tracked?.id != next?.id) _configure(next);
        });
      }
    }
    return widget.child;
  }

  void _configure(EmergencyAlert? alert) {
    _timer?.cancel();
    _tracked = alert?.isActive == true ? alert : null;
    if (_tracked == null) return;
    _restartTimer();
    _capture();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (_foreground && _tracked != null) {
      _timer = Timer.periodic(const Duration(seconds: 15), (_) => _capture());
    }
  }

  Future<void> _capture() async {
    final alert = _tracked;
    if (!_foreground || _capturing || alert == null || !alert.isActive) return;
    _capturing = true;
    try {
      final location = await ref.read(locationServiceProvider).captureCurrent();
      if (!mounted || _tracked?.id != alert.id) return;
      await ref
          .read(emergencyRepositoryProvider)
          .updateLocation(alertId: alert.id, location: location);
      if (mounted && _tracked?.id == alert.id) {
        ref.invalidate(latestAlertLocationProvider(alert.id));
      }
    } catch (_) {
      // Keep the alert active if a fresh position or network is unavailable.
    } finally {
      _capturing = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _sessionSubscription?.cancel();
    super.dispose();
  }
}
