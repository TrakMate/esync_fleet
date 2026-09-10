import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/deviceDiagnosticModel.dart';
import '../../apiURL.dart';

class DeviceDiagnosticAPIService {
  static const String baseUrl = BaseURLConfig.deviceDiagnosticApiUrl;

  Future<DeviceDiagnosticModel> fetchdevicediagnostic({
    required String imei,
    String? date,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? '';

    Uri uri;
    if (date != null && date.isNotEmpty) {
      uri = Uri.parse('$baseUrl/$imei?date=$date');
    } else {
      uri = Uri.parse(
        '$baseUrl/$imei?date=${DateTime.now().toIso8601String().split('T')[0]}',
      );
    }

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return DeviceDiagnosticModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception(
        'Failed to load device diagnostic (${response.statusCode})',
      );
    }
  }
}
