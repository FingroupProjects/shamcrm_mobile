class WareHouse {
  final int id;
  final String name;
  final bool showToOnlineStore;
  final String? createdAt;
  final String? updatedAt;
    final List<int>? userIds;


  WareHouse({
    required this.id,
    required this.name,
    required this.showToOnlineStore,
    this.createdAt,
    this.updatedAt,
    this.userIds,
  });

  factory WareHouse.fromJson(Map<String, dynamic> json) {
    return WareHouse(
      id: json['id'],
      name: json['name'],
      showToOnlineStore: json['show_to_online_store'] ?? false,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      userIds: json['user_ids'] != null
          ? List<int>.from(json['user_ids'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'show_to_online_store': showToOnlineStore,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'user_ids': userIds,
    };
  }

  @override
  String toString() {
    return name;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WareHouse && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

