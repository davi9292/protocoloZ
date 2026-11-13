class AppConfig {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://nzpespvxaqvxtqsrpvmu.supabase.co',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im56cGVzcHZ4YXF2eHRxc3Jwdm11Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTQ1NDcxMTYsImV4cCI6MjExMDEyMzExNn0.110QGEpqjZZsRMhoQ0oY4E13ckvvLN8rG-61MAHCqas',
  );

  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_NNqDI037-jUIZ6Acwy-Znw_wKk9tw2q',
  );

  static void validate() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw StateError(
        'Configure SUPABASE_URL e SUPABASE_ANON_KEY com --dart-define ou atualize AppConfig.',
      );
    }
  }
}
