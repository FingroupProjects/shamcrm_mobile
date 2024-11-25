class LeadDeal {
  final int id;
  final String startDate;
  final String name;
  final String? description;
  final String sum;
  final String endDate;
  final dynamic contract; 
  final OrganizationLeadDeals organization;

  LeadDeal({
    required this.id,
    required this.startDate,
    required this.name,
    this.description,
    required this.sum,
    required this.endDate,
    this.contract,
    required this.organization,
  });

  factory LeadDeal.fromJson(Map<String, dynamic> json) {
    return LeadDeal(
      id: json['id'] ?? 0,
      startDate: json['start_date'] ?? '',
      name: json['name'] ?? 'Без имени',
      description: json['description'],
      sum: json['sum'] ?? '0.00',
      endDate: json['end_date'] ?? '',
      contract: json['contract'],
      organization: OrganizationLeadDeals.fromJson(json['organization']),
    );
  }
}

class OrganizationLeadDeals {
  final int id;
  final String name;
  final int? usersCount;
  final String? instagram;
  final String? facebook;
  final String? tgNick;
  final String? whatsapp;

  OrganizationLeadDeals({
    required this.id,
    required this.name,
    this.usersCount,
    this.instagram,
    this.facebook,
    this.tgNick,
    this.whatsapp,
  });

  factory OrganizationLeadDeals.fromJson(Map<String, dynamic> json) {
    return OrganizationLeadDeals(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Без имени',
      usersCount: json['usersCount'],
      instagram: json['instagram'],
      facebook: json['facebook'],
      tgNick: json['tg_nick'],
      whatsapp: json['whatsapp'],
    );
  }
}