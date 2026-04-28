import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/vehicleReportModel.dart';
import '../../apiURL.dart';
import 'downloadService.dart';

class VehicleReportApiService {
  final String baseUrl = BaseURLConfig.reportsApiUrl + "/vehicle";

  Future<VehicleReportModel> fetchVehicleReports({
    String? groupId,
    int? rangeDays,
    String? status,
    String? availability,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');

      if (token == null) {
        throw Exception('No access token found. Please login again.');
      }

      String url = _buildUrl(
        groupId: groupId,
        rangeDays: rangeDays,
        status: status,
        availability: availability,
      );

      final uri = Uri.parse(url);
      print('Fetching vehicle reports from: $uri');

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
        return VehicleReportModel.fromJson(jsonResponse);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('API endpoint not found. Please check URL: $url');
      } else {
        throw Exception(
          "Failed to load vehicle reports. Status code: ${response.statusCode}\nResponse: ${response.body}",
        );
      }
    } catch (e) {
      print('Error in fetchVehicleReports: $e');
      rethrow;
    }
  }

  Future<VehicleReportModel> fetchRecentVehicleReports({
    String? groupId,
    String? status,
    String? availability,
  }) async {
    return fetchVehicleReports(
      groupId: groupId,
      rangeDays: 7,
      status: status,
      availability: availability,
    );
  }

  String _buildUrl({
    String? groupId,
    int? rangeDays,
    String? status,
    String? availability,
    String? format,
  }) {
    String url = baseUrl;

    if (availability != null &&
        availability.isNotEmpty &&
        availability != 'All') {
      url += "/$availability";
    } else {
      url += "/All";
    }

    Map<String, String> queryParams = {};

    if (groupId != null && groupId.isNotEmpty) {
      queryParams["groupId"] = groupId;
    }

    if (rangeDays != null && rangeDays > 0) {
      queryParams["rangeDays"] = rangeDays.toString();
    }

    if (status != null && status.isNotEmpty && status != 'All') {
      queryParams["StatusFilter"] = status;
    }

    final uri = Uri.parse(url).replace(queryParameters: queryParams);
    return uri.toString();
  }

  Future<String> getDownloadUrl({
    String? groupId,
    int? rangeDays,
    String? status,
    String? availability,
    String? format,
  }) async {
    return _buildUrl(
      groupId: groupId,
      rangeDays: rangeDays,
      status: status,
      availability: availability,
      format: format,
    );
  }

  Future<void> downloadReport({
    required BuildContext context,
    // String? imei,
    String? groupId,
    int? rangeDays,
    String? status,
    String? availability,
    String? format,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    try {
      String url = _buildUrl(
        // imei: imei,
        groupId: groupId,
        rangeDays: rangeDays,
        status: status,
        availability: availability,
        format: format,
      );

      String fileExtension = format == 'xlsx' ? 'xlsx' : (format ?? 'xlsx');
      String timestamp = DateTime.now()
          .toString()
          .split('.')
          .first
          .replaceAll(':', '-')
          .replaceAll(' ', '_');

      String fileName = 'vehicle_report_${groupId}';

      if (groupId != null && groupId.isNotEmpty) {
        fileName += '_group_$groupId';
      }

      if (availability != null &&
          availability.isNotEmpty &&
          availability != 'All') {
        fileName += '_${availability.toLowerCase()}';
      }

      if (status != null && status.isNotEmpty && status != 'All') {
        fileName += '_${status.toLowerCase()}';
      }

      fileName += '_$timestamp.$fileExtension';

      await DownloadService.downloadFile(
        context: context,
        url: url,
        fileName: fileName,
        contentType: _getContentType(format ?? 'xlsx'),
        format: format ?? 'xlsx',
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
