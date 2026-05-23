import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../core/constants/ad_config.dart';

enum AdPlacement { home, gamesHub, gameComplete, gameOver, levelUp }

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  bool _initialized = false;
  int _lastInterstitialMs = 0;
  int _interstitialCount = 0;

  RewardedAd? _rewardedAd;
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;

  bool _rewardedLoading = false;
  bool _interstitialLoading = false;

  bool get isRewardedAdReady => _rewardedAd != null;

  Future<void> init() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
  }

  void loadBanner({
    required void Function(BannerAd) onAdLoaded,
    void Function(Object?)? onAdFailed,
  }) {
    _bannerAd?.dispose();
    _bannerAd = BannerAd(
      adUnitId: AdConfig.bannerHomeId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => onAdLoaded(ad as BannerAd),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          onAdFailed?.call(error);
        },
      ),
    )..load();
  }

  void disposeBanner() {
    _bannerAd?.dispose();
    _bannerAd = null;
  }

  void loadRewardedAd() {
    if (_rewardedLoading) return;
    _rewardedLoading = true;
    _rewardedAd?.dispose();

    RewardedAd.load(
      adUnitId: AdConfig.rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _rewardedLoading = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
              _preloadRewarded();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _rewardedAd = null;
              _rewardedLoading = false;
            },
          );
        },
        onAdFailedToLoad: (error) {
          _rewardedLoading = false;
          _rewardedAd = null;
        },
      ),
    );
  }

  void _preloadRewarded() {
    Future.delayed(const Duration(seconds: 3), loadRewardedAd);
  }

  void showRewardedAd({required void Function() onRewarded}) {
    if (_rewardedAd == null) {
      loadRewardedAd();
      return;
    }
    _rewardedAd!.show(onUserEarnedReward: (ad, reward) {
      onRewarded();
      _preloadRewarded();
    });
  }

  void loadInterstitial() {
    if (_interstitialLoading) return;
    if (_interstitialCount >= AdConfig.maxInterstitialsPerSession) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastInterstitialMs < AdConfig.maxAdImpressionIntervalMs) return;

    _interstitialLoading = true;
    _interstitialAd?.dispose();

    InterstitialAd.load(
      adUnitId: AdConfig.interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialLoading = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              _interstitialLoading = false;
            },
          );
        },
        onAdFailedToLoad: (error) {
          _interstitialLoading = false;
        },
      ),
    );
  }

  void showInterstitial() {
    if (_interstitialAd == null) {
      loadInterstitial();
      return;
    }
    _lastInterstitialMs = DateTime.now().millisecondsSinceEpoch;
    _interstitialCount++;
    _interstitialAd!.show();
    _interstitialAd = null;
  }

  bool get canShowInterstitial {
    if (_interstitialCount >= AdConfig.maxInterstitialsPerSession) return false;
    final now = DateTime.now().millisecondsSinceEpoch;
    return now - _lastInterstitialMs >= AdConfig.maxAdImpressionIntervalMs;
  }

  void dispose() {
    _bannerAd?.dispose();
    _rewardedAd?.dispose();
    _interstitialAd?.dispose();
    _bannerAd = null;
    _rewardedAd = null;
    _interstitialAd = null;
  }
}
