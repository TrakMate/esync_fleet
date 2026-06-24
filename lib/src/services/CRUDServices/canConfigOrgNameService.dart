import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/CRUDModels/cancofigOrgNameModel.dart';
import '../apiURL.dart';

class CanConfigOrgNameService {
  static const String _base = BaseURLConfig.canConfigOrgNameApiUrl;

  Future<canConfigOrgNameModel?> fetchOrgCanTabMapping() async {
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

      debugPrint("Org CAN Mapping API URL : $uri");

      if (response.statusCode == 200) {
        return canConfigOrgNameModel.fromJson(json.decode(response.body));
      } else {
        debugPrint(
          "Org CAN Mapping API Error "
          "(${response.statusCode}) : ${response.body}",
        );
        return null;
      }
    } catch (e) {
      debugPrint("Exception in fetchOrgCanTabMapping : $e");
      return null;
    }
  }
}
