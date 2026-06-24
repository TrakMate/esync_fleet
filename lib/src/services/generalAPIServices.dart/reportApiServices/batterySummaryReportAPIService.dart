import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/batterySummaryReportModel.dart';
import '../../apiURL.dart';
import 'downloadService.dart';

class BatterySummaryReportApiService {
  final String baseUrl = BaseURLConfig.batterySummaryReportApiUrl;

  Future<BatterySummaryReportModel> fetchBatteryReports({
    required String fromDate,
    String? toDate,
    String? imeiList,
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
        imeiList: imeiList,
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
        return BatterySummaryReportModel.fromJson(jsonResponse);
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

  Future<BatterySummaryReportModel> fetchRecentBatteryReports({
    String? imeiList,
    String? batteryStatus,
    String? vehicleType,
  }) async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    String fromDate = _formatDate(sevenDaysAgo);

    return fetchBatteryReports(
      fromDate: fromDate,
      imeiList: imeiList,
      batteryStatus: batteryStatus,
      vehicleType: vehicleType,
    );
  }

  String _buildUrl({
    required String fromDate,
    String? toDate,
    String? imeiList,
    String? batteryStatus,
    String? vehicleType,
    String? format,
    String? groupId,
  }) {
    String url =
        (imeiList != null && imeiList.isNotEmpty)
            ? "$baseUrl/$imeiList"
            : "$baseUrl/all";

    Map<String, String> queryParams = {};

    queryParams["fromDate"] = fromDate;

    if (toDate != null && toDate.isNotEmpty) {
      queryParams["toDate"] = toDate;
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

    return uri.toString();
  }

  Future<String> getDownloadUrl({
    required String fromDate,
    String? toDate,
    String? imeiList,
    String? batteryStatus,
    String? vehicleType,
    int? rangeDays,
    String? format,
  }) async {
    return _buildUrl(
      fromDate: fromDate,
      toDate: toDate,
      imeiList: imeiList,
      batteryStatus: batteryStatus,
      vehicleType: vehicleType,
      format: format,
    );
  }

  Future<void> downloadReport({
    required BuildContext context,
    required String fromDate,
    String? toDate,
    String? imeiList,
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
        imeiList: imeiList,
        groupId: groupId,
        batteryStatus: batteryStatus,
        vehicleType: vehicleType,
        format: format,
      );

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

      bool hasNoData = false;

      if (jsonData['totalCount'] != null && jsonData['totalCount'] == 0) {
        hasNoData = true;
      } else if (jsonData['entities'] is List &&
          (jsonData['entities'] as List).isEmpty) {
        hasNoData = true;
      } else if (jsonData['data'] is List &&
          (jsonData['data'] as List).isEmpty) {
        hasNoData = true;
      } else if (jsonData['items'] is List &&
          (jsonData['items'] as List).isEmpty) {
        hasNoData = true;
      } else if (jsonData['summary'] != null) {
        if (jsonData['summary'] is List &&
            (jsonData['summary'] as List).isEmpty) {
          hasNoData = true;
        } else if (jsonData['summary'] is Map &&
            (jsonData['summary'] as Map).isEmpty) {
          hasNoData = true;
        }
      } else if (jsonData['batterySummary'] is List &&
          (jsonData['batterySummary'] as List).isEmpty) {
        hasNoData = true;
      } else if (jsonData['batterySummaries'] is List &&
          (jsonData['batterySummaries'] as List).isEmpty) {
        hasNoData = true;
      } else if (jsonData.isEmpty ||
          (jsonData.keys.length == 1 &&
              (jsonData.containsKey('message') ||
                  jsonData.containsKey('error')))) {
        hasNoData = true;
      }

      if (hasNoData) {
        onError("No data found for the selected filters");
        return;
      }

      String fileExtension = format ?? 'csv';
      String timestamp = DateTime.now()
          .toString()
          .split('.')
          .first
          .replaceAll(':', '-')
          .replaceAll(' ', '_');

      String fileName = 'battery_summary_report_';

      if (toDate != null && toDate.isNotEmpty) {
        fileName += '_to_${toDate.replaceAll('-', '_')}';
      }

      if (imeiList != null && imeiList.isNotEmpty) {
        fileName += '_$imeiList';
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
