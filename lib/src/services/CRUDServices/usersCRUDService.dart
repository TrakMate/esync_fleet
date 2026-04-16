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

  Future<UserCRUDModel> fetchUsers({
    required int page,
    required int sizePerPage,
  }) async {
    final url =
        "${BaseURLConfig.userApiURL}"
        "?page=$page"
        "&sizePerPage=$sizePerPage"
        "&currentIndex=${(page - 1) * sizePerPage}";

    final response = await http.get(
      Uri.parse(url),
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
    final response = await http.post(
      Uri.parse(BaseURLConfig.userApiURL),
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
    payload["id"] = id; // IMPORTANT (backend consistency)

    final response = await http.post(
      Uri.parse("${BaseURLConfig.userApiURL}/$id"),
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
    final response = await http.delete(
      Uri.parse("${BaseURLConfig.userApiURL}/$id"),
      headers: {"Authorization": "Bearer ${await _token()}"},
    );

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }
  }

  /// RESET PASSWORD
  Future<void> resetPassword(String id, String password) async {
    final response = await http.post(
      Uri.parse("${BaseURLConfig.baseURL}/api/resetPassword/$id"),
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
