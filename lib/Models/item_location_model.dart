class ItemLocationModel {
  final int Id;
  final String LocationName;
  final int Status;

  ItemLocationModel({
    required this.Id,
    required this.LocationName,
    required this.Status,
  });

  factory ItemLocationModel.fromJson(Map<String, dynamic> json) {
    return ItemLocationModel(
      Id: json['Id'] ?? 0,
      LocationName: json['LocationName'] ?? '',
      Status: json['Status'] ?? 0,
    );
  }
}
