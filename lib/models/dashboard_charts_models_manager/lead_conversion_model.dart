class LeadConversionManager {
  final List<double> monthlyData;

  LeadConversionManager({
    required this.monthlyData,
  });

  factory LeadConversionManager.fromJson(Map<String, dynamic> json) {
    final result = json['result'] as List<dynamic>;
    return LeadConversionManager(
      monthlyData: result.map((value) => (value as num).toDouble()).toList(),
    );
  }
}