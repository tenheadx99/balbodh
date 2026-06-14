import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'remote_config_service.dart';


/// Banner-only ad service. This app is in Google Play's Families program,
/// which forbids full-screen / unclosable ad formats (interstitial &
/// rewarded video). Only anchored banner ads are used, and every request
/// is forced to child-directed, G-rated content.
class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  bool _initialized = false;
  BannerAd? _bannerAd;

  /// Remote kill-switch. When false, no ad SDK calls are made at all.
  bool get adsEnabled => RemoteConfigService().adsEnabled;

  Future<void> init() async {
    if (_initialized) return;
    if (!adsEnabled) return;

    // Families Policy: tag every ad request as child-directed and cap
    // content to G. Must be set before initialize().
    MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        maxAdContentRating: MaxAdContentRating.g,
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.yes,
        tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.yes,
      ),
    );

    await MobileAds.instance.initialize();
    _initialized = true;
  }

  void loadBanner({
    required void Function(BannerAd) onAdLoaded,
    void Function(Object?)? onAdFailed,
  }) {
    if (!adsEnabled) {
      onAdFailed?.call('Ads disabled by remote config');
      return;
    }
    _bannerAd?.dispose();
    _bannerAd = BannerAd(
      adUnitId: RemoteConfigService().bannerHomeId,
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

  void dispose() {
    _bannerAd?.dispose();
    _bannerAd = null;
  }
}
