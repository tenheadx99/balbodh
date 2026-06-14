class AdConfig {
  AdConfig._();

  static bool get useTestAds => true;

  static String get appId => useTestAds
      ? 'ca-app-pub-3940256099942544~3347511713'
      : 'ca-app-pub-xxxxxxxxxxxxx~xxxxxxxxx';

  // Banner is the only ad format used — the app is in the Families
  // program, which forbids interstitial & rewarded (full-screen) ads.
  static String get bannerHomeId => useTestAds
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-xxxxxxxxxxxxx/xxxxxxxxx';
}
