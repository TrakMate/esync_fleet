import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/alertCountModel.dart';
import '../apiURL.dart';

class AlertCountApiService {
  static const String baseUrl = BaseURLConfig.alertCountApiUrl;

  Future<AlertCountModel> fetchAlertCounts({String? imei, String? date}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    // Build query parameters
    final Map<String, String> queryParams = {};

    if (imei != null && imei.isNotEmpty) {
      queryParams['imei'] = imei;
    }
    if (date != null) {
      queryParams['date'] = date;
    }

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
        final Map<String, dynamic> responseData = json.decode(response.body);

        // Handle different response structures
        if (responseData.containsKey('data')) {
          return AlertCountModel.fromJson(responseData['data']);
        } else {
          return AlertCountModel.fromJson(responseData);
        }
      } else {
        throw Exception("Failed to load alert counts: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching alert counts: $e");
    }
  }

  Future<AlertCountModel> fetchAlertCountsForDate(
    String date, {
    String? imei,
  }) async {
    return fetchAlertCounts(imei: imei, date: date);
  }
}
