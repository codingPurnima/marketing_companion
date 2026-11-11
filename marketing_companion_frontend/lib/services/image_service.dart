
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'api_service.dart';

class ImageService {
  final SupabaseClient supabaseClient;
  final ApiService apiService;
  final ImagePicker imagePicker;

  ImageService({
    required this.supabaseClient,
    required this.apiService,
    ImagePicker? imagePicker,
  }) : imagePicker = imagePicker ?? ImagePicker();

  Future<XFile?> pickImage() {
    return imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 2000,
    );
  }

  Future<Uint8List> readImageBytes(XFile image) {
    return image.readAsBytes();
  }

  Future<String> uploadProductImage({
    required String productId,
    required XFile image,
    required Uint8List bytes,
    required String title,
  }) async {
    final userId = supabaseClient.auth.currentUser?.id;

    if (userId == null) {
      throw Exception('Please sign in again.');
    }

    final originalExtension = image.name.split('.').last.toLowerCase();

    final extension = switch (originalExtension) {
      'png' => 'png',
      'webp' => 'webp',
      'jpeg' => 'jpeg',
      'jpg' => 'jpg',
      _ => 'jpg',
    };

    final contentType = switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    final storagePath =
        '$userId/$productId/${DateTime.now().millisecondsSinceEpoch}.$extension';

    final storage = supabaseClient.storage.from('product-images');

    await storage.uploadBinary(
      storagePath,
      bytes,
      fileOptions: FileOptions(
        contentType: contentType,
        upsert: false,
      ),
    );

    try {
      await supabaseClient.from('product_images').insert({
        'product_id': productId,
        'storage_path': storagePath,
        'alt_text': title,
        'sort_order': 0,
      });
    } catch (_) {
      try {
        await storage.remove([storagePath]);
      } catch (_) {}

      rethrow;
    }

    return storagePath;
  }

  Future<List<Map<String, dynamic>>> getProductImages(
    String productId,
  ) async {
    final rows = await supabaseClient
        .from('product_images')
        .select('id, storage_path')
        .eq('product_id', productId)
        .order('sort_order');

    return List<Map<String, dynamic>>.from(rows);
  }

  Future<dynamic> getImageComparison(String imageId) {
    return apiService.request(
      '/api/v1/images/$imageId/comparison',
    );
  }

  Future<dynamic> requestEnhancement(String storagePath) {
    return apiService.request(
      '/api/v1/images/enhance',
      method: 'POST',
      body: {'original_storage_path': storagePath},
    );
  }

  Future<dynamic> selectImage({
    required String imageId,
    required String selection,
  }) {
    return apiService.request(
      '/api/v1/images/$imageId/selection',
      method: 'PATCH',
      body: {'selection': selection},
    );
  }
}
