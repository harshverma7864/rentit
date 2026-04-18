import 'user_model.dart';
import '../services/api_service.dart';

/// Describes one spec field for a category (from GET /api/items/categories).
class SpecField {
  final String key;
  final String label;
  final String type; // select, text, number, boolean
  final List<String> options;
  final bool filterable;

  SpecField({required this.key, required this.label, required this.type, this.options = const [], this.filterable = false});

  factory SpecField.fromJson(Map<String, dynamic> json) => SpecField(
    key: json['key'] ?? '',
    label: json['label'] ?? '',
    type: json['type'] ?? 'text',
    options: (json['options'] as List?)?.map<String>((e) => e.toString()).toList() ?? [],
    filterable: json['filterable'] ?? false,
  );
}

/// A subcategory within a parent category.
class SubcategoryInfo {
  final String id;
  final String name;
  SubcategoryInfo({required this.id, required this.name});
  factory SubcategoryInfo.fromJson(Map<String, dynamic> json) => SubcategoryInfo(id: json['id'] ?? '', name: json['name'] ?? '');
}

/// Full category schema returned by the backend.
class CategorySpec {
  final String id;
  final String name;
  final String icon;
  final List<SubcategoryInfo> subcategories;
  final List<SpecField> fields;

  CategorySpec({required this.id, required this.name, required this.icon, this.subcategories = const [], this.fields = const []});

  factory CategorySpec.fromJson(Map<String, dynamic> json) => CategorySpec(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    icon: json['icon'] ?? '📦',
    subcategories: (json['subcategories'] as List?)?.map<SubcategoryInfo>((e) => SubcategoryInfo.fromJson(e)).toList() ?? [],
    fields: (json['fields'] as List?)?.map<SpecField>((e) => SpecField.fromJson(e)).toList() ?? [],
  );

  List<SpecField> get filterableFields => fields.where((f) => f.filterable).toList();
}

class ItemModel {
  final String id;
  final String ownerId;
  final UserModel? owner;
  final String title;
  final String description;
  final String category;
  final List<String> images;
  final double pricePerHour;
  final double pricePerDay;
  final double pricePerWeek;
  final double price;
  final double securityDeposit;
  final String condition;
  final LocationModel? location;
  final bool isAvailable;
  final int quantity;
  final List<String> tags;
  final String rules;
  final int maxRentalDays;
  final bool deliveryAvailable;
  final double deliveryFee;
  final List<String> deliveryOptions;
  final bool isBoosted;
  final DateTime? boostExpiresAt;
  final DateTime? createdAt;
  // Category-specific attributes (JSONB from backend)
  final Map<String, dynamic> specs;

  ItemModel({
    required this.id,
    this.ownerId = '',
    this.owner,
    required this.title,
    required this.description,
    required this.category,
    this.images = const [],
    this.pricePerHour = 0,
    required this.pricePerDay,
    this.pricePerWeek = 0,
    this.price = 0,
    required this.securityDeposit,
    this.condition = 'good',
    this.location,
    this.isAvailable = true,
    this.quantity = 1,
    this.tags = const [],
    this.rules = '',
    this.maxRentalDays = 30,
    this.deliveryAvailable = false,
    this.deliveryFee = 0,
    this.deliveryOptions = const [],
    this.isBoosted = false,
    this.boostExpiresAt,
    this.createdAt,
    this.specs = const {},
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id'] ?? json['_id'] ?? '',
      ownerId: json['owner'] is String ? json['owner'] : '',
      owner: json['owner'] is Map<String, dynamic>
          ? UserModel.fromJson(json['owner'])
          : null,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'other',
      images:
          (json['images'] as List?)?.map<String>((e) => e.toString()).toList() ??
              [],
      pricePerHour: (json['pricePerHour'] ?? 0).toDouble(),
      pricePerDay: (json['pricePerDay'] ?? 0).toDouble(),
      pricePerWeek: (json['pricePerWeek'] ?? 0).toDouble(),
      price: (json['price'] ?? 0).toDouble(),
      securityDeposit: (json['securityDeposit'] ?? 0).toDouble(),
      condition: json['condition'] ?? 'good',
      location: json['location'] != null
          ? LocationModel.fromJson(json['location'])
          : null,
      isAvailable: json['isAvailable'] ?? true,
      quantity: json['quantity'] ?? 1,
      tags: (json['tags'] as List?)?.map<String>((e) => e.toString()).toList() ??
          [],
      rules: json['rules'] ?? '',
      maxRentalDays: json['maxRentalDays'] ?? 30,
      deliveryAvailable: json['deliveryAvailable'] ?? false,
      deliveryFee: (json['deliveryFee'] ?? 0).toDouble(),
      deliveryOptions: (json['deliveryOptions'] as List?)
              ?.map<String>((e) => e.toString())
              .toList() ??
          [],
      isBoosted: json['isBoosted'] ?? false,
      boostExpiresAt: json['boostExpiresAt'] != null
          ? DateTime.tryParse(json['boostExpiresAt'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      specs: json['specs'] is Map<String, dynamic> ? json['specs'] : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'images': images,
      'pricePerHour': pricePerHour,
      'pricePerDay': pricePerDay,
      'pricePerWeek': pricePerWeek,
      'price': price,
      'securityDeposit': securityDeposit,
      'condition': condition,
      'isAvailable': isAvailable,
      'quantity': quantity,
      'tags': tags,
      'rules': rules,
      'maxRentalDays': maxRentalDays,
      'deliveryAvailable': deliveryAvailable,
      'deliveryFee': deliveryFee,
      'deliveryOptions': deliveryOptions,
    };
  }

  /// Build full image URLs: baseUrl/items/{id}/{filename}
  List<String> get imageUrls =>
      images.map((name) => '${ApiService.imageBaseUrl}/items/$id/$name').toList();

  bool get hasInAppDelivery => deliveryOptions.contains('in_app_delivery');
  bool get hasSellerDelivery => deliveryOptions.contains('seller_delivery');
  bool get hasSelfPickup => deliveryOptions.contains('self_pickup') || deliveryOptions.isEmpty;

  String get conditionLabel {
    switch (condition) {
      case 'new':
        return 'Brand New';
      case 'like_new':
        return 'Like New';
      case 'good':
        return 'Good';
      case 'fair':
        return 'Fair';
      default:
        return condition;
    }
  }

  String get categoryIcon {
    switch (category) {
      // Main categories
      case 'electronics':
        return '📱';
      case 'vehicles':
        return '🚗';
      case 'furniture':
        return '🪑';
      case 'clothing':
        return '👗';
      case 'sports':
        return '⚽';
      case 'tools':
        return '🔧';
      case 'books':
        return '📚';
      case 'party':
        return '🎉';
      case 'cameras':
        return '📷';
      // Clothing subcategories
      case 'lehenga':
      case 'saree':
      case 'gown':
      case 'dress':
      case 'kurta':
        return '👗';
      case 'sherwani':
        return '🤵';
      case 'suit':
        return '👔';
      case 'bridal':
        return '💍';
      case 'indo_western':
        return '✨';
      case 'accessories':
        return '👜';
      default:
        return '📦';
    }
  }
}
