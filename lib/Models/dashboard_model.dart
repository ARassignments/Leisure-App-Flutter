class DashboardModel {
  final List<dynamic> DailyOrders;
  final List<dynamic> DailyRevenue;
  final List<dynamic> DailyCreditProfit;
  final List<dynamic> DailyDebitProfit;
  final List<dynamic> MonthlyScap;
  final List<dynamic> CreditSale;
  final List<dynamic> DebitSale;
  final List<dynamic> PaymentDetails;
  final List<dynamic> TopCustomer;
  final List<dynamic> DeadStock;
  final List<dynamic> TopProducts;
  final List<dynamic> EndingStock;

  DashboardModel({
    required this.DailyOrders,
    required this.DailyRevenue,
    required this.DailyCreditProfit,
    required this.DailyDebitProfit,
    required this.MonthlyScap,
    required this.CreditSale,
    required this.DebitSale,
    required this.PaymentDetails,
    required this.TopCustomer,
    required this.DeadStock,
    required this.TopProducts,
    required this.EndingStock,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      DailyOrders: List<dynamic>.from(json["DailyOrders"] ?? []),
      DailyRevenue: List<dynamic>.from(json["DailyRevenue"] ?? []),
      DailyCreditProfit: List<dynamic>.from(json["DailyCreditProfit"] ?? []),
      DailyDebitProfit: List<dynamic>.from(json["DailyDebitProfit"] ?? []),
      MonthlyScap: List<dynamic>.from(json["MonthlyScap"] ?? []),
      CreditSale: List<dynamic>.from(json["CreditSale"] ?? []),
      DebitSale: List<dynamic>.from(json["DebitSale"] ?? []),
      PaymentDetails: List<dynamic>.from(json["PaymentDetails"] ?? []),
      TopCustomer: List<dynamic>.from(json["TopCustomer"] ?? []),
      DeadStock: List<dynamic>.from(json["DeadStock"] ?? []),
      TopProducts: List<dynamic>.from(json["TopProducts"] ?? []),
      EndingStock: List<dynamic>.from(json["EndingStock"] ?? []),
    );
  }
}