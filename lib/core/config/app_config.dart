/// Application configuration and feature flags
class AppConfig {
  /// Feature flag to enable/disable home delivery
  /// Set to false to disable delivery functionality (pickup only mode)
  static const bool isDeliveryEnabled = false;

  /// Google Maps API Key for directions and map services
  static const String googleMapsApiKey =
      'AIzaSyBCL81M_edUzAedzXTUoUL7bHyM2HHc_aQ';

  /// Private constructor to prevent instantiation
  AppConfig._();
}
