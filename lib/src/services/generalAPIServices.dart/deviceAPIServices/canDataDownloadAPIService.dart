import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/canDataDownloadModel.dart';
import '../../apiURL.dart';

class CanDataApiService {
  static const String baseUrl = BaseURLConfig.deviceCanApiUrl;

  Future<List<CanDataDownloadModel>> fetchCanDownloadData({
    required String imei,
    required String name,
    required String date,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    // Build query params
    final Map<String, String> queryParams = {
      "imei": imei,
      "name": name,
      "date": date,
    };

    final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);

    try {
      final response = await http.get(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final String csvData = response.body;

        // Convert CSV → Model list
        return parseCanCsv(csvData);
      } else {
        throw Exception("Failed to load CAN data: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching CAN data: $e");
    }
  }

  /// Optional helper method for single device
  Future<List<CanDataDownloadModel>> fetchDeviceCanData({
    required String imei,
    required String date,
  }) async {
    return fetchCanDownloadData(imei: imei, name: "", date: date);
  }

  List<CanDataDownloadModel> parseCanCsv(String response) {
    List<String> lines = response.split("\n");

    if (lines.isEmpty) return [];

    List<String> headers = lines[0].split(",");

    List<CanDataDownloadModel> list = [];

    for (int i = 1; i < lines.length; i++) {
      if (lines[i].trim().isEmpty) continue;

      List<String> values = lines[i].split(",");

      list.add(CanDataDownloadModel.fromList(headers, values));
    }

    return list;
  }
}
