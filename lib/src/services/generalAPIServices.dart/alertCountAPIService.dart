import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/alertCountModel.dart';
import '../apiURL.dart';

class AlertCountApiService {
  static const String baseUrl = BaseURLConfig.alertCountApiUrl;

  Future<AlertCountModel> fetchAlertCounts({
    String? imei,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    // Build query parameters
    final Map<String, String> queryParams = {};

    if (imei != null && imei.isNotEmpty) {
      queryParams['imei'] = imei;
    }

    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String();
    }

    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String();
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

  // Optional: Method to fetch counts for a specific device
  Future<AlertCountModel> fetchDeviceAlertCounts(String imei) async {
    return fetchAlertCounts(imei: imei);
  }

  // Optional: Method to fetch counts within a date range
  Future<AlertCountModel> fetchAlertCountsForDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? imei,
  }) async {
    return fetchAlertCounts(imei: imei, startDate: startDate, endDate: endDate);
  }
}
