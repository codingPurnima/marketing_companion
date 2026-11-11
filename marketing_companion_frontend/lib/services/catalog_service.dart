
import 'api_service.dart';

class CatalogService {
  final ApiService apiService;

  CatalogService({required this.apiService});

  Future<dynamic> generateCatalog(String productText) {
    return apiService.request(
      '/api/v1/catalog/generate',
      method: 'POST',
      body: {'product_text': productText},
    );
  }

  Future<dynamic> createDraft({
    required String title,
    required String description,
    required String category,
    required List<dynamic> materials,
    required List<dynamic> tags,
    required double? price,
  }) {
    return apiService.request(
      '/api/v1/catalog/drafts',
      method: 'POST',
      body: {
        'title': title,
        'description': description,
        'category': category,
        'materials': materials,
        'tags': tags,
        'price_inr': price,
      },
    );
  }

  Future<dynamic> updateDraft({
    required String productId,
    required String title,
    required String description,
    required String category,
    required double? price,
  }) {
    return apiService.request(
      '/api/v1/catalog/$productId',
      method: 'PATCH',
      body: {
        'title': title,
        'description': description,
        'category': category,
        'materials': [],
        'tags': [],
        'price_inr': price,
      },
    );
  }

  Future<List<dynamic>> getDrafts() async {
    final result = await apiService.request('/api/v1/catalog/drafts');

    if (result is! List) {
      throw Exception('Unexpected response while loading drafts.');
    }

    return result;
  }

  Future<List<dynamic>> getArchivedProducts() async {
    final result = await apiService.request('/api/v1/catalog/archived');

    if (result is! List) {
      throw Exception('Unexpected response while loading archived products.');
    }

    return result;
  }

  Future<dynamic> updatePublication({
    required String productId,
    required bool publish,
  }) {
    return apiService.request(
      '/api/v1/catalog/$productId/${publish ? 'publish' : 'unpublish'}',
      method: 'PATCH',
    );
  }

  Future<dynamic> republishArchivedProduct(String productId) {
    return apiService.request(
      '/api/v1/catalog/$productId/publish',
      method: 'PATCH',
    );
  }
}
