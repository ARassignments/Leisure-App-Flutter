import 'dart:convert';
import 'package:http/http.dart' as http;
import '/Models/customer_model.dart';
import '/utils/session_manager.dart';

class ApiService {
  static const String baseUrl = "http://y2ksolutions.com/api/MobileAppApi";

  static Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse("$baseUrl/login"); // Replace with correct endpoint

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "UserName": username,
        "Password": password,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to login: ${response.body}");
    }
  }

  static Future<List<Customer>> fetchCustomers() async {
    final user = await SessionManager.getUser();
    if (user == null || user['OrganizationId'] == null) {
      return [];
    }

    final orgId = user['OrganizationId'];

    final url = Uri.parse("$baseUrl/Users?OrganizationId=$orgId");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['Success'] == true && data['Accounts'] != null) {
        return (data['Accounts'] as List)
            .map((json) => Customer.fromJson(json))
            .toList();
      }
    }
    return [];
  }
}
