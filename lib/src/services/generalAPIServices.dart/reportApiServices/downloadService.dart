import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
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
  static Future<void> downloadFile({
    required BuildContext context,

    required String url,
    required String fileName,
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

      // final jsonData = json.decode(response.body);
      final bytes = response.bodyBytes;

      // late dynamic contentToDownload;
      // bool isBinary = false;

      // switch (format.toLowerCase()) {
      //   case 'csv':
      //     contentToDownload = _convertJsonToCsv(jsonData);
      //     break;
      //   case 'json':
      //     contentToDownload = _convertJsonToJson(jsonData);
      //     break;
      //   case 'xml':
      //     contentToDownload = _convertJsonToXml(jsonData);
      //     break;
      //   case 'xlsx':
      //     contentToDownload = _convertJsonToXlsx(jsonData);
      //     isBinary = true;
      //     break;
      //   case 'logs':
      //     contentToDownload = _convertJsonToLogs(jsonData);
      //     break;
      //   default:
      //     contentToDownload = json.encode(jsonData);
      // }

      // Uint8List bytes;

      // if (isBinary) {
      //   bytes = Uint8List.fromList(contentToDownload);
      // } else {
      //   bytes = Uint8List.fromList(utf8.encode(contentToDownload));
      // }

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
        message: "Failed to generate report",
        type: ToastType.error,
      );

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
  //     Sheet sheetObject = excel['Trip Report'];

  //     if (jsonData is Map && jsonData.containsKey('entities')) {
  //       final entities = jsonData['entities'] as List;

  //       if (entities.isEmpty) return [];

  //       final headers = (entities.first as Map).keys.toList();

  //       for (int i = 0; i < headers.length; i++) {
  //         sheetObject.updateCell(
  //           CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
  //           TextCellValue(headers[i]),
  //         );
  //       }

  //       for (int row = 0; row < entities.length; row++) {
  //         final entity = entities[row] as Map;

  //         for (int col = 0; col < headers.length; col++) {
  //           sheetObject.updateCell(
  //             CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 1),
  //             TextCellValue(entity[headers[col]]?.toString() ?? ''),
  //           );
  //         }
  //       }
  //     }

  //     return excel.save() ?? [];
  //   } catch (e) {
  //     return [];
  //   }
  // }

  static List<int> _convertJsonToXlsx(dynamic jsonData) {
    try {
      var excel = Excel.createExcel();

      String defaultSheet = excel.getDefaultSheet()!;

      excel.rename(defaultSheet, "Report");

      Sheet sheetObject = excel["Report"];

      if (jsonData is Map && jsonData.containsKey('entities')) {
        final entities = jsonData['entities'] as List;

        if (entities.isEmpty) return [];

        final headers = (entities.first as Map).keys.toList();

        // Headers
        for (int i = 0; i < headers.length; i++) {
          sheetObject.updateCell(
            CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
            TextCellValue(headers[i]),
          );
        }

        // Data
        for (int row = 0; row < entities.length; row++) {
          final entity = entities[row] as Map;

          for (int col = 0; col < headers.length; col++) {
            sheetObject.updateCell(
              CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 1),
              TextCellValue(entity[headers[col]]?.toString() ?? ''),
            );
          }
        }
      }

      return excel.save() ?? [];
    } catch (e) {
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
