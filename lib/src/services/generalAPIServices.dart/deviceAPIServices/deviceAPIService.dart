import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/devicesMapModel.dart';
import '../../../models/devicesModel.dart';
import '../../apiURL.dart';

// class DevicesApiService {
//   static const String baseUrl = BaseURLConfig.deviceDetailsApiUrl;

//   Future<DevicesModel> fetchDevices({
//     required int currentIndex,
//     required int sizePerPage,
//     String? status,
//     String? search,
//     List<String>? selectedStatuses,
//   }) async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('accessToken');

//     final uri = Uri.parse(baseUrl).replace(
//       queryParameters: {
//         'currentIndex': currentIndex.toString(),
//         'sizePerPage': sizePerPage.toString(),
//         if (status != null && status.isNotEmpty) 'status': status,
//       },
//     );

//     final response = await http.get(
//       uri,
//       headers: {
//         'Authorization': 'Bearer $token',
//         'Content-Type': 'application/json',
//       },
//     );

//     if (response.statusCode == 200) {
//       return DevicesModel.fromJson(jsonDecode(response.body));
//     } else {
//       throw Exception('Failed to load devices');
//     }
//   }
// }

class DevicesApiService {
  static const String baseUrl = BaseURLConfig.deviceDetailsApiUrl;

  Future<DevicesModel> fetchDevices({
    required int currentIndex,
    required int sizePerPage,
    String? status,
    String? search,
    String? SOC,
    List<String>? selectedStatuses,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    String statusPath = 'all';

    if (status != null && status.isNotEmpty && status != 'all') {
      statusPath = status;
    } else if (selectedStatuses != null && selectedStatuses.isNotEmpty) {
      statusPath = selectedStatuses.first.toLowerCase();
    }

    final uri = Uri.parse("$baseUrl/$statusPath").replace(
      queryParameters: {
        'currentIndex': currentIndex.toString(),
        'sizePerPage': sizePerPage.toString(),
        if (search != null && search.isNotEmpty) 'searchText': search,
        if (SOC != null && SOC.isNotEmpty) 'SOC': SOC,
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
      return DevicesModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load devices');
    }
  }
}

class DevicesMapApiService {
  static const String baseUrl = BaseURLConfig.devicesMapApiUrl;

  Future<DevicesMapModel> fetchDevicesMap({String? status}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    final uri = Uri.parse(baseUrl).replace(
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
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
      return DevicesMapModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load devices map');
    }
  }
}
