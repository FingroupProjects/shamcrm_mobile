class Storage {
  final int id;
  final String name;
  final String createdAt;
  final String updatedAt;

  Storage({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Storage.fromJson(Map<String, dynamic> json) {
    return Storage(
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
    return other is Storage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}