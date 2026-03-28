import 'dart:convert';
import 'outcome_category_data.dart';

OutcomeCategoriesDataResponse incomeCategoriesDataResponseFromJson(String str) =>
    OutcomeCategoriesDataResponse.fromJson(json.decode(str));

String incomeCategoriesDataResponseToJson(OutcomeCategoriesDataResponse data) =>
    json.encode(data.toJson());

class OutcomeCategoriesDataResponse {
  List<OutcomeCategoryData>? result;
  dynamic errors;

  OutcomeCategoriesDataResponse({
    this.result,
    this.errors,
  });

  factory OutcomeCategoriesDataResponse.fromJson(Map<String, dynamic> json) {
    return OutcomeCategoriesDataResponse(
      result: json["result"] != null && json["result"]["data"] != null
          ? List<OutcomeCategoryData>.from(
              (json["result"]["data"] as List).map((x) => OutcomeCategoryData.fromJson(x)))
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
