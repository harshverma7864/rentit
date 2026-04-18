import '../services/api_service.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String avatar;
  final LocationModel? location;
  final List<AddressModel> addresses;
  final double rating;
  final int totalRatings;
  final bool isSeller;
  final bool isVerified;
  final bool contactLocked;
  final int itemCount;
  final int completedBookings;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.avatar = '',
    this.location,
    this.addresses = const [],
    this.rating = 0,
    this.totalRatings = 0,
    this.isSeller = false,
    this.isVerified = false,
    this.contactLocked = false,
    this.itemCount = 0,
    this.completedBookings = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      avatar: json['avatar'] ?? '',
      location: json['location'] != null
          ? LocationModel.fromJson(json['location'])
          : null,
      addresses: (json['addresses'] as List?)
              ?.map<AddressModel>((e) => AddressModel.fromJson(e))
              .toList() ??
          [],
      rating: (json['rating'] ?? 0).toDouble(),
      totalRatings: json['totalRatings'] ?? 0,
      isSeller: json['isSeller'] ?? false,
      isVerified: json['isVerified'] ?? false,
      contactLocked: json['contactLocked'] ?? false,
      itemCount: json['itemCount'] ?? 0,
      completedBookings: json['completedBookings'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'location': location?.toJson(),
    };
  }

  /// Build full avatar URL: baseUrl/avatars/{id}/{filename}
  String get avatarUrl =>
      avatar.isNotEmpty ? '${ApiService.imageBaseUrl}/avatars/$id/$avatar' : '';

  /// Checks which profile fields are still missing.
  List<String> get incompleteFields {
    final missing = <String>[];
    if (name.isEmpty) missing.add('Name');
    if (email.isEmpty) missing.add('Email');
    if (phone.isEmpty) missing.add('Phone');
    if (avatar.isEmpty) missing.add('Profile Photo');
    if (location == null || location!.city.isEmpty) missing.add('Location');
    return missing;
  }

  bool get isProfileComplete => incompleteFields.isEmpty;
}

class AddressModel {
  final String id;
  final String label;
  final String addressLine1;
  final String addressLine2;
  final String street;
  final String city;
  final String state;
  final String pincode;
  final String landmark;
  final LocationModel? location;
  final bool isDefault;

  AddressModel({
    required this.id,
    this.label = 'Home',
    required this.addressLine1,
    this.addressLine2 = '',
    this.street = '',
    required this.city,
    this.state = '',
    this.pincode = '',
    this.landmark = '',
    this.location,
    this.isDefault = false,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] ?? json['_id'] ?? '',
      label: json['label'] ?? 'Home',
      addressLine1: json['addressLine1'] ?? '',
      addressLine2: json['addressLine2'] ?? '',
      street: json['street'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      landmark: json['landmark'] ?? '',
      location: json['location'] != null
          ? LocationModel.fromJson(json['location'])
          : null,
      isDefault: json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'street': street,
      'city': city,
      'state': state,
      'pincode': pincode,
      'landmark': landmark,
      'latitude': location?.latitude ?? 0,
      'longitude': location?.longitude ?? 0,
      'isDefault': isDefault,
    };
  }

  String get fullAddress {
    final parts = <String>[];
    if (addressLine1.isNotEmpty) parts.add(addressLine1);
    if (addressLine2.isNotEmpty) parts.add(addressLine2);
    if (street.isNotEmpty) parts.add(street);
    if (landmark.isNotEmpty) parts.add('Near $landmark');
    if (city.isNotEmpty) parts.add(city);
    if (state.isNotEmpty) parts.add(state);
    if (pincode.isNotEmpty) parts.add(pincode);
    return parts.join(', ');
  }
}

class LocationModel {
  final String type;
  final List<double> coordinates;
  final String address;
  final String city;

  LocationModel({
    this.type = 'Point',
    this.coordinates = const [0, 0],
    this.address = '',
    this.city = '',
  });

  double get longitude => coordinates.isNotEmpty ? coordinates[0] : 0;
  double get latitude => coordinates.length > 1 ? coordinates[1] : 0;

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      type: json['type'] ?? 'Point',
      coordinates: (json['coordinates'] as List?)
              ?.map<double>((e) => (e as num).toDouble())
              .toList() ??
          [0, 0],
      address: json['address'] ?? '',
      city: json['city'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'coordinates': coordinates,
      'address': address,
      'city': city,
    };
  }
}
