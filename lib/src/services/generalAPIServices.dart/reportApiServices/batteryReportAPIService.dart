import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/batteryReportModel.dart';
import '../../apiURL.dart';
import 'downloadService.dart';

class BatteryReportApiService {
  final String baseUrl = BaseURLConfig.reportsApiUrl + "/battery";

  Future<BatteryReportModel> fetchBatteryReports({
    required String fromDate,
    String? toDate,
    String? imei,
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
        imei: imei,
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
      imei: imei,
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
    String url = baseUrl + "/all";

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
    required BuildContext context,
    required String fromDate,
    String? toDate,
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

      String fileExtension = format ?? 'csv';
      String timestamp = DateTime.now()
          .toString()
          .split('.')
          .first
          .replaceAll(':', '-')
          .replaceAll(' ', '_');

      String fileName = 'battery_report_${fromDate.replaceAll('-', '_')}';

      if (toDate != null && toDate.isNotEmpty) {
        fileName += '_to_${toDate.replaceAll('-', '_')}';
      }

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
