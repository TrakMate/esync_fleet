// import 'dart:convert';

// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';

// import '../../models/alertsModel.dart';
// import '../apiURL.dart';

// class AlertsApiService {
//   static const String baseUrl = BaseURLConfig.alertsApiUrl;

//   Future<AlertsModel> fetchAlerts({
//     String type = "all", // default
//     String? searchText,
//     String? date,
//     required int currentIndex,
//     required int sizePerPage,
//   }) async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('accessToken');

//     final url = "$baseUrl/$type";

//     final queryParams = {
//       'currentIndex': currentIndex.toString(),
//       'sizePerPage': sizePerPage.toString(),
//     };

//     if (searchText != null && searchText.isNotEmpty) {
//       queryParams['searchText'] = searchText;
//     }

//     if (date != null && date.isNotEmpty) {
//       queryParams['date'] = date;
//     }

//     final uri = Uri.parse(url).replace(queryParameters: queryParams);

//     final response = await http.get(
//       uri,
//       headers: {
//         "Authorization": "Bearer $token",
//         "Content-Type": "application/json",
//       },
//     );

//     if (response.statusCode == 200) {
//       return AlertsModel.fromJson(json.decode(response.body));
//     } else {
//       throw Exception("Failed to load alerts");
//     }
//   }
// }

// // class AlertsApiService {
// //   static const String baseUrl = BaseURLConfig.alertsApiUrl;

// //   Future<AlertsModel> fetchAlerts({
// //     String? searchText,
// //     String? date,
// //     required int currentIndex,
// //     required int sizePerPage,
// //   }) async {
// //     final prefs = await SharedPreferences.getInstance();
// //     final token = prefs.getString('accessToken');

// //     final queryParams = {
// //       'currentIndex': currentIndex.toString(),
// //       'sizePerPage': sizePerPage.toString(),
// //     };

// //     if (searchText != null && searchText.isNotEmpty) {
// //       queryParams['searchText'] = searchText;
// //     }
// //     if (date != null && date.isNotEmpty) {
// //       queryParams['date'] = date;
// //     }

// //     final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
// //     final response = await http.get(
// //       uri,
// //       headers: {
// //         "Authorization": "Bearer $token",
// //         "Content-Type": "application/json",
// //       },
// //     );

// //     if (response.statusCode == 200) {
// //       return AlertsModel.fromJson(json.decode(response.body));
// //     } else {
// //       throw Exception("Failed to load alerts");
// //     }
// //   }
// // }
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/alertsModel.dart';
import '../apiURL.dart';

class AlertApiService {
  static const String baseUrl = BaseURLConfig.baseURL;
  static const String alertApiUrl = '$baseUrl/api/alerts';

  Future<AlertsModel> fetchAlerts({
    String? imei,
    required int currentIndex,
    required int sizePerPage,
    String? alertType,
    String? searchText,
    String? date,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    // Build query parameters
    final queryParams = {
      'currentIndex': currentIndex.toString(),
      'sizePerPage': sizePerPage.toString(),
    };

    if (alertType != null && alertType.isNotEmpty) {
      queryParams['alertType'] = alertType;
    }

    // Only add imei if provided and not empty
    if (imei != null && imei.isNotEmpty) {
      queryParams['imei'] = imei;
    }

    // Add optional parameters
    if (searchText != null && searchText.isNotEmpty) {
      queryParams['searchText'] = searchText;
    }

    if (date != null && date.isNotEmpty) {
      queryParams['date'] = date;
    }

    final uri = Uri.parse(alertApiUrl).replace(queryParameters: queryParams);

    try {
      final response = await http.get(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        return AlertsModel.fromJson(json.decode(response.body));
      } else {
        throw Exception("Failed to load alerts: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching alerts: $e");
    }
  }

  // Optional: Method to fetch critical alerts specifically
  Future<AlertsModel> fetchCriticalAlerts({
    String? imei,
    required int currentIndex,
    required int sizePerPage,
    String? searchText,
    String? date,
  }) async {
    return fetchAlerts(
      imei: imei,
      currentIndex: currentIndex,
      sizePerPage: sizePerPage,
      alertType: "CRITICAL",
      searchText: searchText,
      date: date,
    );
  }

  Future<AlertsModel> fetchNonCriticalAlerts({
    String? imei,
    required int currentIndex,
    required int sizePerPage,
    String? searchText,
    String? date,
  }) async {
    return fetchAlerts(
      imei: imei,
      currentIndex: currentIndex,
      sizePerPage: sizePerPage,
      alertType: "NON_CRITICAL",
      searchText: searchText,
      date: date,
    );
  }

  Future<AlertsModel> fetchAllAlerts({
    String? imei,
    required int currentIndex,
    required int sizePerPage,
    String? searchText,
    String? date,
  }) async {
    return fetchAlerts(
      imei: imei,
      currentIndex: currentIndex,
      sizePerPage: sizePerPage,
      alertType: "ALL",
      searchText: searchText,
      date: date,
    );
  }
}
