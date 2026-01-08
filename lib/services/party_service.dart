import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class PartyService {
  static Future<void> createParty({
    required String name,
    required String address,
    required String phone,
    String? email,
    required String type,
    required double openingBalance,
    required List<int> userIds,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final role = prefs.getString("role");

    if (token == null || role == null) {
      throw Exception("User not logged in");
    }
    if (role != "admin") {
      throw Exception("Unauthorized: Only admin can create party");
    }

    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/party"),
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "name": name,
        "address": address,
        "phone": phone,
        "email": email,
        'type':type,
        "opening_balance": openingBalance,
        "user_ids": userIds,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(response.body);
    }
  }

  static Future<void> updateParty({
    required int partyId,
    required String name,
    required String address,
    required String phone,
    required String type,
    String? email,
    required double openingBalance,
    required List<int> userIds,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final role = prefs.getString("role");

    if (token == null || role == null) {
      throw Exception("User not logged in");
    }
    if (role != "admin") {
      throw Exception("Unauthorized: Only admin can update party");
    }
    final response = await http.put(
      Uri.parse("${ApiConfig.baseUrl}/party/$partyId"),
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "name": name,
        "address": address,
        "phone": phone,
        "email": email,
        "type":type,
        "opening_balance": openingBalance,
        "user_ids": userIds,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to update party: ${response.body}");
    }
  }

  static Future<List<dynamic>> getParties() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final role = prefs.getString("role");

    if (token == null || role == null) {
      throw Exception("User not logged in");
    }
    if (role != "admin") {
      throw Exception("Unauthorized: Only admin can update party");
    }

    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/party"),
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

  static Future<Map<String, dynamic>> getPartyDetail(int partyId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final role = prefs.getString("role");

    if (token == null || role == null) {
      throw Exception("User not logged in");
    }
    String url;

    if (role == "admin") {
      url = "${ApiConfig.baseUrl}/party/$partyId";
    } else {
      url = "${ApiConfig.baseUrl}/user/party/$partyId";
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['party'] != null) {
        return Map<String, dynamic>.from(data['party']);
      } else {
        throw Exception("Party not found");
      }
    } else {
      throw Exception("Failed to load party detail");
    }
  }


  static Future<List<dynamic>> getUserPartyList() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final userId = prefs.getInt("userId");
    final role = prefs.getString("role");

    if (userId == null || token == null) {
      throw Exception("User not logged in");
    }
    if (role != "user") {
      throw Exception("Unauthorized: Only User can view List");
    }

    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/user/user-party-list/$userId"),
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
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
}
