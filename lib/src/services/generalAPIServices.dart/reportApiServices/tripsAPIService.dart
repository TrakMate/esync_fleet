import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/tripReportModel.dart';
import '../../apiURL.dart';
import 'downloadService.dart';

class TripReportApiService {
  final String baseUrl = BaseURLConfig.reportsApiUrl + "/trips";

  Future<TripReportModel> fetchTripReports({
    required String fromDate,
    required String toDate,
    String? imei,
    String? groupId,
    int? rangeDays,
    String? status,
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
        groupId: groupId,
        rangeDays: rangeDays,
        status: status,
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
        return TripReportModel.fromJson(jsonResponse);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('API endpoint not found. Please check URL: $url');
      } else {
        throw Exception(
          "Failed to load trip reports. Status code: ${response.statusCode}\nResponse: ${response.body}",
        );
      }
    } catch (e) {
      print('Error in fetchTripReports: $e');
      rethrow;
    }
  }

  Future<TripReportModel> fetchRecentTripReports({
    String? imei,
    String? groupId,
    String? status,
  }) async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    String fromDate = _formatDate(sevenDaysAgo);
    String toDate = _formatDate(now);

    return fetchTripReports(
      fromDate: fromDate,
      toDate: toDate,
      imei: imei,
      groupId: groupId,
      rangeDays: 7,
      status: status,
    );
  }

  String _buildUrl({
    required String fromDate,
    required String toDate,
    String? imei,
    String? groupId,
    int? rangeDays,
    String? status,
    String? format,
  }) {
    String url = baseUrl;

    if (status != null && status.isNotEmpty) {
      String statusLower = status.toLowerCase();
      if (statusLower == 'all') {
        url += "/all";
      } else {
        url += "/$statusLower";
      }
    }

    // Build query parameters dynamically
    Map<String, String> queryParams = {};

    // Only add fromDate and toDate if rangeDays is null or 0
    // This assumes that when rangeDays is provided, we don't need individual dates
    if (rangeDays == null || rangeDays <= 0) {
      // Add fromDate and toDate only when they're not empty
      if (fromDate.isNotEmpty && toDate.isNotEmpty) {
        queryParams["fromDate"] = fromDate;
        queryParams["toDate"] = toDate;
      }
    }

    if (imei != null && imei.isNotEmpty) {
      queryParams["imei"] = imei;
    }

    if (groupId != null && groupId.isNotEmpty) {
      queryParams["groupId"] = groupId;
    }

    // Only add rangeDays if it's > 0
    if (rangeDays != null && rangeDays > 0) {
      queryParams["rangeDays"] = rangeDays.toString();
    }

    final uri = Uri.parse(url).replace(queryParameters: queryParams);

    return uri.toString();
  }

  Future<String> getDownloadUrl({
    required String fromDate,
    required String toDate,
    String? imei,
    String? groupId,
    int? rangeDays,
    String? status,
  }) async {
    return _buildUrl(
      fromDate: fromDate,
      toDate: toDate,
      imei: imei,
      groupId: groupId,
      rangeDays: rangeDays,
      status: status,
    );
  }

  Future<void> downloadReport({
    required BuildContext context,
    required String fromDate,
    required String toDate,
    String? imei,
    String? groupId,
    int? rangeDays,
    String? status,
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
        rangeDays: rangeDays,
        status: status,
        format: format,
      );

      String fileExtension = format ?? 'csv';
      String timestamp = DateTime.now()
          .toString()
          .split('.')
          .first
          .replaceAll(':', '-');

      String fileName = 'trip_report_${fromDate}_to_${toDate}';

      if (imei != null && imei.isNotEmpty) {
        fileName += '_$imei';
      } else if (groupId != null && groupId.isNotEmpty) {
        fileName += '_group_$groupId';
      }

      if (status != null && status.isNotEmpty) {
        fileName += '_${status.toLowerCase()}';
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
