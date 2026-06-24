import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/canDataModel.dart';
import '../../apiURL.dart';

class Candatatableapiservice {
  static const String baseUrl = BaseURLConfig.baseURL;

  // API
  static const String canDataApiUrl = '$baseUrl/api/device/orgCanData';

  Future<CanDataModel> fetchCANData({required String imei}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    // Final URL
    final uri = Uri.parse('$canDataApiUrl/$imei');

    try {
      final response = await http.get(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        return CanDataModel.fromJson(data);
      } else {
        throw Exception("Failed to load CAN data : ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching CAN data : $e");
    }
  }
}
