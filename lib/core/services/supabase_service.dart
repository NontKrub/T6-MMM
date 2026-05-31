import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

class SupabaseService {
  static SupabaseClient? get client {
    if (!AppConfig.isSupabaseConfigured) return null;
    return Supabase.instance.client;
  }

  static bool get isSignedIn => client?.auth.currentSession != null;
}
