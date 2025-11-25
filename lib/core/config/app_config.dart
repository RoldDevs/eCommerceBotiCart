/// Application configuration and feature flags
class AppConfig {
  /// Feature flag to enable/disable home delivery
  /// Set to false to disable delivery functionality (pickup only mode)
  static const bool isDeliveryEnabled = false;

  /// Private constructor to prevent instantiation
  AppConfig._();
}
