class EmailVerificationResponse {
  final String domain;
  final String login;

  EmailVerificationResponse({
    required this.domain,
    required this.login,
  });

  factory EmailVerificationResponse.fromJson(Map<String, dynamic> json) {
    return EmailVerificationResponse(
      domain: json['domain'] ?? '',
      login: json['login'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'domain': domain,
      'login': login,
    };
  }
}