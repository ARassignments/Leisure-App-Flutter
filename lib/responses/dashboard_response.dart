import '/Models/dashboard_model.dart';

class DashboardResponse {
  final DashboardModel dashboard;
  final bool success;

  DashboardResponse({
    required this.dashboard,
    required this.success,
  });

  factory DashboardResponse.fromJson(Map<String, dynamic> json) {
    return DashboardResponse(
      dashboard: DashboardModel.fromJson(json),
      success: json["Success"] ?? false,
    );
  }
}