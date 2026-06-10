import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ads/ads_service.dart';
import '../levels/level_repository.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';

/// Provides the singleton [StorageService]. Overridden at app startup with the
/// instance built from an initialized [SharedPreferences].
final storageServiceProvider = Provider<StorageService>(
  (ref) => throw UnimplementedError('storageServiceProvider not overridden'),
);

/// Provides the loaded [LevelRepository]. Overridden at app startup.
final levelRepositoryProvider = Provider<LevelRepository>(
  (ref) => throw UnimplementedError('levelRepositoryProvider not overridden'),
);

/// Provides the [AdsService] singleton. Overridden at app startup.
final adsServiceProvider = Provider<AdsService>(
  (ref) => throw UnimplementedError('adsServiceProvider not overridden'),
);

/// Provides the [FirebaseService] singleton. Overridden at app startup.
final firebaseServiceProvider = Provider<FirebaseService>(
  (ref) => throw UnimplementedError('firebaseServiceProvider not overridden'),
);

/// Player progression: which stage they are on and the furthest reached.
class ProgressState {
  const ProgressState({
    required this.currentStage,
    required this.highestStage,
    required this.stagesCleared,
  });

  final int currentStage;
  final int highestStage;
  final int stagesCleared;

  ProgressState copyWith({
    int? currentStage,
    int? highestStage,
    int? stagesCleared,
  }) =>
      ProgressState(
        currentStage: currentStage ?? this.currentStage,
        highestStage: highestStage ?? this.highestStage,
        stagesCleared: stagesCleared ?? this.stagesCleared,
      );
}

class ProgressNotifier extends Notifier<ProgressState> {
  @override
  ProgressState build() {
    final storage = ref.read(storageServiceProvider);
    return ProgressState(
      currentStage: storage.currentStage,
      highestStage: storage.highestStage,
      stagesCleared: storage.stagesCleared,
    );
  }

  /// Marks the current stage cleared and moves to the next one.
  void advance() {
    final storage = ref.read(storageServiceProvider);
    final next = state.currentStage + 1;
    final highest = max(state.highestStage, next);
    final cleared = state.stagesCleared + 1;

    storage.setCurrentStage(next);
    storage.setHighestStage(highest);
    storage.setStagesCleared(cleared);

    state = state.copyWith(
      currentStage: next,
      highestStage: highest,
      stagesCleared: cleared,
    );
  }

  void reset() {
    final storage = ref.read(storageServiceProvider);
    storage.resetProgress();
    state = const ProgressState(
      currentStage: 1,
      highestStage: 1,
      stagesCleared: 0,
    );
  }
}

final progressProvider =
    NotifierProvider<ProgressNotifier, ProgressState>(ProgressNotifier.new);

/// App settings (currently just sound). Persisted locally.
class SettingsState {
  const SettingsState({required this.soundOn});
  final bool soundOn;
}

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    final storage = ref.read(storageServiceProvider);
    return SettingsState(soundOn: storage.soundOn);
  }

  void toggleSound() {
    final storage = ref.read(storageServiceProvider);
    final value = !state.soundOn;
    storage.setSoundOn(value);
    state = SettingsState(soundOn: value);
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);
