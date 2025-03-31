class CharacteristicListDataResponse {
  final List<CharacteristicItem>? result; 
  final dynamic errors;

  CharacteristicListDataResponse({
    this.result, 
    this.errors,
  });

  factory CharacteristicListDataResponse.fromJson(Map<String, dynamic> json) {
    return CharacteristicListDataResponse(
      result: json['result'] != null 
          ? (json['result'] as List)
              .map((item) => CharacteristicItem.fromJson(item))
              .toList()
          : null,
      errors: json['errors'],
    );
  }
}

class CharacteristicItem {
  final int id;
  final String name;
  final String? createdAt;  
  final String? updatedAt;  

  CharacteristicItem({
    required this.id,
    required this.name,
    this.createdAt,  
    this.updatedAt,  
  });

  factory CharacteristicItem.fromJson(Map<String, dynamic> json) {
    return CharacteristicItem(
      id: json['id'] ?? 0,  
      name: json['name']?.toString() ?? '',  
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
}

class AttributeList {
  final String attribute;

  AttributeList({required this.attribute});

  factory AttributeList.fromJson(Map<String, dynamic> json) {
    return AttributeList(
      attribute: json['attribute']?.toString() ?? '',  
    );
  }
}