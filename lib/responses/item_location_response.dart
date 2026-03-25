import '/Models/item_location_model.dart';

class ItemLocationResponse {
  final List<ItemLocationModel> locations;
  final bool success;

  ItemLocationResponse({required this.locations, required this.success});

  factory ItemLocationResponse.fromJson(Map<String, dynamic> json) {
    return ItemLocationResponse(
      locations: (json['ItemLocation'] as List<dynamic>)
          .map((e) => ItemLocationModel.fromJson(e))
          .toList(),
      success: json['Success'] ?? false,
    );
  }
}
