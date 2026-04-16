import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/deviceOverviewModel.dart';
import '../../../models/imeiAlertsDetailsModel.dart';
import '../../../models/imeiDistSpeedSocModel.dart';
import '../../../models/imeiGraphModel.dart';
import '../../../models/imeiTripMappointsModel.dart';
import '../../../models/imeiTripsDetailsModel.dart';
import '../../../models/imeiVehicleGraphModel.dart';
import '../../../models/tripMAPModel.dart';
import '../../apiURL.dart';

class IMEIAlertsApiService {
  static const String baseUrl = BaseURLConfig.deviceAlertsApiUrl;

  Future<IMEIAlertsDetailsModel> fetchAlerts({
    required String imei,
    DateTime? date,
    required int currentIndex,
    required int sizePerPage,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    final queryParams = {
      "currentIndex": currentIndex.toString(),
      "sizePerPage": sizePerPage.toString(),
      if (date != null)
        "date": date.toIso8601String().split('T').first, // yyyy-MM-dd
    };

    final uri = Uri.parse(
      "$baseUrl/$imei",
    ).replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      return IMEIAlertsDetailsModel.fromJson(json.decode(response.body));
    } else {
      throw Exception("Failed to load alerts");
    }
  }
}

class IMEITripsApiService {
  static const String baseUrl = BaseURLConfig.deviceTripsApiUrl;

  Future<IMEITripDetailsModel> fetchTrips({
    required String imei,
    DateTime? date,
    required int currentIndex,
    required int sizePerPage,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    final queryParams = {
      "currentIndex": currentIndex.toString(),
      "sizePerPage": sizePerPage.toString(),
      if (date != null) "date": date.toIso8601String().split('T').first,
    };
    final uri = Uri.parse(
      "$baseUrl/$imei",
    ).replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      return IMEITripDetailsModel.fromJson(json.decode(response.body));
    } else {
      throw Exception("Failed to load imwi trips");
    }
  }
}

class IMEITripMapPointsApiService {
  static const String baseUrl = BaseURLConfig.deviceTripMapPointsApiUrl;

  Future<IMEITripMapPointsModel> fetchTripMapPoints({
    required String imei,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    final uri = Uri.parse("$baseUrl/$imei");

    final response = await http.get(
      uri,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      return IMEITripMapPointsModel.fromJson(json.decode(response.body));
    } else {
      throw Exception("Failed to load trip map points: ${response.body}");
    }
  }
}

class IMEITripMapApiService {
  static const String baseUrl = BaseURLConfig.deviceTripMapApiUrl;

  Future<TripMapPerTripModel> fetchTripMap({
    required String imei,
    DateTime? date,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    // final String currentDate =
    //     DateTime.now().toIso8601String().split('T').first;
    final DateTime finalDate = date ?? DateTime.now();

    final String formattedDate =
        "${finalDate.year.toString().padLeft(4, '0')}-"
        "${finalDate.month.toString().padLeft(2, '0')}-"
        "${finalDate.day.toString().padLeft(2, '0')}";
    final uri = Uri.parse(
      "$baseUrl/$imei",
    ).replace(queryParameters: {'date': formattedDate});

    final response = await http.get(
      uri,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      return TripMapPerTripModel.fromJson(json.decode(response.body));
    } else {
      throw Exception(
        "Failed to load trip map: ${response.statusCode} ${response.body}",
      );
    }
  }
}

class IMEIGraphApiService {
  static const String baseUrl = BaseURLConfig.deviceGraphApiUrl;

  Future<IMEIGraphModel> fetchimeiGraph({
    required String imei,
    // required DateTime date,
    DateTime? date,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? '';

    // final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final formattedDate = date?.toUtc().toIso8601String();

    final uri = Uri.parse(
      '$baseUrl/$imei',
    ).replace(queryParameters: {'date': formattedDate});

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return IMEIGraphModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('Failed to load vehicle graph (${response.statusCode})');
    }
  }
}

class IMEISpeedDistanceApiService {
  static const String baseUrl = BaseURLConfig.deviceDistSpeedSocApiUrl;

  Future<IMEIDistSpeedSocModel> fetchSpeedDistanceSoc({
    required String imei,
    DateTime? date,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? '';

    final formattedDate =
        date != null
            ? "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}"
            : null;
    final queryParams = <String, String>{};

    if (formattedDate != null) {
      queryParams['dateStr'] = formattedDate;
    }

    final uri = Uri.parse(
      '$baseUrl/$imei',
    ).replace(queryParameters: queryParams.isEmpty ? null : queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return IMEIDistSpeedSocModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception(
        'Failed to load speed-distance-SOC data (${response.statusCode})',
      );
    }
  }
}

class IMEIVehicleGraphApiService {
  static const String baseUrl = BaseURLConfig.deviceVehicleGraphApiUrl;

  Future<IMEIVehicleGraphModel> fetchVehicleGraph({
    required String imei,
    // required DateTime date,
    DateTime? date,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? '';

    final formattedDate = date?.toUtc().toIso8601String();

    final uri = Uri.parse(
      '$baseUrl/$imei',
    ).replace(queryParameters: {'date': formattedDate});

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return IMEIVehicleGraphModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception('Failed to load vehicle graph (${response.statusCode})');
    }
  }
}

class DeviceOverviewApiService {
  static const String baseUrl = BaseURLConfig.deviceOverviewApiUrl;

  Future<DeviceOverviewModel> fetchDeviceOverview({
    required String imei,
    DateTime? date,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? '';

    final formattedDate =
        date != null
            ? "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}"
            : null;

    final uri = Uri.parse(
      '$baseUrl/$imei',
    ).replace(queryParameters: {'dateStr': formattedDate});
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return DeviceOverviewModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } else {
      throw Exception(
        'Failed to load device overview (${response.statusCode})',
      );
    }
  }
}
