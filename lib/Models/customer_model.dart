class Customer {
  final int userId;
  final String userName;
  final int accGroup;
  final double openingBalance;
  final int balanceType;
  final String address;
  final String? userAccountName;
  final String stateName;
  final String cityName;
  final String phoneNo;
  final String email;
  final String bankName;
  final String bankAccount;
  final String bankBranchCode;

  Customer({
    required this.userId,
    required this.userName,
    required this.accGroup,
    required this.openingBalance,
    required this.balanceType,
    required this.address,
    this.userAccountName,
    required this.stateName,
    required this.cityName,
    required this.phoneNo,
    required this.email,
    required this.bankName,
    required this.bankAccount,
    required this.bankBranchCode,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      userId: json["UserId"] ?? 0,
      userName: json["UserName"] ?? "",
      accGroup: json["AccGroup"] ?? 0,
      openingBalance: (json["OpeningBalance"] ?? 0).toDouble(),
      balanceType: json["BalanceType"] ?? 0,
      address: json["Address"] ?? "",
      userAccountName: json["UserAccountName"],
      stateName: json["StateName"] ?? "",
      cityName: json["CityName"] ?? "",
      phoneNo: json["PhoneNo"] ?? "",
      email: json["Email"] ?? "",
      bankName: json["BankName"] ?? "",
      bankAccount: json["BankAccount"] ?? "",
      bankBranchCode: json["BankBranchCode"] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "UserId": userId,
      "UserName": userName,
      "AccGroup": accGroup,
      "OpeningBalance": openingBalance,
      "BalanceType": balanceType,
      "Address": address,
      "UserAccountName": userAccountName,
      "StateName": stateName,
      "CityName": cityName,
      "PhoneNo": phoneNo,
      "Email": email,
      "BankName": bankName,
      "BankAccount": bankAccount,
      "BankBranchCode": bankBranchCode,
    };
  }
}
