class AdConfig {
  AdConfig._();

  static bool get useTestAds => true;

  static String get appId => useTestAds
      ? 'ca-app-pub-3940256099942544~3347511713'
      : 'ca-app-pub-xxxxxxxxxxxxx~xxxxxxxxx';

  static String get bannerHomeId => useTestAds
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-xxxxxxxxxxxxx/xxxxxxxxx';

  static String get interstitialId => useTestAds
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-xxxxxxxxxxxxx/xxxxxxxxx';

  static String get rewardedId => useTestAds
      ? 'ca-app-pub-3940256099942544/5224354917'
      : 'ca-app-pub-xxxxxxxxxxxxx/xxxxxxxxx';

  static const int maxAdImpressionIntervalMs = 180000;

  static const int maxInterstitialsPerSession = 6;
}
