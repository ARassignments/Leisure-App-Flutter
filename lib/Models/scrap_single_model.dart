class ScrapSingleModel {
  final int Id;
  final int UserAccountId;
  final int LocationId;
  final String UserName;
  final String CustomerAddress;
  final String CustomerPhone;
  final double Quantity;
  final String OrderType;
  final double Price;
  final double TotalAmount;
  final String CreatedAt;
  final String Remarks;
  final String FullName;
  final String Phone;
  final int Items;
  final int OrganizationId;
  final String Address;

  ScrapSingleModel({
    required this.Id,
    required this.UserAccountId,
    required this.LocationId,
    required this.UserName,
    required this.CustomerAddress,
    required this.CustomerPhone,
    required this.Quantity,
    required this.OrderType,
    required this.Price,
    required this.TotalAmount,
    required this.CreatedAt,
    required this.Remarks,
    required this.FullName,
    required this.Phone,
    required this.Items,
    required this.OrganizationId,
    required this.Address,
  });

  factory ScrapSingleModel.fromJson(Map<String, dynamic> json) {
    return ScrapSingleModel(
      Id: json['Id'],
      UserAccountId: json['UserAccountId'],
      LocationId: json['LocationId'],
      UserName: json['UserName'],
      CustomerAddress: json['CustomerAddress'],
      CustomerPhone: json['CustomerPhone'],
      Quantity: (json['Quantity'] as num).toDouble(),
      OrderType: json['OrderType'],
      Price: (json['Price'] as num).toDouble(),
      TotalAmount: (json['TotalAmount'] as num).toDouble(),
      CreatedAt: json['CreatedAt'],
      Remarks: json['Remarks'],
      FullName: json['FullName'],
      Phone: json['Phone'],
      Items: json['Items'],
      OrganizationId: json['OrganizationId'],
      Address: json['Address']
    );
  }
}