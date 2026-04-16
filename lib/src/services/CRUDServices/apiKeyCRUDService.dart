import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/CRUDModels/apiKeyCRUDModel.dart';
import '../apiURL.dart';

class ApiKeyApiService {
  Future<APIKeyCRUDModel> fetchApiKeys({
    required int currentPage,
    required int sizePerPage,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("accessToken") ?? "";

    final uri = Uri.parse(BaseURLConfig.apiKeyApiUrl).replace(
      queryParameters: {
        "page": currentPage.toString(),
        "sizePerPage": sizePerPage.toString(),
        "currentIndex": ((currentPage - 1) * sizePerPage).toString(),
      },
    );

    final response = await http.get(
      uri,
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return APIKeyCRUDModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Failed to load API keys");
    }
  }

  Future<void> createApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("accessToken") ?? "";

    final uri = Uri.parse(BaseURLConfig.apiKeyApiUrl);

    final response = await http.post(
      uri,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to create API key");
    }
  }

  Future<void> deleteApiKey(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("accessToken") ?? "";

    final uri = Uri.parse("${BaseURLConfig.apiKeyApiUrl}/$id");

    final response = await http.delete(
      uri,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to delete API key");
    }
  }
}
