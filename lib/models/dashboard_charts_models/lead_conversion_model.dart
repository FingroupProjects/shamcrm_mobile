class LeadConversion {
  final List<double> monthlyData;

  LeadConversion({
    required this.monthlyData,
  });

  factory LeadConversion.fromJson(Map<String, dynamic> json) {
    final result = json['result'] as List<dynamic>;
    return LeadConversion(
      monthlyData: result.map((value) => (value as num).toDouble()).toList(),
    );
  }
}