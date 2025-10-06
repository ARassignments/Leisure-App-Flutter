class PaymentModel {
  final int Id;
  final int UserId;
  final String UserName;
  final int Payment;
  final DateTime PaymentDate;
  final String PaymentType;
  final String PaymentMode;
  final String Remarks;

  PaymentModel({
    required this.Id,
    required this.UserId,
    required this.UserName,
    required this.Payment,
    required this.PaymentDate,
    required this.PaymentType,
    required this.PaymentMode,
    required this.Remarks
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      Id: json['Id'],
      UserId: json['UserId'],
      UserName: json['UserName'],
      Payment: json['Payment'],
      PaymentDate: DateTime.parse(json['PaymentDate']),
      PaymentType: json['PaymentType'],
      PaymentMode: json['PaymentMode'],
      Remarks: json['Remarks'],
    );
  }
}
