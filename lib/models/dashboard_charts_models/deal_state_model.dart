class DealStatsResponse {
  final String month;
  final int count;

  DealStatsResponse({
    required this.month,
    required this.count,
  });

  factory DealStatsResponse.fromJson(Map<String, dynamic> json) {
    return DealStatsResponse(
      month: json['month'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

