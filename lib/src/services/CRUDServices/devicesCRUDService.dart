import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/CRUDModels/devicesCRUDModel.dart';
import '../apiURL.dart';

class DevicesCRUDApiService {
  Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("accessToken") ?? "";
  }

  Future<DevicesCRUDModel> fetchDevices({
    required int page,
    required int sizePerPage,
  }) async {
    final uri = Uri.parse(BaseURLConfig.devicesApiUrl).replace(
      queryParameters: {
        "page": page.toString(),
        "sizePerPage": sizePerPage.toString(),
        "currentIndex": ((page - 1) * sizePerPage).toString(),
      },
    );

    final response = await http.get(
      uri,
      headers: {
        "Authorization": "Bearer ${await _token()}",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      return DevicesCRUDModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Failed to load devices (${response.statusCode})");
    }
  }

  Future<void> createDevice(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse("${BaseURLConfig.baseURL}/api/device"),
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

  Future<void> updateDevice(String imei, Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse("${BaseURLConfig.baseURL}/api/device/$imei"),
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
}
