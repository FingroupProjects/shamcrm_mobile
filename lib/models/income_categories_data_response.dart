import 'dart:convert';
import 'income_category_data.dart';

IncomeCategoriesDataResponse incomeCategoriesDataResponseFromJson(String str) =>
    IncomeCategoriesDataResponse.fromJson(json.decode(str));

String incomeCategoriesDataResponseToJson(IncomeCategoriesDataResponse data) =>
    json.encode(data.toJson());

class IncomeCategoriesDataResponse {
  List<IncomeCategoryData>? result;
  dynamic errors;

  IncomeCategoriesDataResponse({
    this.result,
    this.errors,
  });

  factory IncomeCategoriesDataResponse.fromJson(Map<String, dynamic> json) {
    return IncomeCategoriesDataResponse(
      result: json["result"] != null && json["result"]["data"] != null
          ? List<IncomeCategoryData>.from(
              (json["result"]["data"] as List).map((x) => IncomeCategoryData.fromJson(x)))
          : [],
      errors: json["errors"],
    );
  }

  Map<String, dynamic> toJson() => {
        "result": result == null
            ? []
            : List<dynamic>.from(result!.map((x) => x.toJson())),
        "errors": errors,
      };
}
