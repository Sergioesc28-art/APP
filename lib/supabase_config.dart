// lib/supabase_config.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static final SupabaseConfig _instance = SupabaseConfig._internal();

  factory SupabaseConfig() {
    return _instance;
  }

  SupabaseConfig._internal();

  Future<void> init() async {
    await Supabase.initialize(
      url: 'https://wtxjocqptmghpkuddpwp.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind0eGpvY3FwdG1naHBrdWRkcHdwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDIzMzY2NjAsImV4cCI6MjA1NzkxMjY2MH0.gWEpbK7OkhfDDRjxkVfNI6ZYwjmGyCq34oapbqotB_8',
    );
  }
}

final supabase = Supabase.instance.client;
