
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  final String baseUrl;
  final SupabaseClient supabaseClient;

  ApiService({
    required this.baseUrl,
    required this.supabaseClient,
  });

  Map<String, String> get _authHeaders {
    final token = supabaseClient.auth.currentSession?.accessToken;

    if (token == null) {
      throw Exception('Your session has expired. Please sign in again.');
    }

    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<dynamic> request(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = _authHeaders;

    final response = switch (method.toUpperCase()) {
      'POST' => await http.post(
          uri,
          headers: headers,
          body: jsonEncode(body),
        ),
      'PUT' => await http.put(
          uri,
          headers: headers,
          body: jsonEncode(body),
        ),
      'PATCH' => await http.patch(
          uri,
          headers: headers,
          body: jsonEncode(body),
        ),
      _ => await http.get(uri, headers: headers),
    };

    final data = response.body.isEmpty
        ? null
        : jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = data is Map ? data['detail'] : null;

      throw Exception(
        detail ?? 'Request failed (${response.statusCode}).',
      );
    }

    return data;
  }
}
