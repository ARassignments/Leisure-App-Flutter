import '/Models/scrap_single_model.dart';

class ScrapResponseById {
  final ScrapSingleModel scrap;
  final bool success;

  ScrapResponseById({required this.scrap, required this.success});

  factory ScrapResponseById.fromJson(Map<String, dynamic> json) {
    return ScrapResponseById(
      scrap: ScrapSingleModel.fromJson(json),
      success: json['Success'],
    );
  }
}
