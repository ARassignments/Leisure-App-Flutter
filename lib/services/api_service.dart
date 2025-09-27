import 'dart:convert';
import 'package:http/http.dart' as http;
import '/responses/order_detail_response.dart';
import '/responses/order_response.dart';
import '/responses/customer_response.dart';
import '/utils/session_manager.dart';

class ApiService {
  static const String baseUrl = "https://y2ksolutions.com/api/MobileAppApi";

  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    final url = Uri.parse("$baseUrl/login");

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

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return CustomerResponse.fromJson(jsonData);
    } else {
      throw Exception("Failed to load customers");
    }
  }

  static Future<OrdersResponse> getAllOrders({
    required String fromDate,
    required String toDate,
  }) async {
    final orgId = await SessionManager.getOrganizationId();
    if (orgId == null) {
      throw Exception("OrganizationId not found in session");
    }

    final url = Uri.parse(
      "$baseUrl/AllOrders?OrganizationId=$orgId&FromDate=$fromDate&ToDate=$toDate",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return OrdersResponse.fromJson(jsonData);
    } else {
      throw Exception("Failed to fetch orders: ${response.body}");
    }
  }

  static Future<OrderDetailResponse> getOrderDetail(int id) async {
    final url = Uri.parse("$baseUrl/OrderDetail?Id=$id");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return OrderDetailResponse.fromJson(jsonData);
    } else {
      throw Exception("Failed to fetch order detail: ${response.body}");
    }
  }
}
