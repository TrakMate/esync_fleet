import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/deviceDetailsModel.dart';
import '../apiURL.dart';

class DeviceDetailsApiService {
  static const String baseUrl = BaseURLConfig.deviceDetailApiUrl;

  Future<DeviceDetailsModel> fetchDeviceDetails({
    required String deviceId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    final uri = Uri.parse("$baseUrl/$deviceId");

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print("Device Details URL: $uri");

    if (response.statusCode == 200) {
      return DeviceDetailsModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load device details');
    }
  }
}
