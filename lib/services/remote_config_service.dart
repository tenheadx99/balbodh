import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/ad_config.dart';

/// Reads remote config variables from Firebase Remote Config so ads can
/// be turned off or ad IDs can be configured in production without shipping
/// an update.
///
/// Fail-open: if Firebase isn't configured or the fetch fails, ads stay
/// enabled and fallback to local AdConfig values.
class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  static const String _adsEnabledKey = 'balbodh_ads_enabled';
  static const String _adAppIdKey = 'balbodh_ad_app_id';
  static const String _adBannerHomeIdKey = 'balbodh_ad_banner_home_id';

  static const bool _adsEnabledDefault = true; // fail-open

  FirebaseRemoteConfig? _remoteConfig;
  bool _ready = false;

  /// Whether ads may be shown. Returns the fail-open default until a remote
  /// value has been fetched and activated.
  bool get adsEnabled {
    if (!_ready || _remoteConfig == null) return _adsEnabledDefault;
    return _remoteConfig!.getBool(_adsEnabledKey);
  }

  /// Dynamic AdMob App ID.
  String get appId {
    if (!_ready || _remoteConfig == null) return AdConfig.appId;
    final value = _remoteConfig!.getString(_adAppIdKey);
    return value.isNotEmpty ? value : AdConfig.appId;
  }

  /// Dynamic Banner Ad Unit ID.
  String get bannerHomeId {
    if (!_ready || _remoteConfig == null) return AdConfig.bannerHomeId;
    final value = _remoteConfig!.getString(_adBannerHomeIdKey);
    return value.isNotEmpty ? value : AdConfig.bannerHomeId;
  }

  /// Must be called after Firebase.initializeApp(). Safe to call when Firebase
  /// is unavailable — it simply leaves the service in its fail-open state.
  Future<void> init() async {
    try {
      final rc = FirebaseRemoteConfig.instance;
      await rc.setDefaults({
        _adsEnabledKey: _adsEnabledDefault,
        _adAppIdKey: AdConfig.appId,
        _adBannerHomeIdKey: AdConfig.bannerHomeId,
      });
      await rc.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          // Responsive enough for a kill-switch/update without hitting throttling.
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );
      await rc.fetchAndActivate();
      _remoteConfig = rc;
      _ready = true;
    } catch (e) {
      // No Firebase config yet, offline, or fetch failed — stay fail-open.
      debugPrint('RemoteConfig unavailable, ads fallback to local defaults: $e');
      _ready = false;
    }
  }
}

