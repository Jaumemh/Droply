import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  EnvConfig._();

  static const String _supabaseUrlKey = 'SUPABASE_URL';
  static const String _supabaseAnonKey = 'SUPABASE_ANON_KEY';
  static const String _defaultUrl = 'https://your-project-ref.supabase.co';
  static const String _defaultAnonKey = 'your-anon-key';
  static const String _supabaseUrlFromDefine =
      String.fromEnvironment('SUPABASE_URL');
  static const String _supabaseAnonKeyFromDefine =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  static Future<void> load() async {
    if (dotenv.isInitialized) {
      return;
    }

    try {
      await dotenv.load(fileName: '.env');
    } on Object {
      await dotenv.load(fileName: '.env.example');
    }
  }

  static String? get supabaseUrl => _readOptional(_supabaseUrlKey);
  static String? get supabaseAnonKey => _readOptional(_supabaseAnonKey);
  static bool get isSupabaseConfigured =>
      supabaseUrl != null && supabaseAnonKey != null;

  static String? _readOptional(String key) {
    final fromDefine =
        key == _supabaseUrlKey ? _supabaseUrlFromDefine : _supabaseAnonKeyFromDefine;
    if (fromDefine.isNotEmpty) {
      return fromDefine;
    }

    final value = dotenv.maybeGet(key)?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }

    if ((key == _supabaseUrlKey && value == _defaultUrl) ||
        (key == _supabaseAnonKey && value == _defaultAnonKey)) {
      return null;
    }

    return value;
  }
}
