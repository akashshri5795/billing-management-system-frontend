import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class LedgerService {
  static Future<List<dynamic>> getTransactionTypes() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/transaction_type"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['transactions'];
    } else {
      throw Exception("Failed to load transaction types");
    }
  }

  static Future<void> addLedger({
    required int partyId,
    required int transactionTypeId,
    required String entryDate,
    required String voucherNo,
    required double amount,
    required String type,
    String? narration,
    String? remark,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/ledger"),
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "party_id": partyId,
        "transaction_type_id": transactionTypeId,
        "entry_date": entryDate,
        "voucher_no": voucherNo,
        "amount": amount,
        "type": type,
        "narration": narration,
        "remark": remark,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception("Failed to save ledger");
    }
  }

  static Future<Map<String, dynamic>> getLedgerByParty(int partyId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/ledger-details/$partyId"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception("Failed to load ledger");
    }
  }
}


