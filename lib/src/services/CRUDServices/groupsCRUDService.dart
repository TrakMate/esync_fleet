import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/CRUDModels/groupsCRUDModel.dart';
import '../apiURL.dart';

class GroupsApiService {
  Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("accessToken") ?? "";
  }

  Future<GroupsCRUDModel> fetchGroups({
    required int page,
    required int sizePerPage,
  }) async {
    final uri = Uri.parse(BaseURLConfig.groupApiURL).replace(
      queryParameters: {
        "page": page.toString(),
        "sizePerPage": sizePerPage.toString(),
        "currentIndex": ((page - 1) * sizePerPage).toString(),
      },
    );

    final response = await http.get(
      uri,
      headers: {"Authorization": "Bearer ${await _token()}"},
    );

    if (response.statusCode == 200) {
      return GroupsCRUDModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Failed to load groups");
    }
  }

  /// ---------------- CREATE ----------------
  Future<void> createGroup(String name) async {
    final response = await http.post(
      Uri.parse(BaseURLConfig.groupApiURL),
      headers: {
        "Authorization": "Bearer ${await _token()}",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"name": name}),
    );

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }
  }

  /// ---------------- UPDATE ----------------
  Future<void> updateGroup(String id, String name) async {
    final response = await http.post(
      Uri.parse("${BaseURLConfig.groupApiURL}/$id"),
      headers: {
        "Authorization": "Bearer ${await _token()}",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"id": id, "name": name}),
    );

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }
  }

  /// ---------------- DELETE ----------------
  Future<void> deleteGroup(String id) async {
    final response = await http.delete(
      Uri.parse("${BaseURLConfig.groupApiURL}/$id"),
      headers: {"Authorization": "Bearer ${await _token()}"},
    );

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }
  }
}
