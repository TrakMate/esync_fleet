import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';

import '../../../ui/widgets/reports/custom_Toast.dart';

class DownloadProgress {
  final String id;
  final String fileName;
  final DownloadStatus status;
  final int progress;
  final String? error;
  final String url;
  final DateTime startTime;
  final DateTime? endTime;
  final String format;

  DownloadProgress({
    required this.id,
    required this.fileName,
    required this.status,
    required this.progress,
    required this.url,
    this.error,
    required this.startTime,
    this.endTime,
    required this.format,
  });

  DownloadProgress copyWith({
    String? id,
    String? fileName,
    DownloadStatus? status,
    int? progress,
    String? error,
    String? url,
    DateTime? startTime,
    DateTime? endTime,
    String? format,
  }) {
    return DownloadProgress(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      url: url ?? this.url,
      error: error ?? this.error,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      format: format ?? this.format,
    );
  }
}

enum DownloadStatus { starting, downloading, completed, failed, removed }

class DownloadService {
  static final Map<String, DownloadProgress> _activeDownloads = {};

  static final StreamController<DownloadProgress> _progressController =
      StreamController<DownloadProgress>.broadcast();

  static Stream<DownloadProgress> get progressStream =>
      _progressController.stream;

  // Original method for downloading from URL
  // static Future<void> downloadFile({
  //   required BuildContext context,

  //   required String url,
  //   required String fileName,
  //   required String format,
  //   required String contentType,
  //   required Function(String) onSuccess,
  //   required Function(String) onError,
  // }) async {
  //   String downloadId = DateTime.now().millisecondsSinceEpoch.toString();

  //   DownloadProgress progress = DownloadProgress(
  //     id: downloadId,
  //     fileName: fileName,
  //     status: DownloadStatus.starting,
  //     progress: 0,
  //     url: url,
  //     startTime: DateTime.now(),
  //     format: format,
  //   );

  //   try {
  //     _activeDownloads[downloadId] = progress;
  //     _progressController.add(progress);

  //     CustomToast.show(
  //       context: context,
  //       message: "Generating Report...",
  //       type: ToastType.loading,
  //     );

  //     final prefs = await SharedPreferences.getInstance();
  //     final token = prefs.getString('accessToken');

  //     if (token == null) {
  //       throw Exception("Authentication required - Please login again");
  //     }

  //     final uri = Uri.parse(url);

  //     final response = await http.get(
  //       uri,
  //       headers: {
  //         "Authorization": "Bearer $token",
  //         "Accept": "application/json",
  //       },
  //     );

  //     if (response.statusCode != 200) {
  //       throw Exception("Download failed: HTTP ${response.statusCode}");
  //     }

  //     final jsonData = json.decode(response.body);

  //     late dynamic contentToDownload;
  //     bool isBinary = false;

  //     switch (format.toLowerCase()) {
  //       case 'csv':
  //         contentToDownload = _convertJsonToCsv(jsonData);
  //         break;
  //       case 'json':
  //         contentToDownload = _convertJsonToJson(jsonData);
  //         break;
  //       case 'xml':
  //         contentToDownload = _convertJsonToXml(jsonData);
  //         break;
  //       case 'xlsx':
  //         contentToDownload = _convertJsonToXlsx(jsonData);
  //         isBinary = true;
  //         break;
  //       case 'logs':
  //         contentToDownload = _convertJsonToLogs(jsonData);
  //         break;
  //       default:
  //         contentToDownload = json.encode(jsonData);
  //     }

  //     Uint8List bytes;

  //     if (isBinary) {
  //       bytes = Uint8List.fromList(contentToDownload);
  //     } else {
  //       bytes = Uint8List.fromList(utf8.encode(contentToDownload));
  //     }

  //     await FileSaver.instance.saveFile(
  //       name: fileName.split('.').first,
  //       bytes: bytes,
  //       ext: format,
  //       mimeType: MimeType.other,
  //     );

  //     progress = progress.copyWith(
  //       status: DownloadStatus.completed,
  //       progress: 100,
  //       endTime: DateTime.now(),
  //     );

  //     _activeDownloads[downloadId] = progress;
  //     _progressController.add(progress);

  //     CustomToast.show(
  //       context: context,
  //       message: "Download complete",
  //       type: ToastType.loading,
  //     );

  //     onSuccess("File downloaded: $fileName");
  //   } catch (e) {
  //     progress = progress.copyWith(
  //       status: DownloadStatus.failed,
  //       error: e.toString(),
  //       endTime: DateTime.now(),
  //     );

  //     _activeDownloads[downloadId] = progress;
  //     _progressController.add(progress);

  //     CustomToast.show(
  //       context: context,
  //       message: "Failed to generate report",
  //       type: ToastType.error,
  //     );

  //     onError(e.toString());
  //   }
  // }

  static Future<void> downloadFile({
    required BuildContext context,
    required String url,
    required String fileName,
    required String format,
    required String contentType,
    dynamic jsonData, // Add this optional parameter
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    String downloadId = DateTime.now().millisecondsSinceEpoch.toString();

    DownloadProgress progress = DownloadProgress(
      id: downloadId,
      fileName: fileName,
      status: DownloadStatus.starting,
      progress: 0,
      url: url,
      startTime: DateTime.now(),
      format: format,
    );

    try {
      _activeDownloads[downloadId] = progress;
      _progressController.add(progress);

      CustomToast.show(
        context: context,
        message: "Generating Report...",
        type: ToastType.loading,
      );

      Uint8List bytes;
      bool isBinary = false;
      late dynamic contentToDownload;

      // If jsonData is provided, use it; otherwise fetch from URL
      if (jsonData != null) {
        // Use the pre-fetched data
        switch (format.toLowerCase()) {
          case 'csv':
            contentToDownload = _convertJsonToCsv(jsonData);
            break;
          case 'json':
            contentToDownload = _convertJsonToJson(jsonData);
            break;
          case 'xml':
            contentToDownload = _convertJsonToXml(jsonData);
            break;
          case 'xlsx':
            contentToDownload = _convertJsonToXlsx(jsonData);
            isBinary = true;
            break;
          case 'logs':
            contentToDownload = _convertJsonToLogs(jsonData);
            break;
          default:
            contentToDownload = json.encode(jsonData);
        }
      } else {
        // Fallback to fetching from URL (original code)
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('accessToken');

        if (token == null) {
          throw Exception("Authentication required - Please login again");
        }

        final uri = Uri.parse(url);
        final response = await http.get(
          uri,
          headers: {
            "Authorization": "Bearer $token",
            "Accept": "application/json",
          },
        );

        if (response.statusCode != 200) {
          throw Exception("Download failed: HTTP ${response.statusCode}");
        }

        final fetchedJsonData = json.decode(response.body);

        switch (format.toLowerCase()) {
          case 'csv':
            contentToDownload = _convertJsonToCsv(fetchedJsonData);
            break;
          case 'json':
            contentToDownload = _convertJsonToJson(fetchedJsonData);
            break;
          case 'xml':
            contentToDownload = _convertJsonToXml(fetchedJsonData);
            break;
          case 'xlsx':
            contentToDownload = _convertJsonToXlsx(fetchedJsonData);
            isBinary = true;
            break;
          case 'logs':
            contentToDownload = _convertJsonToLogs(fetchedJsonData);
            break;
          default:
            contentToDownload = json.encode(fetchedJsonData);
        }
      }

      if (isBinary) {
        if (contentToDownload is List<int>) {
          bytes = Uint8List.fromList(contentToDownload);
        } else if (contentToDownload is Uint8List) {
          bytes = contentToDownload;
        } else {
          throw Exception("Invalid binary data format");
        }
      } else {
        bytes = Uint8List.fromList(utf8.encode(contentToDownload));
      }

      await FileSaver.instance.saveFile(
        name: fileName.split('.').first,
        bytes: bytes,
        ext: format,
        mimeType: MimeType.other,
      );

      progress = progress.copyWith(
        status: DownloadStatus.completed,
        progress: 100,
        endTime: DateTime.now(),
      );

      _activeDownloads[downloadId] = progress;
      _progressController.add(progress);

      CustomToast.show(
        context: context,
        message: "Download complete",
        type: ToastType.success, // Change from loading to success
      );

      onSuccess("File downloaded: $fileName");
    } catch (e) {
      progress = progress.copyWith(
        status: DownloadStatus.failed,
        error: e.toString(),
        endTime: DateTime.now(),
      );

      _activeDownloads[downloadId] = progress;
      _progressController.add(progress);

      onError(e.toString());
    }
  }

  static Future<void> downloadBytes({
    required BuildContext context,
    required String fileName,
    required Uint8List bytes,
    required String format,
    required String contentType,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    String downloadId = DateTime.now().millisecondsSinceEpoch.toString();

    DownloadProgress progress = DownloadProgress(
      id: downloadId,
      fileName: fileName,
      status: DownloadStatus.starting,
      progress: 0,
      url: '',
      startTime: DateTime.now(),
      format: format,
    );

    try {
      _activeDownloads[downloadId] = progress;
      _progressController.add(progress);

      CustomToast.show(
        context: context,
        message: "Generating Report...",
        type: ToastType.loading,
      );

      await FileSaver.instance.saveFile(
        name: fileName.split('.').first,
        bytes: bytes,
        ext: format,
        mimeType: MimeType.other,
      );

      progress = progress.copyWith(
        status: DownloadStatus.completed,
        progress: 100,
        endTime: DateTime.now(),
      );

      _activeDownloads[downloadId] = progress;
      _progressController.add(progress);

      CustomToast.show(
        context: context,
        message: "Generating Report...",
        type: ToastType.loading,
      );

      onSuccess("File downloaded: $fileName");
    } catch (e) {
      progress = progress.copyWith(
        status: DownloadStatus.failed,
        error: e.toString(),
        endTime: DateTime.now(),
      );

      _activeDownloads[downloadId] = progress;
      _progressController.add(progress);

      CustomToast.show(
        context: context,
        message: "Failed to Generate Report",
        type: ToastType.error,
      );

      onError(e.toString());
    }
  }

  static String _convertJsonToCsv(dynamic jsonData) {
    final buffer = StringBuffer();

    if (jsonData is Map && jsonData.containsKey('entities')) {
      final entities = jsonData['entities'] as List;

      if (entities.isEmpty) return "";

      final headers = (entities.first as Map).keys.toList();
      buffer.writeln(headers.join(','));

      for (var entity in entities) {
        final row = headers
            .map((h) {
              var value = entity[h]?.toString() ?? '';

              if (value.contains(',')) {
                value = '"$value"';
              }

              return value;
            })
            .join(',');

        buffer.writeln(row);
      }
    }

    return buffer.toString();
  }

  static String _convertJsonToJson(dynamic jsonData) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(jsonData);
  }

  static String _convertJsonToXml(dynamic jsonData) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0"?>');
    buffer.writeln('<tripReport>');

    if (jsonData is Map && jsonData.containsKey('entities')) {
      for (var entity in jsonData['entities']) {
        buffer.writeln('<trip>');
        (entity as Map).forEach((k, v) {
          buffer.writeln('<$k>${v ?? ''}</$k>');
        });
        buffer.writeln('</trip>');
      }
    }

    buffer.writeln('</tripReport>');
    return buffer.toString();
  }

  // static List<int> _convertJsonToXlsx(dynamic jsonData) {
  //   try {
  //     var excel = Excel.createExcel();

  //     final defaultSheet = excel.getDefaultSheet();
  //     if (defaultSheet != null) {
  //       excel.rename(defaultSheet, "Report");
  //     }

  //     final sheet = excel["Report"];

  //     if (jsonData == null ||
  //         jsonData is! Map ||
  //         !jsonData.containsKey('entities')) {
  //       throw Exception("Invalid JSON structure");
  //     }

  //     final List entities = jsonData['entities'];

  //     if (entities.isEmpty) {
  //       throw Exception("No data available");
  //     }

  //     final headers = <String>{};
  //     for (var item in entities) {
  //       headers.addAll((item as Map).keys.map((e) => e.toString()));
  //     }

  //     final headerList = headers.toList();

  //     // Headers
  //     for (int col = 0; col < headerList.length; col++) {
  //       sheet.updateCell(
  //         CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
  //         TextCellValue(headerList[col]),
  //       );
  //     }

  //     // Data
  //     for (int row = 0; row < entities.length; row++) {
  //       final rowData = entities[row] as Map;

  //       for (int col = 0; col < headerList.length; col++) {
  //         final key = headerList[col];
  //         final value = rowData[key];

  //         sheet.updateCell(
  //           CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 1),
  //           TextCellValue(value?.toString() ?? ''),
  //         );
  //       }
  //     }

  //     final fileBytes = excel.save();

  //     if (fileBytes == null || fileBytes.isEmpty) {
  //       throw Exception("Excel file generation failed");
  //     }

  //     return fileBytes;
  //   } catch (e) {
  //     print("Excel conversion error: $e");
  //     rethrow;
  //   }
  // }
  static List<int> _convertJsonToXlsx(dynamic jsonData) {
    try {
      var excel = Excel.createExcel();

      final sheetName = "Report";

      final sheet = excel[sheetName];

      excel.setDefaultSheet(sheetName);
      excel.delete('Sheet1'); // Remove default sheet if it exists
      if (jsonData == null ||
          jsonData is! Map ||
          !jsonData.containsKey('entities')) {
        throw Exception("Invalid JSON structure");
      }

      final List entities = jsonData['entities'];

      if (entities.isEmpty) {
        final emptyBytes = excel.encode();
        return emptyBytes ?? [];
      }

      final headers = <String>{};
      for (var item in entities) {
        headers.addAll((item as Map).keys.map((e) => e.toString()));
      }

      final headerList = headers.toList();

      List<TextCellValue> headerCells = [];
      for (int col = 0; col < headerList.length; col++) {
        headerCells.add(TextCellValue(headerList[col]));
      }
      sheet.appendRow(headerCells);

      for (int row = 0; row < entities.length; row++) {
        final rowData = entities[row] as Map;
        List<TextCellValue> rowCells = [];

        for (int col = 0; col < headerList.length; col++) {
          final key = headerList[col];
          final value = rowData[key];
          rowCells.add(TextCellValue(value?.toString() ?? ''));
        }
        sheet.appendRow(rowCells);
      }

      final fileBytes = excel.encode();

      if (fileBytes == null || fileBytes.isEmpty) {
        throw Exception("Excel file generation failed");
      }

      return fileBytes;
    } catch (e) {
      print("Excel conversion error: $e");
      // Return empty list instead of rethrowing
      return [];
    }
  }

  static String _convertJsonToLogs(dynamic jsonData) {
    final buffer = StringBuffer();

    if (jsonData is Map && jsonData.containsKey('entities')) {
      for (var entity in jsonData['entities']) {
        (entity as Map).forEach((k, v) {
          buffer.writeln("$k : ${v ?? ''}");
        });
        buffer.writeln("----------------------");
      }
    }

    return buffer.toString();
  }
}
