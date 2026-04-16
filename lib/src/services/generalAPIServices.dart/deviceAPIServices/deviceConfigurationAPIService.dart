import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/imeiCommandsModel.dart';
import '../../apiURL.dart';

class IMEICommandsApiService {
  static const String baseUrl = BaseURLConfig.deviceConfigurationApiUrl;

  Future<IMEICommandsModel> fetchCommands({
    required String imei,
    required int page,
    required int sizePerPage,
    required int currentIndex,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    final uri = Uri.parse(
      '$baseUrl/$imei'
      '?page=$page'
      '&sizePerPage=$sizePerPage'
      '&currentIndex=$currentIndex',
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      return IMEICommandsModel.fromJson(json);
    } else {
      throw Exception('Failed to fetch IMEI commands (${response.statusCode})');
    }
  }

  Future<void> sendCommand({
    required String imei,
    required String command,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    final uri = Uri.parse('$baseUrl/$imei');

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({"command": command}),
    );

    // if (response.statusCode != 200 || response.statusCode != 201) {
    //   throw Exception('Failed to send command (${response.statusCode})');
    // }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to send command (${response.statusCode})');
    }
  }
}
