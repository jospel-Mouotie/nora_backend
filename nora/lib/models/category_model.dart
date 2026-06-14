class Category {
  final int id;
  final String name;
  final String? description;
  final String? icon;
  final int? parentId;
  final String? parentName;
  final int sortOrder;
  final bool isActive;
  final List<Category> children;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.parentId,
    this.parentName,
    required this.sortOrder,
    required this.isActive,
    required this.children,
    this.createdAt,
    this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    List<Category> children = [];
    if (json['children'] is List) {
      children = (json['children'] as List)
          .map((c) => Category.fromJson(c as Map<String, dynamic>))
          .toList();
    }

    return Category(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      icon: json['icon'],
      parentId: json['parent_id'],
      parentName: json['parent_name'],
      sortOrder: json['sort_order'] ?? 0,
      isActive: json['is_active'] ?? true,
      children: children,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'parent_id': parentId,
      'parent_name': parentName,
      'sort_order': sortOrder,
      'is_active': isActive,
      'children': children.map((c) => c.toJson()).toList(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  bool get hasChildren => children.isNotEmpty;
  
  bool get isSubcategory => parentId != null;
}
