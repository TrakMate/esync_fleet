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
  final String baseUrl = BaseURLConfig.alertReportApiUrl;

  Future<alertReportModel> fetchAlertReports({
    required String fromDate,
    required String toDate,
    String? imeiList,
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
        imeiList: imeiList,
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
    String? imeiList,
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
      imeiList: imeiList,
      groupId: groupId,
      rangeDays: 7,
      status: status,
    );
  }

  String _buildUrl({
    required String fromDate,
    required String toDate,
    String? imeiList,
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

    if (imeiList != null && imeiList.isNotEmpty) {
      queryParams["imeiList"] = imeiList;
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
    String? imeiList,
    String? groupId,
    int? rangeDays,
    String? status,
  }) async {
    return _buildUrl(
      fromDate: fromDate,
      toDate: toDate,
      imeiList: imeiList,
      groupId: groupId,
      rangeDays: rangeDays,
      status: status,
    );
  }

  Future<void> downloadReport({
    required BuildContext context,
    required String fromDate,
    required String toDate,
    String? imeiList,
    String? groupId,
    int? rangeDays,
    String? status,
    String? format,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    try {
      final reportData = await fetchAlertReports(
        fromDate: fromDate,
        toDate: toDate,
        imeiList: imeiList,
        groupId: groupId,
        rangeDays: rangeDays,
        status: status,
      );

      if (reportData.totalCount == 0 || reportData.entities.isEmpty) {
        onError("No data found for the selected filters.");
        return;
      }

      String fileExtension = format ?? 'csv';
      String timestamp = DateTime.now()
          .toString()
          .split('.')
          .first
          .replaceAll(':', '-')
          .replaceAll(' ', '_');

      String fileName = 'alert_report_${fromDate}_to_${toDate}';

      if (imeiList != null && imeiList.isNotEmpty) {
        fileName += '_$imeiList';
      } else if (groupId != null && groupId.isNotEmpty) {
        fileName += '_group_$groupId';
      }

      if (status != null && status.isNotEmpty && status != 'All') {
        fileName += '_${status.toLowerCase()}';
      }

      fileName += '_$timestamp.$fileExtension';

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

      if (!isBinary && (contentToDownload as String).isEmpty) {
        onError("No alert data found for the selected filters");
        return;
      }

      Uint8List bytes;
      if (isBinary) {
        if (contentToDownload is List<int> && contentToDownload.isEmpty) {
          onError("Failed to generate Excel file: No data available");
          return;
        }
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
      if (reportData.entities.isEmpty) {
        var excel = Excel.createExcel();
        final defaultSheet = excel.getDefaultSheet();
        if (defaultSheet != null) {
          excel.rename(defaultSheet, 'Alerts Report');
        }
        Sheet sheetObject = excel['Alerts Report'];

        // Add message for empty data
        sheetObject.updateCell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
          TextCellValue('No alert data found for the selected filters'),
        );

        final fileBytes = excel.encode(); // Use encode() instead of save()
        if (fileBytes != null && fileBytes.isNotEmpty) {
          return fileBytes;
        }
        return [];
      }

      var excel = Excel.createExcel();

      final defaultSheet = excel.getDefaultSheet();
      if (defaultSheet != null) {
        excel.rename(defaultSheet, 'Alerts Report');
      }

      final sheetObject = excel['Alerts Report'];

      // Define headers
      final headers = [
        'IMEI',
        'Vehicle Number',
        'Alert Type',
        'Alert Category',
        'Data',
        'Time',
      ];

      // Add headers (row 0)
      for (int i = 0; i < headers.length; i++) {
        sheetObject.updateCell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
          TextCellValue(headers[i]),
        );
      }

      // Add data rows (starting from row 1)
      for (int row = 0; row < reportData.entities.length; row++) {
        final entity = reportData.entities[row];

        sheetObject.updateCell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row + 1),
          TextCellValue(entity.imei ?? ''),
        );

        sheetObject.updateCell(
          CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row + 1),
          TextCellValue(entity.vehicleNumber?.toString() ?? ''),
        );

        sheetObject.updateCell(
          CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row + 1),
          TextCellValue(entity.alertType ?? ''),
        );

        sheetObject.updateCell(
          CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row + 1),
          TextCellValue(entity.alertCategory ?? ''),
        );

        sheetObject.updateCell(
          CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row + 1),
          TextCellValue(entity.data ?? ''),
        );

        sheetObject.updateCell(
          CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row + 1),
          TextCellValue(entity.time ?? ''),
        );
      }

      final fileBytes = excel.encode();

      if (fileBytes == null || fileBytes.isEmpty) {
        print("Excel file generation failed - bytes are null or empty");
        return [];
      }

      print(
        "Excel file generated successfully, size: ${fileBytes.length} bytes",
      );
      return fileBytes;
    } catch (e, stackTrace) {
      print('Error creating Excel file: $e');
      print('StackTrace: $stackTrace');

      try {
        var fallbackExcel = Excel.createExcel();
        final sheet = fallbackExcel['Error'];
        sheet.updateCell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
          TextCellValue('Error generating report: ${e.toString()}'),
        );
        final fallbackBytes = fallbackExcel.encode();
        return fallbackBytes ?? [];
      } catch (fallbackError) {
        print('Even fallback Excel generation failed: $fallbackError');
        return [];
      }
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
