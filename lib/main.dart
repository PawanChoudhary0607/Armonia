// lib/main.dart
//
// Phase 6B — Added SupabaseAuthService.instance.initialize() call.
//
// All other logic is identical to Phase 6A.1:
//   • SharedPreferences resolved before runApp() (avoids !_dirty assertion).
//   • ProviderScope overrides sharedPreferencesProvider with resolved instance.
//   • ArmoniaApp watches settingsProvider for live theme switching.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:armonia/core/routes/app_router.dart';
import 'package:armonia/core/theme/app_theme.dart';
import 'package:armonia/data/repositories/supabase_auth_service.dart';
import 'package:armonia/providers/settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // ── Phase 6B: Initialize Supabase BEFORE SharedPreferences and runApp. ──
  //
  // Replace these placeholder strings with your actual Supabase project URL
  // and anon key from the Supabase Dashboard → Settings → API.
  //
  // SECURITY: The anon key is safe to embed in the client — it is a public
  // key that only allows operations permitted by your Row Level Security
  // policies. Never embed the service_role key in the app.
  await SupabaseAuthService.instance.initialize(
    supabaseUrl: 'https://jyjgwvfszwbsxfkgskri.supabase.co',
    supabaseAnonKey: 'sb_publishable_uBEOBtuR4_Lb5Xqd7LyGyQ__muaCuyC',
  );

  // ── Resolve SharedPreferences before runApp() ────────────────────────────
  //
  // This lets SettingsNotifier's build() synchronously read persisted values
  // on first construction, avoiding the !_dirty assertion during startup.
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const ArmoniaApp(),
    ),
  );
}

/// Root application widget. Watches [settingsProvider] so the entire app
/// re-themes instantly when the user changes theme mode or accent color.
class ArmoniaApp extends ConsumerWidget {
  const ArmoniaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SettingsState settings = ref.watch(settingsProvider);
    final GoRouter router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Armonia',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(settings.accentColor),
      darkTheme: AppTheme.dark(settings.accentColor),
      themeMode: settings.themeMode,
      routerConfig: router,
    );
  }
}
