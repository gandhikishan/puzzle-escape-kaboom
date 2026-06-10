import 'package:shared_preferences/shared_preferences.dart';

/// Thin, typed wrapper around [SharedPreferences] for all on-device persistence.
/// Everything the game saves (progress + settings) is local and free.
class StorageService {
  StorageService(this._prefs);

  final SharedPreferences _prefs;

  static const _kCurrentStage = 'current_stage';
  static const _kHighestStage = 'highest_stage';
  static const _kSoundOn = 'sound_on';
  static const _kStagesCleared = 'stages_cleared';
  static const _kHints = 'hints';
  static const _kLastFreeHint = 'last_free_hint_ymd';

  static const int defaultStartingHints = 3;

  int get currentStage => _prefs.getInt(_kCurrentStage) ?? 1;
  int get highestStage => _prefs.getInt(_kHighestStage) ?? 1;
  bool get soundOn => _prefs.getBool(_kSoundOn) ?? true;

  /// Total stages cleared across all sessions; used to pace interstitial ads.
  int get stagesCleared => _prefs.getInt(_kStagesCleared) ?? 0;

  /// Hints the player currently owns.
  int get hints => _prefs.getInt(_kHints) ?? defaultStartingHints;

  /// Calendar day (yyyy-mm-dd) the last free daily hint was granted.
  String get lastFreeHintDay => _prefs.getString(_kLastFreeHint) ?? '';

  Future<void> setCurrentStage(int value) =>
      _prefs.setInt(_kCurrentStage, value);
  Future<void> setHighestStage(int value) =>
      _prefs.setInt(_kHighestStage, value);
  Future<void> setSoundOn(bool value) => _prefs.setBool(_kSoundOn, value);
  Future<void> setStagesCleared(int value) =>
      _prefs.setInt(_kStagesCleared, value);
  Future<void> setHints(int value) => _prefs.setInt(_kHints, value);
  Future<void> setLastFreeHintDay(String ymd) =>
      _prefs.setString(_kLastFreeHint, ymd);

  /// Sends the player back to Stage 1 while preserving the best-reached badge.
  Future<void> resetProgress() async {
    await _prefs.setInt(_kCurrentStage, 1);
    await _prefs.setInt(_kStagesCleared, 0);
  }
}
