import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Wraps Google AdMob: interstitials between stages and rewarded video to
/// refill lives. Configured child-directed / max content rating "G" so the app
/// is safe for the 3+ / Designed-for-Families audience.
///
/// Ad unit IDs default to Google's official TEST IDs. Replace [_androidAppId]
/// and the unit IDs with the real ones from the AdMob console before release
/// (and update the APPLICATION_ID in AndroidManifest.xml to match).
class AdsService {
  AdsService({this.useTestAds = true});

  /// When true (default) the Google test ad units are used. Keep true until
  /// real units are created, otherwise the account risks invalid-traffic flags.
  final bool useTestAds;

  static const _testInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const _testRewarded = 'ca-app-pub-3940256099942544/5224354917';

  // TODO(release): paste real AdMob unit IDs here.
  static const _prodInterstitial = _testInterstitial;
  static const _prodRewarded = _testRewarded;

  /// Show an interstitial after every N cleared stages. Tunable at runtime via
  /// Firebase Remote Config.
  int interstitialEveryNStages = 3;

  bool _initialized = false;
  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  int _clearedSinceInterstitial = 0;

  String get _interstitialUnit =>
      useTestAds ? _testInterstitial : _prodInterstitial;
  String get _rewardedUnit => useTestAds ? _testRewarded : _prodRewarded;

  Future<void> init() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.yes,
        tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.yes,
        maxAdContentRating: MaxAdContentRating.g,
      ),
    );
    _initialized = true;
    _loadInterstitial();
    _loadRewarded();
  }

  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: _interstitialUnit,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (error) {
          _interstitial = null;
          debugPrint('Interstitial failed: $error');
        },
      ),
    );
  }

  void _loadRewarded() {
    RewardedAd.load(
      adUnitId: _rewardedUnit,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewarded = ad,
        onAdFailedToLoad: (error) {
          _rewarded = null;
          debugPrint('Rewarded failed: $error');
        },
      ),
    );
  }

  /// Counts a cleared stage and shows an interstitial on the cadence above.
  void onStageCleared() {
    _clearedSinceInterstitial++;
    if (_clearedSinceInterstitial >= interstitialEveryNStages) {
      _clearedSinceInterstitial = 0;
      _showInterstitial();
    }
  }

  void _showInterstitial() {
    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitial = null;
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitial = null;
        _loadInterstitial();
      },
    );
    ad.show();
    _interstitial = null;
  }

  /// Shows a rewarded ad. Resolves true if the reward was earned.
  Future<bool> showRewarded() async {
    final ad = _rewarded;
    if (ad == null) {
      _loadRewarded();
      return false;
    }

    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewarded = null;
        _loadRewarded();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewarded = null;
        _loadRewarded();
      },
    );

    await ad.show(
      onUserEarnedReward: (ad, reward) => earned = true,
    );
    _rewarded = null;
    return earned;
  }

  void dispose() {
    _interstitial?.dispose();
    _rewarded?.dispose();
  }
}
