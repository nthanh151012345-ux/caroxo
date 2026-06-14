import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static String get url {
    // 1. Try reading from dart-define
    const dartDefineUrl = String.fromEnvironment('SUPABASE_URL');
    if (dartDefineUrl.isNotEmpty) {
      return dartDefineUrl;
    }
    // 2. Try reading from dotenv
    return dotenv.env['SUPABASE_URL'] ?? '';
  }

  static String get anonKey {
    // 1. Try reading from dart-define
    const dartDefineKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (dartDefineKey.isNotEmpty) {
      return dartDefineKey;
    }
    // 2. Try reading from dotenv
    return dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  }

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  static SupabaseClient? get client {
    if (!isConfigured) {
      return null;
    }

    return Supabase.instance.client;
  }

  static Future<void> initialize() async {
    // Attempt to load .env, catch error if file not found or empty (e.g., on Web)
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      debugPrint("Warning: Could not load .env file, trying env: $e");
      try {
        await dotenv.load(fileName: "env");
      } catch (e2) {
        debugPrint("Warning: Could not load env file: $e2");
      }
    }

    final resolvedUrl = url;
    final resolvedKey = anonKey;

    debugPrint("=== SUPABASE CONFIGURATION ===");
    debugPrint("SUPABASE_URL: $resolvedUrl");
    if (resolvedKey.isNotEmpty) {
      final maskedKey = resolvedKey.length > 15
          ? "${resolvedKey.substring(0, 8)}...${resolvedKey.substring(resolvedKey.length - 8)}"
          : "loaded (too short to mask)";
      debugPrint("SUPABASE_ANON_KEY: $maskedKey");
    } else {
      debugPrint("SUPABASE_ANON_KEY: [EMPTY]");
    }
    debugPrint("Is Configured: $isConfigured");
    debugPrint("==============================");

    if (!isConfigured) {
      return;
    }

    await Supabase.initialize(url: resolvedUrl, publishableKey: resolvedKey);
  }
}


