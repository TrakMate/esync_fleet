import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:excel/excel.dart';

import '../../../models/alertReportModel.dart';
import '../../apiURL.dart';
import 'downloadService.dart';

class AlertReportApiService {
  final String baseUrl = BaseURLConfig.reportsApiUrl + "/alerts";

  Future<alertReportModel> fetchAlertReports({
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
      print('Fetching alerts from: $uri');

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
        return alertReportModel.fromJson(jsonResponse);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (response.statusCode == 403) {
        throw Exception(
          'Access forbidden. You don\'t have permission to access this resource.',
        );
      } else if (response.statusCode == 404) {
        throw Exception('API endpoint not found. Please check URL: $url');
      } else {
        throw Exception(
          "Failed to load alert reports. Status code: ${response.statusCode}\nResponse: ${response.body}",
        );
      }
    } catch (e) {
      print('Error in fetchAlertReports: $e');
      rethrow;
    }
  }

  Future<alertReportModel> fetchRecentAlertReports({
    String? imei,
    String? groupId,
    String? status,
  }) async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    String fromDate = _formatDate(sevenDaysAgo);
    String toDate = _formatDate(now);

    return fetchAlertReports(
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

    if (status != null && status.isNotEmpty && status != 'All') {
      String statusParam = status.toUpperCase();
      if (statusParam == 'NON-CRITICAL') {
        statusParam = 'NON_CRITICAL';
      }
      url += "/$statusParam";
    } else {
      url += "/alerts";
    }

    final Map<String, String> queryParams = {
      "fromDate": fromDate,
      "toDate": toDate,
    };

    if (imei != null && imei.isNotEmpty) {
      queryParams["imei"] = imei;
    }

    if (groupId != null && groupId.isNotEmpty) {
      queryParams["groupId"] = groupId;
    }

    if (rangeDays != null) {
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
      // First fetch the data
      final reportData = await fetchAlertReports(
        fromDate: fromDate,
        toDate: toDate,
        imei: imei,
        groupId: groupId,
        rangeDays: rangeDays,
        status: status,
      );

      String fileExtension = format ?? 'csv';
      String timestamp = DateTime.now()
          .toString()
          .split('.')
          .first
          .replaceAll(':', '-');

      String fileName = 'alert_report_${fromDate}_to_${toDate}';

      if (imei != null && imei.isNotEmpty) {
        fileName += '_$imei';
      } else if (groupId != null && groupId.isNotEmpty) {
        fileName += '_group_$groupId';
      }

      if (status != null && status.isNotEmpty && status != 'All') {
        fileName += '_${status.toLowerCase()}';
      }

      fileName += '_$timestamp.$fileExtension';

      // Convert the data to the requested format
      late dynamic contentToDownload;
      bool isBinary = false;

      switch (fileExtension.toLowerCase()) {
        case 'csv':
          contentToDownload = _convertAlertsToCsv(reportData);
          break;
        case 'json':
          contentToDownload = _convertAlertsToJson(reportData);
          break;
        case 'xml':
          contentToDownload = _convertAlertsToXml(reportData);
          break;
        case 'xlsx':
          contentToDownload = _convertAlertsToXlsx(reportData);
          isBinary = true;
          break;
        case 'logs':
          contentToDownload = _convertAlertsToLogs(reportData);
          break;
        default:
          contentToDownload = json.encode(reportData.toJson());
      }

      Uint8List bytes;
      if (isBinary) {
        bytes = Uint8List.fromList(contentToDownload);
      } else {
        bytes = Uint8List.fromList(utf8.encode(contentToDownload as String));
      }

      await DownloadService.downloadBytes(
        context: context,
        fileName: fileName,
        bytes: bytes,
        format: fileExtension,
        contentType: _getContentType(fileExtension),
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

  String _convertAlertsToCsv(alertReportModel reportData) {
    final buffer = StringBuffer();

    if (reportData.entities.isEmpty) return "";

    final headers = [
      'IMEI',
      'Vehicle Number',
      'Alert Type',
      'Alert Category',
      'Data',
      'Time',
    ];

    buffer.writeln(headers.join(','));

    for (var entity in reportData.entities) {
      final row = [
        _escapeCsvValue(entity.imei),
        _escapeCsvValue(entity.vehicleNumber?.toString() ?? ''),
        _escapeCsvValue(entity.alertType),
        _escapeCsvValue(entity.alertCategory),
        _escapeCsvValue(entity.data),
        _escapeCsvValue(entity.time),
      ].join(',');

      buffer.writeln(row);
    }

    return buffer.toString();
  }

  String _escapeCsvValue(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  String _convertAlertsToJson(alertReportModel reportData) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(reportData.toJson());
  }

  String _convertAlertsToXml(alertReportModel reportData) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0"?>');
    buffer.writeln('<alertReport>');
    buffer.writeln('  <totalCount>${reportData.totalCount}</totalCount>');

    for (var entity in reportData.entities) {
      buffer.writeln('  <alert>');
      _addXmlElement(buffer, 'imei', entity.imei, 4);
      _addXmlElement(
        buffer,
        'vehicleNumber',
        entity.vehicleNumber?.toString(),
        4,
      );
      _addXmlElement(buffer, 'alertType', entity.alertType, 4);
      _addXmlElement(buffer, 'alertCategory', entity.alertCategory, 4);
      _addXmlElement(buffer, 'data', entity.data, 4);
      _addXmlElement(buffer, 'time', entity.time, 4);
      buffer.writeln('  </alert>');
    }

    buffer.writeln('</alertReport>');
    return buffer.toString();
  }

  void _addXmlElement(
    StringBuffer buffer,
    String tag,
    String? value,
    int indent,
  ) {
    if (value != null && value.isNotEmpty) {
      buffer.writeln('${' ' * indent}<$tag>${_escapeXml(value)}</$tag>');
    }
  }

  String _escapeXml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  List<int> _convertAlertsToXlsx(alertReportModel reportData) {
    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Alerts Report'];

      if (reportData.entities.isNotEmpty) {
        final headers = [
          'IMEI',
          'Vehicle Number',
          'Alert Type',
          'Alert Category',
          'Data',
          'Time',
        ];

        // Add headers
        for (int i = 0; i < headers.length; i++) {
          sheetObject.updateCell(
            CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
            TextCellValue(headers[i]),
          );
        }

        // Add data rows
        for (int row = 0; row < reportData.entities.length; row++) {
          final entity = reportData.entities[row];
          final rowData = [
            entity.imei,
            entity.vehicleNumber?.toString() ?? '',
            entity.alertType,
            entity.alertCategory,
            entity.data,
            entity.time,
          ];

          for (int col = 0; col < rowData.length; col++) {
            sheetObject.updateCell(
              CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 1),
              TextCellValue(rowData[col]),
            );
          }
        }
      }

      return excel.save() ?? [];
    } catch (e) {
      print('Error creating Excel file: $e');
      return [];
    }
  }

  String _convertAlertsToLogs(alertReportModel reportData) {
    final buffer = StringBuffer();
    buffer.writeln('ALERTS REPORT');
    buffer.writeln('=' * 60);
    buffer.writeln('Total Alerts: ${reportData.totalCount}');
    buffer.writeln('=' * 60);
    buffer.writeln('');

    for (int i = 0; i < reportData.entities.length; i++) {
      final entity = reportData.entities[i];
      buffer.writeln('Alert #${i + 1}');
      buffer.writeln('-' * 40);
      buffer.writeln('IMEI           : ${entity.imei}');
      buffer.writeln('Vehicle Number : ${entity.vehicleNumber ?? "N/A"}');
      buffer.writeln('Alert Type     : ${entity.alertType}');
      buffer.writeln('Alert Category : ${entity.alertCategory}');
      buffer.writeln('Data           : ${entity.data}');
      buffer.writeln('Time           : ${entity.time}');
      buffer.writeln('');
    }

    return buffer.toString();
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${_twoDigits(date.month)}-${_twoDigits(date.day)}";
  }

  String _twoDigits(int n) {
    if (n >= 10) return "$n";
    return "0$n";
  }
}
