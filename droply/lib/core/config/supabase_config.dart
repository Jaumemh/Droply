import 'package:supabase_flutter/supabase_flutter.dart';

import 'env.dart';

class SupabaseConfig {
  SupabaseConfig._();

  static Future<bool> initialize() async {
    await EnvConfig.load();

    if (!EnvConfig.isSupabaseConfigured) {
      return false;
    }

    try {
      Supabase.instance.client;
      return true;
    } on AssertionError {
      // Supabase is not initialized yet.
    } on Object {
      // Ignore and initialize below.
    }

    await Supabase.initialize(
      url: EnvConfig.supabaseUrl!,
      anonKey: EnvConfig.supabaseAnonKey!,
    );

    return true;
  }
}
