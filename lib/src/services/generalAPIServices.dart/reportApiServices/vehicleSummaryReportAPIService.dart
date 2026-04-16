import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/vehicleSummaryModel.dart';
import '../../apiURL.dart';
import 'downloadService.dart';

class VehicleSummaryApiService {
  final String baseUrl = BaseURLConfig.reportsApiUrl + "/vehiclesummary";

  Future<VehicleSummaryModel> fetchVehicleSummary({
    required String toDate,
    String? imei,
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
        toDate: toDate,
        imei: imei,
        groupId: groupId,
        rangeDays: rangeDays,
        status: status,
        availability: availability,
      );

      final uri = Uri.parse(url);
      print('Fetching vehicle summary from: $uri');

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
        return VehicleSummaryModel.fromJson(jsonResponse);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('API endpoint not found. Please check URL: $url');
      } else {
        throw Exception(
          "Failed to load vehicle summary. Status code: ${response.statusCode}\nResponse: ${response.body}",
        );
      }
    } catch (e) {
      print('Error in fetchVehicleSummary: $e');
      rethrow;
    }
  }

  Future<VehicleSummaryModel> fetchRecentVehicleSummary({
    String? imei,
    String? groupId,
    String? status,
    String? availability,
  }) async {
    final now = DateTime.now();

    String toDate = _formatDate(now);

    return fetchVehicleSummary(
      toDate: toDate,
      imei: imei,
      groupId: groupId,
      rangeDays: 7,
      status: status,
      availability: availability,
    );
  }

  String _buildUrl({
    required String toDate,
    String? imei,
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

    // Add query parameters
    Map<String, String> queryParams = {};

    // Only add fromDate and toDate if rangeDays is null or 0
    if (rangeDays == null || rangeDays <= 0) {
      if (toDate.isNotEmpty) {
        queryParams["toDate"] = toDate;
      }
    }

    if (imei != null && imei.isNotEmpty) {
      queryParams["imei"] = imei;
    }

    if (groupId != null && groupId.isNotEmpty) {
      queryParams["groupId"] = groupId;
    }

    if (rangeDays != null && rangeDays > 0) {
      queryParams["rangeDays"] = rangeDays.toString();
    }

    if (status != null && status.isNotEmpty && status != 'All') {
      queryParams["StatusFilter"] = status;
    }

    // Add format for download URLs
    if (format != null && format.isNotEmpty) {
      queryParams["format"] = format.toLowerCase();
    }

    final uri = Uri.parse(url).replace(queryParameters: queryParams);
    return uri.toString();
  }

  Future<String> getDownloadUrl({
    required String toDate,
    String? imei,
    String? groupId,
    int? rangeDays,
    String? status,
    String? availability,
    String? format,
  }) async {
    return _buildUrl(
      toDate: toDate,
      imei: imei,
      groupId: groupId,
      rangeDays: rangeDays,
      status: status,
      availability: availability,
      format: format,
    );
  }

  Future<void> downloadReport({
    required BuildContext context,
    required String toDate,
    String? imei,
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
        toDate: toDate,
        imei: imei,
        groupId: groupId,
        rangeDays: rangeDays,
        status: status,
        availability: availability,
        format: format,
      );

      String fileExtension = format?.toLowerCase() ?? 'csv';
      String timestamp = DateTime.now()
          .toString()
          .split('.')
          .first
          .replaceAll(':', '-')
          .replaceAll(' ', '_');

      String fileName = 'vehicle_summary_${toDate}';

      if (imei != null && imei.isNotEmpty) {
        fileName += '_$imei';
      } else if (groupId != null && groupId.isNotEmpty) {
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
