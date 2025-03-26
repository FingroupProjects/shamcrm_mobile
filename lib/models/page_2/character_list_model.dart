class CharacteristicListDataResponse {
  final List<CharacteristicItem> result;
  final dynamic errors;

  CharacteristicListDataResponse({
    required this.result,
    this.errors,
  });

  factory CharacteristicListDataResponse.fromJson(Map<String, dynamic> json) {
    return CharacteristicListDataResponse(
      result: (json['result'] as List)
          .map((item) => CharacteristicItem.fromJson(item))
          .toList(),
      errors: json['errors'],
    );
  }
}

class CharacteristicItem {
  final int id;
  final String name;
  final String createdAt;
  final String updatedAt;

  CharacteristicItem({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CharacteristicItem.fromJson(Map<String, dynamic> json) {
    return CharacteristicItem(
      id: json['id'],
      name: json['name'] ?? '', // Обеспечиваем дефолтное значение
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}

class AttributeList {
  final String attribute;

  AttributeList({required this.attribute});

  factory AttributeList.fromJson(Map<String, dynamic> json) {
    return AttributeList(attribute: json['attribute']);
  }
}