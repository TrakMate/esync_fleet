import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/userReportModel.dart';
import '../../apiURL.dart';

class ReportsApiService {
  Future<UserReportModel> fetchUserReport({
    String? groupId,
    String? imei,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    final uri = Uri.parse("${BaseURLConfig.reportsApiUrl}/user-report").replace(
      queryParameters: {
        if (groupId != null && groupId.isNotEmpty) 'groupId': groupId,
        if (imei != null && imei.isNotEmpty) 'imei': imei,
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return UserReportModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load user report: ${response.statusCode}');
    }
  }
}
