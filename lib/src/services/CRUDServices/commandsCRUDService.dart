import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/CRUDModels/commandsCRUDModel.dart';
import '../apiURL.dart';

class CommandsApiService {
  Future<CommandsCRUDModel> fetchCommands({
    required int page,
    required int sizePerPage,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("accessToken") ?? "";

    final url =
        "${BaseURLConfig.commandsALLApiURL}"
        "?page=$page"
        "&sizePerPage=$sizePerPage"
        "&currentIndex=${(page - 1) * sizePerPage}";

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      return CommandsCRUDModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Failed to load commands (${response.statusCode})");
    }
  }

  /// SEND MULTIPLE COMMANDS
  Future<String> sendMulCommand(MulCommandRequest request) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("accessToken") ?? "";

    final response = await http.post(
      Uri.parse("${BaseURLConfig.baseURL}/api/mulcommands"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception(response.body);
    }
  }
}

// class MulCommandRequest {
//   final String command;
//   final List<String> imeis;

//   MulCommandRequest({required this.command, required this.imeis});

//   Map<String, dynamic> toJson() {
//     return {"command": command, "imeis": imeis};
//   }
// }

class MulCommandRequest {
  final String command;
  final List<String> groups;

  MulCommandRequest({required this.command, required this.groups});

  Map<String, dynamic> toJson() {
    return {"command": command, "groups": groups};
  }
}
