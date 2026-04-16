import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

Future<String> getAddressFromLatLngWeb(double lat, double lng) async {
  try {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse'
      '?format=json'
      '&lat=$lat'
      '&lon=$lng'
      '&zoom=18'
      '&addressdetails=1',
    );

    final response = await http.get(
      url,
      headers: {
        // REQUIRED by Nominatim policy
        'User-Agent': 'your-app-name/1.0',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return data['display_name'] ?? '$lat, $lng';
    }
  } catch (e) {
    debugPrint('Web geocoding error: $e');
  }

  return '$lat, $lng';
}

Future<String> getAddressFromLocationStringWeb(String location) async {
  final parts = location.split(',');
  if (parts.length != 2) return location;

  final lat = double.tryParse(parts[0].trim());
  final lng = double.tryParse(parts[1].trim());

  if (lat == null || lng == null) return location;

  return await getAddressFromLatLngWeb(lat, lng);
}
