
import 'package:flutter/material.dart';
import 'package:marketing_companion_web/screens/discover_page.dart';
import 'package:marketing_companion_web/screens/artisan_profile_page.dart';
import 'package:marketing_companion_web/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:marketing_companion_web/screens/product_detail_page.dart';

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

  Widget _initialPage(Uri uri) {
    final productId = uri.queryParameters['product'];
    final artisanId = uri.queryParameters['artisan'];

    if (productId != null && productId.isNotEmpty) {
      return PublicProductLinkPage(productId: productId);
    }

    if (artisanId != null && artisanId.isNotEmpty) {
      return ArtisanProfilePage(ownerId: artisanId);
    }

    return const DiscoverPage();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Artisan Marketplace',
      theme: AppTheme.themeData,
      home: _initialPage(Uri.base),
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '/');

        final productId = uri.queryParameters['product'];
        final artisanId = uri.queryParameters['artisan'];

        if (productId != null && productId.isNotEmpty) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => PublicProductLinkPage(productId: productId),
          );
        }

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

class PublicProductLinkPage extends StatefulWidget {
  final String productId;

  const PublicProductLinkPage({
    super.key,
    required this.productId,
  });

  @override
  State<PublicProductLinkPage> createState() =>
      _PublicProductLinkPageState();
}

class _PublicProductLinkPageState extends State<PublicProductLinkPage> {
  late Future<Map<String, dynamic>?> productFuture;

  @override
  void initState() {
    super.initState();
    productFuture = fetchProduct();
  }

  Future<Map<String, dynamic>?> fetchProduct() async {
    final response = await Supabase.instance.client
        .from('products')
        .select('*, product_images(*)')
        .eq('id', widget.productId)
        .eq('status', 'published')
        .maybeSingle();

    if (response == null) return null;

    return Map<String, dynamic>.from(response);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: productFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Product unavailable')),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'This product is unavailable or is no longer published.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        return ProductDetailPage(product: snapshot.data!);
      },
    );
  }
}