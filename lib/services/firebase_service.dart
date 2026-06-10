import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Wraps the free-tier Firebase services: Analytics, Crashlytics and Remote
/// Config. Everything degrades gracefully: if Firebase has not been configured
/// for the project yet (no `google-services.json` / `firebase_options.dart`),
/// [init] simply marks the service unavailable and the game keeps running.
///
/// To enable Firebase before release, run `flutterfire configure` from the
/// project root (free Spark tier is sufficient for these three products).
class FirebaseService {
  static const _kInterstitialEveryN = 'interstitial_every_n_stages';
  static const _kLivesPerStage = 'lives_per_stage';

  bool available = false;
  FirebaseAnalytics? _analytics;
  FirebaseRemoteConfig? _remoteConfig;

  FirebaseAnalytics? get analytics => _analytics;

  Future<void> init() async {
    try {
      await Firebase.initializeApp();
      _analytics = FirebaseAnalytics.instance;

      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      await _initRemoteConfig();
      available = true;
    } catch (e) {
      available = false;
      debugPrint('Firebase not configured yet, running without it: $e');
    }
  }

  Future<void> _initRemoteConfig() async {
    final rc = FirebaseRemoteConfig.instance;
    await rc.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: const Duration(hours: 6),
    ));
    await rc.setDefaults(const {
      _kInterstitialEveryN: 3,
      _kLivesPerStage: 3,
    });
    try {
      await rc.fetchAndActivate();
    } catch (_) {
      // Offline or first run: defaults are already in effect.
    }
    _remoteConfig = rc;
  }

  int get interstitialEveryNStages =>
      _remoteConfig?.getInt(_kInterstitialEveryN) ?? 3;

  int get livesPerStage => _remoteConfig?.getInt(_kLivesPerStage) ?? 3;

  void logStageStarted(int stage) => _log('stage_started', {'stage': stage});

  void logStageCleared(int stage) => _log('stage_cleared', {'stage': stage});

  void logGameOver(int stage) => _log('game_over', {'stage': stage});

  void _log(String name, Map<String, Object> parameters) {
    if (!available) return;
    _analytics?.logEvent(name: name, parameters: parameters);
  }
}
