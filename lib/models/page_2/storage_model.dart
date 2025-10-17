class WareHouse {
  final int id;
  final String name;
  final bool? showOnSite;
  final String? createdAt;
  final String? updatedAt;
  final List<int>? userIds;

  WareHouse({
    required this.id,
    required this.name,
    this.showOnSite,
    this.createdAt,
    this.updatedAt,
    this.userIds,
  });

  factory WareHouse.fromJson(Map<String, dynamic> json) {
    List<int>? userIds;
    if (json['users'] != null) {
      final usersList = json['users'] as List<dynamic>?;
      if (usersList != null && usersList.isNotEmpty) {
        userIds = usersList.map((user) => user['user_id'] as int).toList();
      }
    }

    return WareHouse(
      id: json['id'] as int,
      name: json['name'] as String,
      showOnSite: (json['show_on_site'] as int?) == 1,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      userIds: userIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'show_on_site': showOnSite,
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