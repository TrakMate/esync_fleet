import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/CRUDModels/orgsCRUDModel.dart';
import '../apiURL.dart';

class OrgsApiService {
  Future<OrgsModel> fetchorgs({
    required int currentPage,
    required int sizePerPage,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("accessToken") ?? "";

    final uri = Uri.parse(BaseURLConfig.orgApiUrl).replace(
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
      return OrgsModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Failed to load API keys");
    }
  }

  Future<void> updateOrg(String id, Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString("accessToken") ?? "";

    final response = await http.put(
      Uri.parse("${BaseURLConfig.orgApiUrl}/$id"),
      headers: {
        "Authorization": "Bearer $token}",
        "Content-Type": "application/json",
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }
  }

  Future<void> createOrg(Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("accessToken") ?? "";

    final response = await http.post(
      Uri.parse("${BaseURLConfig.baseURL}/api/super/org"),
      headers: {
        "Authorization": "Bearer $token", // ✅ fixed
        "Content-Type": "application/json",
      },
      body: jsonEncode(payload),
    );

    /// Optional debug
    print("CREATE ORG RESPONSE: ${response.body}");

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        "Failed to create org (${response.statusCode}) ${response.body}",
      );
    }
  }

  static Future<void> deleteOrg(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("accessToken") ?? "";

    final url = Uri.parse("${BaseURLConfig.orgDeleteApiUrl}/$id");

    final response = await http.delete(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Failed to delete org");
    }
  }
}
