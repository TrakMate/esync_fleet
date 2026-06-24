import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/CRUDModels/canConfigTabNameModel.dart';
import '../apiURL.dart';

class CanConfigTabNameApiService {
  static const String _base = BaseURLConfig.canTabNameApiUrl;

  // Fetch CAN Config Tab Names
  Future<canConfigTabNameModel?> fetchCanTabNames() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("accessToken") ?? "";

      final uri = Uri.parse(_base);

      final response = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      debugPrint("CAN Config API URL : $uri");

      if (response.statusCode == 200) {
        return canConfigTabNameModel.fromJson(json.decode(response.body));
      } else {
        debugPrint(
          "CAN Config API Error (${response.statusCode}) : ${response.body}",
        );
        return null;
      }
    } catch (e) {
      debugPrint("Exception in fetchCanTabNames : $e");
      return null;
    }
  }
}
