import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ads/ads_service.dart';
import 'app.dart';
import 'levels/level_repository.dart';
import 'services/firebase_service.dart';
import 'services/storage_service.dart';
import 'state/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final prefs = await SharedPreferences.getInstance();
  final storage = StorageService(prefs);

  final repository = LevelRepository();
  await repository.ensureLoaded();

  final firebase = FirebaseService();
  await firebase.init();

  final ads = AdsService();
  ads.interstitialEveryNStages = firebase.interstitialEveryNStages;
  // Fire-and-forget: ads load in the background and are not required for play.
  unawaited(ads.init());

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
        levelRepositoryProvider.overrideWithValue(repository),
        adsServiceProvider.overrideWithValue(ads),
        firebaseServiceProvider.overrideWithValue(firebase),
      ],
      child: const BombsAndPuzzlesApp(),
    ),
  );
}
