class AppFeatureFlags {
  final bool premiumInsightsEnabled;
  final bool premiumDailyChallengePlusEnabled;

  const AppFeatureFlags({
    this.premiumInsightsEnabled = false,
    this.premiumDailyChallengePlusEnabled = false,
  });

  factory AppFeatureFlags.fromEnv(Map<String, String> env) {
    return AppFeatureFlags(
      premiumInsightsEnabled:
          _parseBool(env['FEATURE_PREMIUM_INSIGHTS_ENABLED']),
      premiumDailyChallengePlusEnabled:
          _parseBool(env['FEATURE_PREMIUM_DAILY_PLUS_ENABLED']),
    );
  }

  static bool _parseBool(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    return normalized == '1' || normalized == 'true' || normalized == 'yes';
  }
}
