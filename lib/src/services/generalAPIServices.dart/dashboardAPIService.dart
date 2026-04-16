import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/alertDashboardModel.dart';
import '../../models/alertGraphModel.dart';
import '../../models/dashboardDetailsModel.dart';
import '../../models/tripGraphModel.dart';
import '../../models/tripsDashboardModel.dart';
import '../../models/vehicleDashboardModel.dart';
import '../apiURL.dart';

class DashboardApiService {
  static const String baseUrl = BaseURLConfig.dashboardApiUrl;

  Future<DashboardDetailModel> fetchDashboardDetails({
    String? date, // yyyy-MM-dd
    String? groupId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    final uri = Uri.parse(baseUrl).replace(
      queryParameters: {
        if (date != null && date.isNotEmpty) 'date': date,
        if (groupId != null && groupId.isNotEmpty) 'groupId': groupId,
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
      return DashboardDetailModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        'Failed to load dashboard details: ${response.statusCode}',
      );
    }
  }

  Future<AlertDashboardModel> fetchAlertDetails({
    String? date, // yyyy-MM-dd
    String? groupId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    final uri = Uri.parse(BaseURLConfig.alertDashboardApiUrl).replace(
      queryParameters: {
        if (date != null && date.isNotEmpty) 'date': date,
        if (groupId != null && groupId.isNotEmpty) 'groupId': groupId,
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
      return AlertDashboardModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        'Failed to load dashboard details: ${response.statusCode}',
      );
    }
  }

  Future<TripDashboardModel> fetchTripsDetails({
    String? date, // yyyy-MM-dd
    String? groupId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    final uri = Uri.parse(BaseURLConfig.tripDashboardApiUrl).replace(
      queryParameters: {
        if (date != null && date.isNotEmpty) 'date': date,
        if (groupId != null && groupId.isNotEmpty) 'groupId': groupId,
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
      return TripDashboardModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        'Failed to load dashboard details: ${response.statusCode}',
      );
    }
  }

  Future<VehicleDashboardModel> fetchVehicleDetails({
    String? date, // yyyy-MM-dd
    String? groupId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    final uri = Uri.parse(BaseURLConfig.vehicleDashboardApiUrl).replace(
      queryParameters: {
        if (date != null && date.isNotEmpty) 'date': date,
        if (groupId != null && groupId.isNotEmpty) 'groupId': groupId,
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
      return VehicleDashboardModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        'Failed to load dashboard details: ${response.statusCode}',
      );
    }
  }

  Future<AlertGraphModel> fetchAlertGraph({
    String? date,
    String? groupId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    final uri = Uri.parse(BaseURLConfig.alertGraphApiUrl).replace(
      queryParameters: {
        if (date != null && date.isNotEmpty) 'date': date,
        if (groupId != null && groupId.isNotEmpty) 'groupId': groupId,
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
      return AlertGraphModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load alert dashboard: ${response.statusCode}');
    }
  }

  Future<TripGraphModel> fetchTripsGraph({
    String? date, // yyyy-MM-dd
    String? groupId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    final uri = Uri.parse(BaseURLConfig.tripGraphApiUrl).replace(
      queryParameters: {
        if (date != null && date.isNotEmpty) 'date': date,
        if (groupId != null && groupId.isNotEmpty) 'groupId': groupId,
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
      return TripGraphModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        'Failed to load dashboard details: ${response.statusCode}',
      );
    }
  }
}
