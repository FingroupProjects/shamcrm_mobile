class GoodDashboardWarehouse {
  final int id;
  final String name;
  final Category category;
  final List<FileData> files;
  final GoodLabel? label;
  final bool isActive;
  final dynamic price; // Can be int, double, or null
  final List<dynamic> discount;
  final bool isNew;
  final bool isSale;
  final bool isPopular;
  final int isService;
  final String? article;

  GoodDashboardWarehouse({
    required this.id,
    required this.name,
    required this.category,
    required this.files,
    this.label,
    required this.isActive,
    this.price,
    required this.discount,
    required this.isNew,
    required this.isSale,
    required this.isPopular,
    required this.isService,
    this.article,
  });

  factory GoodDashboardWarehouse.fromJson(Map<String, dynamic> json) {
    return GoodDashboardWarehouse(
      id: json['id'] as int,
      name: json['name'] as String,
      category: Category.fromJson(json['category'] as Map<String, dynamic>),
      files: (json['files'] as List?)
          ?.map((file) => FileData.fromJson(file as Map<String, dynamic>))
          .toList() ??
          [],
      label: json['label'] != null
          ? GoodLabel.fromJson(json['label'] as Map<String, dynamic>)
          : null,
      isActive: json['is_active'] as bool,
      price: json['price'], // Can be null, int, or double
      discount: json['discount'] as List? ?? [],
      isNew: json['is_new'] as bool,
      isSale: json['is_sale'] as bool,
      isPopular: json['is_popular'] as bool,
      isService: json['is_service'] as int,
      article: json['article'] as String?,
    );
  }

  // Helper method to get formatted price
  String getFormattedPrice() {
    if (price == null) return '0';
    if (price is int) return price.toString();
    if (price is double) return price.toStringAsFixed(2);
    return price.toString();
  }
}

class Category {
  final int id;
  final String name;
  final String? image;
  final String displayType;
  final int isParent;
  final bool hasPriceCharacteristics;
  final ParentCategory? parent;
  final List<CategoryAttribute> attributes;

  Category({
    required this.id,
    required this.name,
    this.image,
    required this.displayType,
    required this.isParent,
    required this.hasPriceCharacteristics,
    this.parent,
    required this.attributes,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      name: json['name'] as String,
      image: json['image'] as String?,
      displayType: json['display_type'] as String,
      isParent: json['is_parent'] as int,
      hasPriceCharacteristics: json['has_price_characteristics'] as bool,
      parent: json['parent'] != null
          ? ParentCategory.fromJson(json['parent'] as Map<String, dynamic>)
          : null,
      attributes: (json['attributes'] as List?)
          ?.map((attr) =>
          CategoryAttribute.fromJson(attr as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }
}

class ParentCategory {
  final int id;
  final String name;
  final String? image;
  final int isParent;
  final List<dynamic> attributes;
  final bool hasPriceCharacteristics;

  ParentCategory({
    required this.id,
    required this.name,
    this.image,
    required this.isParent,
    required this.attributes,
    required this.hasPriceCharacteristics,
  });

  factory ParentCategory.fromJson(Map<String, dynamic> json) {
    return ParentCategory(
      id: json['id'] as int,
      name: json['name'] as String,
      image: json['image'] as String?,
      isParent: json['is_parent'] as int,
      attributes: json['attributes'] as List? ?? [],
      hasPriceCharacteristics: json['has_price_characteristics'] as bool,
    );
  }
}

class CategoryAttribute {
  final int id;
  final Attribute attribute;
  final bool isIndividual;
  final bool showToSite;

  CategoryAttribute({
    required this.id,
    required this.attribute,
    required this.isIndividual,
    required this.showToSite,
  });

  factory CategoryAttribute.fromJson(Map<String, dynamic> json) {
    return CategoryAttribute(
      id: json['id'] as int,
      attribute: Attribute.fromJson(json['attribute'] as Map<String, dynamic>),
      isIndividual: json['is_individual'] as bool,
      showToSite: json['show_to_site'] as bool,
    );
  }
}

class Attribute {
  final int id;
  final String name;

  Attribute({
    required this.id,
    required this.name,
  });

  factory Attribute.fromJson(Map<String, dynamic> json) {
    return Attribute(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

class FileData {
  final int id;
  final String name;
  final String path;
  final String externalUrl;
  final bool isMain;

  FileData({
    required this.id,
    required this.name,
    required this.path,
    required this.externalUrl,
    required this.isMain,
  });

  factory FileData.fromJson(Map<String, dynamic> json) {
    return FileData(
      id: json['id'] as int,
      name: json['name'] as String,
      path: json['path'] as String,
      externalUrl: json['external_url'] as String,
      isMain: json['is_main'] as bool,
    );
  }
}

class GoodLabel {
  final int id;
  final String name;
  final String color;
  final int showOnMain;
  final String createdAt;
  final String updatedAt;

  GoodLabel({
    required this.id,
    required this.name,
    required this.color,
    required this.showOnMain,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GoodLabel.fromJson(Map<String, dynamic> json) {
    return GoodLabel(
      id: json['id'] as int,
      name: json['name'] as String,
      color: json['color'] as String,
      showOnMain: json['show_on_main'] as int,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }
}

class Pagination {
  final int total;
  final int count;
  final int perPage;
  final int currentPage;
  final int totalPages;

  Pagination({
    required this.total,
    required this.count,
    required this.perPage,
    required this.currentPage,
    required this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      total: json['total'] as int,
      count: json['count'] as int,
      perPage: json['per_page'] as int,
      currentPage: json['current_page'] as int,
      totalPages: json['total_pages'] as int,
    );
  }
}