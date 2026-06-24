import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/batteryReportModel.dart';
import '../../apiURL.dart';
import 'downloadService.dart';

class BatteryReportApiService {
  final String baseUrl = BaseURLConfig.batteryReportApiUrl;

  Future<BatteryReportModel> fetchBatteryReports({
    required String fromDate,
    String? toDate,
    // String? imei,
    String? batteryStatus,
    String? vehicleType,
    int? rangeDays,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');

      if (token == null) {
        throw Exception('No access token found. Please login again.');
      }

      String url = _buildUrl(
        fromDate: fromDate,
        toDate: toDate,
        // imei: imei,
        batteryStatus: batteryStatus,
        vehicleType: vehicleType,
      );

      final uri = Uri.parse(url);

      final response = await http
          .get(
            uri,
            headers: {
              "Authorization": "Bearer $token",
              "Content-Type": "application/json",
            },
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception(
                'Connection timeout. Please check your internet connection.',
              );
            },
          );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return BatteryReportModel.fromJson(jsonResponse);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('API endpoint not found. Please check URL: $url');
      } else {
        throw Exception(
          "Failed to load battery reports. Status code: ${response.statusCode}\nResponse: ${response.body}",
        );
      }
    } catch (e) {
      print('Error in fetchBatteryReports: $e');
      rethrow;
    }
  }

  Future<BatteryReportModel> fetchRecentBatteryReports({
    String? imei,
    String? batteryStatus,
    String? vehicleType,
  }) async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    String fromDate = _formatDate(sevenDaysAgo);

    return fetchBatteryReports(
      fromDate: fromDate,
      // imei: imei,
      batteryStatus: batteryStatus,
      vehicleType: vehicleType,
    );
  }

  String _buildUrl({
    required String fromDate,
    String? toDate,
    String? imei,
    String? batteryStatus,
    String? vehicleType,
    String? format,
    String? groupId,
  }) {
    String url = baseUrl;

    Map<String, String> queryParams = {};

    queryParams["fromDate"] = fromDate;

    if (toDate != null && toDate.isNotEmpty) {
      queryParams["toDate"] = toDate;
    }

    if (imei != null && imei.isNotEmpty) {
      queryParams["imei"] = imei;
    }

    if (batteryStatus != null &&
        batteryStatus.isNotEmpty &&
        batteryStatus.toLowerCase() != 'all') {
      queryParams["batteryStatus"] = batteryStatus.toLowerCase();
    }

    if (groupId != null && groupId.isNotEmpty) {
      queryParams["groupId"] = groupId;
    }

    if (vehicleType != null &&
        vehicleType.isNotEmpty &&
        vehicleType.toLowerCase() != 'all') {
      queryParams["vehicleType"] = vehicleType.toLowerCase();
    }

    if (format != null && format.isNotEmpty && format.toLowerCase() != 'all') {
      queryParams["format"] = format.toLowerCase();
    }

    final uri = Uri.parse(url).replace(queryParameters: queryParams);

    print("FINAL URL 👉 $uri"); // 🔥 DEBUG

    return uri.toString();
  }

  Future<String> getDownloadUrl({
    required String fromDate,
    String? toDate,
    String? imei,
    String? batteryStatus,
    String? vehicleType,
    int? rangeDays,
    String? format,
  }) async {
    return _buildUrl(
      fromDate: fromDate,
      toDate: toDate,
      imei: imei,
      batteryStatus: batteryStatus,
      vehicleType: vehicleType,
      format: format,
    );
  }

  Future<void> downloadReport({
    required String fromDate,
    String? toDate,
    required BuildContext context,
    String? imei,
    String? groupId,
    String? batteryStatus,
    String? vehicleType,
    String? format,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    try {
      String url = _buildUrl(
        fromDate: fromDate,
        toDate: toDate,
        imei: imei,
        groupId: groupId,
        batteryStatus: batteryStatus,
        vehicleType: vehicleType,
        format: format,
      );

      // Step 1: Fetch the data first to check if there's any content
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');

      if (token == null) {
        onError("Authentication required - Please login again");
        return;
      }

      final uri = Uri.parse(url);
      final response = await http.get(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode != 200) {
        onError("Failed to fetch data: HTTP ${response.statusCode}");
        return;
      }

      final jsonData = json.decode(response.body);

      // Step 2: Check if there's no data
      bool hasNoData = false;

      // Check totalCount if it exists
      if (jsonData['totalCount'] != null && jsonData['totalCount'] == 0) {
        hasNoData = true;
      }
      // Check if entities is empty
      else if (jsonData['entities'] is List &&
          (jsonData['entities'] as List).isEmpty) {
        hasNoData = true;
      }
      // Check if data is empty
      else if (jsonData['data'] is List && (jsonData['data'] as List).isEmpty) {
        hasNoData = true;
      }
      // Check if items is empty
      else if (jsonData['items'] is List &&
          (jsonData['items'] as List).isEmpty) {
        hasNoData = true;
      }
      // Check if battery data array is empty (battery report specific)
      else if (jsonData['batteryData'] is List &&
          (jsonData['batteryData'] as List).isEmpty) {
        hasNoData = true;
      } else if (jsonData['batteryReports'] is List &&
          (jsonData['batteryReports'] as List).isEmpty) {
        hasNoData = true;
      }
      // Check if the response itself is empty or has error message
      else if (jsonData.isEmpty ||
          (jsonData.keys.length == 1 &&
              (jsonData.containsKey('message') ||
                  jsonData.containsKey('error')))) {
        hasNoData = true;
      }

      // Step 3: Show error and return if no data found
      if (hasNoData) {
        onError("No battery data found for the selected filters");
        return;
      }

      // Step 4: Proceed with download only if there's data
      String fileExtension = format ?? 'csv';
      String timestamp = DateTime.now()
          .toString()
          .split('.')
          .first
          .replaceAll(':', '-')
          .replaceAll(' ', '_');

      String fileName = 'battery_report_';

      if (imei != null && imei.isNotEmpty) {
        fileName += '_$imei';
      }

      if (groupId != null && groupId.isNotEmpty) {
        fileName += '_group_$groupId';
      }

      if (batteryStatus != null &&
          batteryStatus.isNotEmpty &&
          batteryStatus.toLowerCase() != 'all') {
        fileName += '_${batteryStatus.toLowerCase()}';
      }

      if (vehicleType != null &&
          vehicleType.isNotEmpty &&
          vehicleType.toLowerCase() != 'all') {
        fileName += '_${vehicleType.toLowerCase()}';
      }

      fileName += '_$timestamp.$fileExtension';

      await DownloadService.downloadFile(
        context: context,
        url: url,
        fileName: fileName,
        contentType: _getContentType(format ?? 'csv'),
        format: format ?? 'csv',
        onSuccess: onSuccess,
        onError: onError,
      );
    } catch (e) {
      onError("Failed to initiate download: ${e.toString()}");
    }
  }

  String _getContentType(String format) {
    switch (format.toLowerCase()) {
      case 'csv':
        return 'text/csv';
      case 'json':
        return 'application/json';
      case 'xml':
        return 'application/xml';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'logs':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${_twoDigits(date.month)}-${_twoDigits(date.day)}";
  }

  String _twoDigits(int n) {
    if (n >= 10) return "$n";
    return "0$n";
  }
}
