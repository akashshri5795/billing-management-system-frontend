import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rbcledger/config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Emulator
  static Future<String?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/login"),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", data['token']);
        await prefs.setInt("userId", data['user']['id']);
        await prefs.setString("role", data['user']['role']);

        return data['user']['role'];
      } else {
        return null;
      }
    } catch (e) {
      print("Login Error: $e");
      return null;
    }
  }

  static Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
  }

  static Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }
}
