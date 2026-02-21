class OrderInternetStore {
  final int id;
  final String type;
  final String category;
  final String name;
  final String username;
  final bool isActive;

  const OrderInternetStore({
    required this.id,
    required this.type,
    required this.category,
    required this.name,
    required this.username,
    required this.isActive,
  });

  factory OrderInternetStore.fromJson(Map<String, dynamic> json) {
    return OrderInternetStore(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      type: (json['type'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      isActive: json['is_active'] == true || json['is_active'] == 1,
    );
  }
}
