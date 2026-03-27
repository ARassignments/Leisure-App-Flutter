import 'dart:convert';
import 'package:http/http.dart' as http;
import '/responses/item_location_response.dart';
import '/responses/scrap_response_by_id.dart';
import '/responses/payment_response_by_id.dart';
import '/responses/dashboard_response.dart';
import '/Models/customer_single_model.dart';
import '/responses/scrap_response.dart';
import '/responses/ledger_response.dart';
import '/responses/payment_response.dart';
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

  static Future<LedgerResponse> getAllLedgers({
    required String fromDate,
    required String toDate,
    required int userId,
  }) async {
    final orgId = await SessionManager.getOrganizationId();
    if (orgId == null) {
      throw Exception("OrganizationId not found in session");
    }

    final url = Uri.parse(
      "$baseUrl/Ledger?OrganizationId=$orgId&UserId=$userId&FromDate=$fromDate&ToDate=$toDate",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return LedgerResponse.fromJson(jsonData);
    } else {
      throw Exception("Failed to fetch ledgers: ${response.body}");
    }
  }

  static Future<PaymentsResponse> getAllPayments({
    required String fromDate,
    required String toDate,
  }) async {
    final orgId = await SessionManager.getOrganizationId();
    if (orgId == null) {
      throw Exception("OrganizationId not found in session");
    }

    final url = Uri.parse(
      "$baseUrl/AllPayments?OrganizationId=$orgId&FromDate=$fromDate&ToDate=$toDate",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return PaymentsResponse.fromJson(jsonData);
    } else {
      throw Exception("Failed to fetch payments: ${response.body}");
    }
  }

  static Future<ScrapsResponse> getAllScraps({
    required String fromDate,
    required String toDate,
  }) async {
    final orgId = await SessionManager.getOrganizationId();
    if (orgId == null) {
      throw Exception("OrganizationId not found in session");
    }

    final url = Uri.parse(
      "$baseUrl/AllScraps?OrganizationId=$orgId&FromDate=$fromDate&ToDate=$toDate",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return ScrapsResponse.fromJson(jsonData);
    } else {
      throw Exception("Failed to fetch scraps: ${response.body}");
    }
  }

  static Future<CustomerSingleModel?> getSingleCustomer(int id) async {
    final url = Uri.parse('$baseUrl/GetSingleCustomer?Id=$id');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['Success'] == true) {
        return CustomerSingleModel.fromJson(jsonData);
      } else {
        return null;
      }
    } else {
      throw Exception('Failed to fetch customer');
    }
  }

  static Future<DashboardResponse> getDashboardReport({
    required String fromDate,
    required String toDate,
    required String fromMonth,
    required String toMonth,
  }) async {
    final orgId = await SessionManager.getOrganizationId();

    if (orgId == null) {
      throw Exception("OrganizationId not found in session");
    }

    final url = Uri.parse(
      "$baseUrl/GetDashboardReport"
      "?OrganizationId=$orgId"
      "&FromDate=$fromDate"
      "&ToDate=$toDate"
      "&FromMonth=$fromMonth"
      "&ToMonth=$toMonth",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return DashboardResponse.fromJson(jsonData);
    } else {
      throw Exception("Failed to fetch dashboard data: ${response.body}");
    }
  }

  static Future<Map<dynamic, dynamic>> addPayment(
    int userId,
    String paymentType,
    String paymentMode,
    String paymentDate,
    int paymentAmount,
    String paymentRemarks,
  ) async {
    final url = Uri.parse("$baseUrl/AddPayment");
    final orgId = await SessionManager.getOrganizationId();

    if (orgId == null) {
      throw Exception("OrganizationId not found in session");
    }

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "Id": 0,
        "OrganizationId": orgId,
        "UserId": userId,
        "PaymentType": paymentType,
        "PaymentMode": paymentMode,
        "PaymentDate": paymentDate,
        "Payment": paymentAmount,
        "Remarks": paymentRemarks,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to add payment: ${response.body}");
    }
  }

  static Future<Map<dynamic, dynamic>> editPayment(
    int paymentId,
    int userId,
    String paymentType,
    String paymentMode,
    String paymentDate,
    int paymentAmount,
    String paymentRemarks,
  ) async {
    final url = Uri.parse("$baseUrl/AddPayment");
    final orgId = await SessionManager.getOrganizationId();

    if (orgId == null) {
      throw Exception("OrganizationId not found in session");
    }

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "Id": paymentId,
        "OrganizationId": orgId,
        "UserId": userId,
        "PaymentType": paymentType,
        "PaymentMode": paymentMode,
        "PaymentDate": paymentDate,
        "Payment": paymentAmount,
        "Remarks": paymentRemarks,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to edit payment: ${response.body}");
    }
  }

  static Future<PaymentResponseById> getPaymentById({required int id}) async {
    final orgId = await SessionManager.getOrganizationId();

    if (orgId == null) {
      throw Exception("OrganizationId not found in session");
    }

    final url = Uri.parse(
      "$baseUrl/GetPaymentById"
      "?Id=$id"
      "&OrganizationId=$orgId"
      "&CurrentUserName",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return PaymentResponseById.fromJson(jsonData);
    } else {
      throw Exception("Failed to fetch payment data: ${response.body}");
    }
  }

  static Future<Map<dynamic, dynamic>> deletePaymentById(int paymentId) async {
    final url = Uri.parse("$baseUrl/DeletePaymentById");
    final userPassword = await SessionManager.getUserPassword();

    if (userPassword == null) {
      throw Exception("UserPassword not found in session");
    }

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"Id": paymentId, "Password": "1"}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to delete payment: ${response.body}");
    }
  }

  static Future<Map<dynamic, dynamic>> addScrap(
    int userId,
    int scrapQuantity,
    double scrapWeight,
    int scrapPrice,
    int scrapItemLocation,
    String scrapDate,
    String scrapOrderType,
    String scrapRemarks,
  ) async {
    final url = Uri.parse("$baseUrl/AddScrap");
    final orgId = await SessionManager.getOrganizationId();

    if (orgId == null) {
      throw Exception("OrganizationId not found in session");
    }

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "Id": 0,
        "UserId": userId,
        "Items": scrapQuantity,
        "LocationId": scrapItemLocation,
        "Quantity": scrapWeight,
        "Price": scrapPrice,
        "Date": scrapDate,
        "OrderType": scrapOrderType,
        "Remarks": scrapRemarks,
        "OrganizationId": orgId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to add scrap: ${response.body}");
    }
  }

  static Future<Map<dynamic, dynamic>> editScrap(
    int scrapId,
    int userId,
    int scrapQuantity,
    double scrapWeight,
    int scrapPrice,
    int scrapItemLocation,
    String scrapDate,
    String scrapOrderType,
    String scrapRemarks,
  ) async {
    final url = Uri.parse("$baseUrl/AddScrap");
    final orgId = await SessionManager.getOrganizationId();

    if (orgId == null) {
      throw Exception("OrganizationId not found in session");
    }

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "Id": scrapId,
        "UserId": userId,
        "Items": scrapQuantity,
        "LocationId": scrapItemLocation,
        "Quantity": scrapWeight,
        "Price": scrapPrice,
        "Date": scrapDate,
        "OrderType": scrapOrderType,
        "Remarks": scrapRemarks,
        "OrganizationId": orgId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to edit scrap: ${response.body}");
    }
  }

  static Future<ScrapResponseById> getScrapById({required int id}) async {
    final url = Uri.parse(
      "$baseUrl/GetScrapById"
      "?Id=$id",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return ScrapResponseById.fromJson(jsonData);
    } else {
      throw Exception("Failed to fetch scrap data: ${response.body}");
    }
  }

  static Future<Map<dynamic, dynamic>> deleteScrapById(int scrapId) async {
    final url = Uri.parse("$baseUrl/DeleteScrapById");
    final userPassword = await SessionManager.getUserPassword();

    if (userPassword == null) {
      throw Exception("UserPassword not found in session");
    }

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"Id": scrapId, "Password": "1"}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to delete scrap: ${response.body}");
    }
  }

  static Future<ItemLocationResponse> getAllItemLocations() async {
    final orgId = await SessionManager.getOrganizationId();

    if (orgId == null) {
      throw Exception("OrganizationId not found in session");
    }

    final url = Uri.parse("$baseUrl/AllLocations?OrganizationId=$orgId");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return ItemLocationResponse.fromJson(jsonData);
    } else {
      throw Exception("Failed to load item locations");
    }
  }
}
