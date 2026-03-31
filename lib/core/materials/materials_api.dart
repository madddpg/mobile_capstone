import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models/material_category.dart';

/// Optional API integration for dynamic material loading.
///
/// Expected JSON shape (example):
/// {
///   "categories": [
///     {"title": "Tile Type", "items": [{"name": "...", "category": "Tile Type", "description": "..."}]}
///   ]
/// }
class MaterialsApi {
  final http.Client _client;

  MaterialsApi({http.Client? client}) : _client = client ?? http.Client();

  Future<List<MaterialCategory>> fetchMaterialsFromAPI(Uri url) async {
    final response = await _client.get(url);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw http.ClientException(
        'Failed to load materials (HTTP ${response.statusCode}).',
        url,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid materials JSON (expected object).');
    }

    final rawCategories = decoded['categories'];
    if (rawCategories is! List) {
      return const <MaterialCategory>[];
    }

    return rawCategories
        .whereType<Map<String, dynamic>>()
        .map(MaterialCategory.fromJson)
        .toList(growable: false);
  }
}
