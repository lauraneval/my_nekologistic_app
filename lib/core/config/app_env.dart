class AppEnv {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// REST API base URL. Falls back to production when not provided via --dart-define.
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://nekologistic.lauraneval.dev',
  );

  static const enableActivityLogs = bool.fromEnvironment(
    'ENABLE_ACTIVITY_LOGS',
    defaultValue: true,
  );
  static const activityLogPath = String.fromEnvironment(
    'ACTIVITY_LOG_PATH',
    defaultValue: '/courier/activity-logs',
  );
  static const activityLogQueueMaxItems = int.fromEnvironment(
    'ACTIVITY_LOG_QUEUE_MAX_ITEMS',
    defaultValue: 100,
  );
  static const activityLogQueueMaxRetry = int.fromEnvironment(
    'ACTIVITY_LOG_QUEUE_MAX_RETRY',
    defaultValue: 5,
  );
  static const maxDeliveryDistanceMeters = int.fromEnvironment(
    'MAX_DELIVERY_DISTANCE_METERS',
    defaultValue: 100,
  );
  static const podBucket = String.fromEnvironment(
    'POD_BUCKET',
    defaultValue: 'proof-of-delivery',
  );
}
