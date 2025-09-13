class WareHouse {
  final int id;
  final String name;
  final String createdAt;
  final String updatedAt;

  WareHouse({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WareHouse.fromJson(Map<String, dynamic> json) {
    return WareHouse(
      id: json['id'],
      name: json['name'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt,
      'updated_at': updatedAt,
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
