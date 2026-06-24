import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/CRUDModels/usersCRUDModel.dart';
import '../apiURL.dart';

class UserApiService {
  Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("accessToken") ?? "";
  }

  Future<String?> getUserRole() async {
    final token = await _token();

    if (token == null || token.isEmpty) {
      return null;
    }

    final parts = token.split('.');

    if (parts.length != 3) {
      return null;
    }

    final payload = parts[1];

    String normalized = base64Url.normalize(payload);

    final decoded = utf8.decode(base64Url.decode(normalized));

    final Map<String, dynamic> data = jsonDecode(decoded);

    return data["auth"];
  }

  Future<UserCRUDModel> fetchUsers({
    required int page,
    required int sizePerPage,
    String? role,
    int? status,
    String? searchText,
  }) async {
    String? mappedRole = role;

    if (role == "SUPER ADMIN") {
      mappedRole = "SUPER_ADMIN";
    }

    final queryParams = {
      "page": page.toString(),
      "sizePerPage": sizePerPage.toString(),
      "currentIndex": ((page - 1) * sizePerPage).toString(),
    };

    if (mappedRole != null && mappedRole.isNotEmpty && mappedRole != "ALL") {
      queryParams["role"] = mappedRole;
    }

    if (status != null && status != -1) {
      queryParams["status"] = status.toString();
    }

    if (searchText != null && searchText.trim().isNotEmpty) {
      queryParams["searchText"] = searchText.trim();
    }

    final uri = Uri.parse(
      BaseURLConfig.userApiURL,
    ).replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        "Authorization": "Bearer ${await _token()}",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      return UserCRUDModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Failed to load users (${response.statusCode})");
    }
  }

  /// CREATE USER
  Future<void> createUser(Map<String, dynamic> payload) async {
    final loggedInRole = await getUserRole();

    final apiUrl =
        loggedInRole == "SUPER_ADMIN"
            ? BaseURLConfig.UpdateUserApiURL
            : BaseURLConfig.userApiURL;
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        "Authorization": "Bearer ${await _token()}",
        "Content-Type": "application/json",
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }
  }

  /// UPDATE USER
  Future<void> updateUser(String id, Map<String, dynamic> payload) async {
    payload["id"] = id;

    final loggedInRole = await getUserRole();

    final apiUrl =
        loggedInRole == "SUPER_ADMIN"
            ? BaseURLConfig.UpdateUserApiURL
            : BaseURLConfig.userApiURL;

    final response = await http.post(
      Uri.parse("$apiUrl/$id"),
      headers: {
        "Authorization": "Bearer ${await _token()}",
        "Content-Type": "application/json",
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }
  }

  /// DELETE USER
  Future<void> deleteUser(String id) async {
    final loggedInRole = await getUserRole();

    final apiUrl =
        loggedInRole == "SUPER_ADMIN"
            ? BaseURLConfig.UpdateUserApiURL
            : BaseURLConfig.userApiURL;
    final response = await http.delete(
      Uri.parse("$apiUrl/$id"),
      headers: {"Authorization": "Bearer ${await _token()}"},
    );

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }
  }

  /// RESET PASSWORD
  Future<void> resetPassword(String id, String password) async {
    final loggedInRole = await getUserRole();

    final apiUrl =
        loggedInRole == "SUPER_ADMIN"
            ? "${BaseURLConfig.baseURL}/api/super/resetPassword"
            : "${BaseURLConfig.baseURL}/api/resetPassword";

    final response = await http.post(
      Uri.parse("$apiUrl/$id"),
      headers: {
        "Authorization": "Bearer ${await _token()}",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"password": password}),
    );

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }
  }
}
