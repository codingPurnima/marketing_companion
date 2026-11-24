import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config/app_config.dart';
import 'providers/locale_provider.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (supabaseUrl.isEmpty || supabaseKey.isEmpty || apiBaseUrl.isEmpty) {
    throw StateError(
      'Set SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY and API_BASE_URL.',
    );
  }

  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);

  final localeController = await LocaleController.load();

  runApp(
    ArtisanApp(localeController: localeController),
  );
}