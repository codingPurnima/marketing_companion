
import 'package:flutter/material.dart';
import 'package:marketing_companion_web/screens/discover_page.dart';
import 'package:marketing_companion_web/screens/artisan_profile_page.dart';
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Artisan Marketplace',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B5E3C),
        ),
        useMaterial3: true,
      ),
      onGenerateRoute: (settings) {
          debugPrint('ROUTE RECEIVED: ${settings.name}');

        final uri = Uri.parse(settings.name ?? '/');
          debugPrint('ROUTE QUERY PARAMETERS: ${uri.queryParameters}');

        final artisanId = uri.queryParameters['artisan'];
          debugPrint('ARTISAN ID: $artisanId');


        if (artisanId != null && artisanId.isNotEmpty) {
          debugPrint('OPENING ARTISAN PROFILE FOR: $artisanId');
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
