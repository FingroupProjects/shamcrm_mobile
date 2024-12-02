class ForgotPinResponse {
  final int? result;
  final String? errors;

  ForgotPinResponse({this.result, this.errors});

  factory ForgotPinResponse.fromJson(Map<String, dynamic> json) {
    return ForgotPinResponse(
      result: json['result'] as int?,
      errors: json['errors'] as String?,
    );
  }
}
