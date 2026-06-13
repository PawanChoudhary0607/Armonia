// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:armonia/core/routes/app_router.dart';
import 'package:armonia/core/theme/app_theme.dart';
import 'package:armonia/providers/settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Resolve SharedPreferences BEFORE runApp(). This lets SettingsNotifier's
  // build() synchronously read persisted values on first construction,
  // avoiding any post-construction state mutation during the initial
  // widget tree build (which previously caused a `!_dirty is not true`
  // assertion when settings were loaded from initState()).
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
