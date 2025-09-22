import 'dart:convert';
import 'package:http/http.dart' as http;
import '/responses/customer_response.dart';
import '/utils/session_manager.dart';

class ApiService {
  static const String baseUrl = "https://y2ksolutions.com/api/MobileAppApi";

  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    final url = Uri.parse("$baseUrl/login"); // Replace with correct endpoint

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"UserName": username, "Password": password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to login: ${response.body}");
    }
  }

  static Future<CustomerResponse> getAllCustomers() async {
    final orgId = await SessionManager.getOrganizationId();
    final token = await SessionManager.getUserToken();

    if (orgId == null) {
      throw Exception("OrganizationId not found in session");
    }

    final url = Uri.parse("$baseUrl/Users?OrganizationId=$orgId");

    final response = await http.get(
      url
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return CustomerResponse.fromJson(jsonData);
    } else {
      throw Exception("Failed to load customers");
    }
  }
}
