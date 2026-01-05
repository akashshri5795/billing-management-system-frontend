import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';

class UserPartyService {
  static Future<List<dynamic>> getUserParties() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/user/party"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['party'] as List<dynamic>?) ?? [];
    } else {
      throw Exception("Failed to load parties");
    }
  }

  static Future<Map<String, dynamic>> getUserPartyDetail(int id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/user/party/$id"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['party'] != null && data['party'].isNotEmpty) {
        return (data['party'][0] as Map<String, dynamic>);
      } else {
        throw Exception("Party not found");
      }

    } else {
      throw Exception("Failed to load party detail");
    }
  }

  static Future<List<dynamic>> getUserPartyLedgerDetail(int partyId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/user/ledger-details/$partyId"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data != null && data['ledger'] != null) {
        return data['ledger'] as List<dynamic>; // ✅ Return full ledger list
      } else {
        return []; // Empty list if ledger not found
      }

    } else {
      throw Exception("Failed to load ledger detail");
    }
  }


}
