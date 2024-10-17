class Lead {
  final int id;
  final String name;
  final Source? source; // Предположим, что source - это объект Source
  final int messageAmount;
  final String? createdAt;
  final int statusId;

  Lead({
    required this.id,
    required this.name,
    this.source,
    required this.messageAmount,
    this.createdAt,
    required this.statusId,
  });

  factory Lead.fromJson(Map<String, dynamic> json) {
    return Lead(
      id: json['id'] ?? 0, // Предоставить значение по умолчанию
      name: json['name'] ?? 'Без имени', // Предоставить значение по умолчанию
      source: json['source'] != null ? Source.fromJson(json['source']) : null,
      messageAmount: json['message_amount'] ?? 0,
      createdAt: json['created_at'],
      statusId: json['leadStatus']?['id'] ?? 0, // Проверка на null
    );
  }
}

class Source {
  final String name;

  Source({required this.name});

  factory Source.fromJson(Map<String, dynamic> json) {
    return Source(
      name: json['name'],
    );
  }
}

class LeadStatus {
  final int id;
  final String title;
  final int leadsCount;

  LeadStatus({
    required this.id,
    required this.title,
    required this.leadsCount,
  });

  factory LeadStatus.fromJson(Map<String, dynamic> json) {
    return LeadStatus(
      id: json['id'],
      title: json['title'],
      leadsCount: json['leads_count'],
    );
  }
}
