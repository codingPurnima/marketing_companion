
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductImageUrls {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static String? normalizePath(String? rawPath) {
    if (rawPath == null || rawPath.trim().isEmpty) return null;

    var path = rawPath.trim();

    // Remove accidental leading slashes.
    while (path.startsWith('/')) {
      path = path.substring(1);
    }

    // Remove bucket prefix if it is already included.
    if (path.startsWith('product-images/')) {
      path = path.substring('product-images/'.length);
    }

    return path.isEmpty ? null : path;
  }

  static Future<String?> getUrl(Map<String, dynamic> image) async {
    final originalPath = normalizePath(
      image['storage_path']?.toString(),
    );

    final enhancedPath = normalizePath(
      image['enhanced_storage_path']?.toString(),
    );

    final useEnhanced =
        image['is_enhanced_selected'] == true &&
        enhancedPath != null;

    // Try the selected image first.
    final primaryPath = useEnhanced ? enhancedPath : originalPath;

    // If enhanced is selected, fall back to the original image.
    final fallbackPath = useEnhanced ? originalPath : null;

    if (primaryPath == null) return null;

    try {
      return await _supabase.storage
          .from('product-images')
          .createSignedUrl(primaryPath, 3600);
    } catch (e) {
      debugPrint('Primary image URL error: $e');
    }

    if (fallbackPath != null) {
      try {
        return await _supabase.storage
            .from('product-images')
            .createSignedUrl(fallbackPath, 3600);
      } catch (e) {
        debugPrint('Original image fallback error: $e');
      }
    }

    return null;
  }
}
