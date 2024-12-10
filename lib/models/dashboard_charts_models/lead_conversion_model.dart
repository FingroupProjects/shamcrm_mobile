class LeadConversion {
  final double newLeads;
  final double repeatedLeads;

  LeadConversion({
    required this.newLeads,
    required this.repeatedLeads,
  });

  factory LeadConversion.fromJson(Map<String, dynamic> json) {
    final result = json['result'] as Map<String, dynamic>? ?? {};
    return LeadConversion(
      newLeads: (result['new'] as num?)?.toDouble() ?? 0.0,
      repeatedLeads: (result['repeated'] as num?)?.toDouble() ?? 0.0,
    );
  }

  List<double> get data => [newLeads, repeatedLeads];
}
