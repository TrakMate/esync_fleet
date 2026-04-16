import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/tripRoutePlayBackModel.dart';
import '../../models/tripsModel.dart';
import '../apiURL.dart';

class TripsApiService {
  static const String _base = BaseURLConfig.tripsApiUrl;

  Future<TripsModel?> fetchTrips({
    required int page,
    required int size,
    required String status,
    String? inputImei,
    DateTime? inputDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("accessToken") ?? "";
    final formattedDate =
        inputDate != null ? DateFormat('yyyy-MM-dd').format(inputDate) : null;

    final uri = Uri.parse("$_base/$status").replace(
      queryParameters: {
        "page": page.toString(),
        "size": size.toString(),
        if (formattedDate != null) "inputDate": formattedDate,
        if (inputImei != null && inputImei.isNotEmpty) "inputImei": inputImei,
      },
    );

    final response = await http.get(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
    print(uri);

    if (response.statusCode == 200) {
      return TripsModel.fromJson(json.decode(response.body));
    } else {
      debugPrint("Trips API error: ${response.statusCode}");
      return null;
    }
  }

  //Route Playback Per Trip
  Future<RoutePlayBackPerTripModel?> fetchTripRoutePlayback(
    String tripId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("accessToken") ?? "";

    final url = BaseURLConfig.tripsRoutePlayBackPerTripIDApiUrl.replaceAll(
      '{tripId}',
      tripId,
    );
    final uri = Uri.parse(url);

    final response = await http.get(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return RoutePlayBackPerTripModel.fromJson(json.decode(response.body));
    } else {
      debugPrint(
        "Route Playback API error (${response.statusCode}): ${response.body}",
      );
      return null;
    }
  }
}
