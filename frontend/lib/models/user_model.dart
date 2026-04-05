class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String avatar;
  final LocationModel? location;
  final double rating;
  final int totalRatings;
  final bool isVerified;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.avatar = '',
    this.location,
    this.rating = 0,
    this.totalRatings = 0,
    this.isVerified = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      avatar: json['avatar'] ?? '',
      location: json['location'] != null
          ? LocationModel.fromJson(json['location'])
          : null,
      rating: (json['rating'] ?? 0).toDouble(),
      totalRatings: json['totalRatings'] ?? 0,
      isVerified: json['isVerified'] ?? false,
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
