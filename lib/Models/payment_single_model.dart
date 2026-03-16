class PaymentSingleModel {
  final int Id;
  final int UserId;
  final String UserName;
  final String CustomerAddress;
  final String CustomerPhone;
  final double Payment;
  final String PaymentDate;
  final String PaymentType;
  final String PaymentMode;
  final String Remarks;
  final String FullName;
  final String Phone;
  final String Address;
  final String LastBalance;

  PaymentSingleModel({
    required this.Id,
    required this.UserId,
    required this.UserName,
    required this.CustomerAddress,
    required this.CustomerPhone,
    required this.Payment,
    required this.PaymentDate,
    required this.PaymentType,
    required this.PaymentMode,
    required this.Remarks,
    required this.FullName,
    required this.Phone,
    required this.Address,
    required this.LastBalance,
  });

  factory PaymentSingleModel.fromJson(Map<String, dynamic> json) {
    return PaymentSingleModel(
      Id: json['Id'],
      UserId: json['UserId'],
      UserName: json['UserName'],
      CustomerAddress: json['CustomerAddress'],
      CustomerPhone: json['CustomerPhone'],
      Payment: (json['Payment'] as num).toDouble(),
      PaymentDate: json['PaymentDate'],
      PaymentType: json['PaymentType'],
      PaymentMode: json['PaymentMode'],
      Remarks: json['Remarks'],
      FullName: json['FullName'],
      Phone: json['Phone'],
      Address: json['Address'],
      LastBalance: json['LastBalance']
    );
  }
}