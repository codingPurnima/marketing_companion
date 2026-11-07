
import 'package:flutter/material.dart';
import 'package:marketing_companion_web/screens/discover_page.dart';
import 'package:marketing_companion_web/screens/artisan_profile_page.dart';
import 'package:marketing_companion_web/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    publishableKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(const ArtisanDiscoveryApp());
}


class ArtisanDiscoveryApp extends StatelessWidget {
  const ArtisanDiscoveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final initialArtisanId =
        Uri.base.queryParameters['artisan'];

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Artisan Marketplace',
      theme: AppTheme.themeData,

      home: initialArtisanId != null && initialArtisanId.isNotEmpty
          ? ArtisanProfilePage(ownerId: initialArtisanId)
          : const DiscoverPage(),

      onGenerateRoute: (settings) {
        final routeUri = Uri.parse(settings.name ?? '/');
        final artisanId = routeUri.queryParameters['artisan'];

        if (artisanId != null && artisanId.isNotEmpty) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => ArtisanProfilePage(ownerId: artisanId),
          );
        }

        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const DiscoverPage(),
        );
      },
    );
  }
}