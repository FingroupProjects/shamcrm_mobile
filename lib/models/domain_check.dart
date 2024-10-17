class DomainCheck {
  final bool result;
  final String? errors;

  DomainCheck({required this.result, this.errors});

  factory DomainCheck.fromJson(Map<String, dynamic> json) {
    return DomainCheck(
      result: json['result'],
      errors: json['errors'],
    );
  }
}
