import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/downloadTripModel.dart';
import '../apiURL.dart';

class Downloadtripapiservice {
  static const String _base = BaseURLConfig.tripsApiUrl;

  //Route Playback Per Trip
  Future<DownloadTripModel?> fetchDetatledTripData(String tripId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("accessToken") ?? "";

    final url = BaseURLConfig.downloadDetailedTripApiUrl.replaceAll(
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
      return DownloadTripModel.fromJson(json.decode(response.body));
    } else {
      debugPrint(
        "Download Trip error (${response.statusCode}): ${response.body}",
      );
      return null;
    }
  }
}
