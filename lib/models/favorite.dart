class Favorite {
  int? id;
  int houseId;
  String houseTitle;
  String houseAddress;
  String houseImage;
  double housePrice;
  double houseRating;
  int bedrooms;
  int bathrooms;
  String userEmail;
  DateTime createdAt;

  Favorite({
    this.id,
    required this.houseId,
    required this.houseTitle,
    required this.houseAddress,
    required this.houseImage,
    required this.housePrice,
    required this.houseRating,
    required this.bedrooms,
    required this.bathrooms,
    required this.userEmail,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'house_id': houseId,
      'house_title': houseTitle,
      'house_address': houseAddress,
      'house_image': houseImage,
      'house_price': housePrice,
      'house_rating': houseRating,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'user_email': userEmail,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Favorite.fromMap(Map<String, dynamic> map) {
    return Favorite(
      id: _toInt(map['id']),
      houseId: _toInt(map['house_id'])!,
      houseTitle: map['house_title'] as String,
      houseAddress: map['house_address'] as String,
      houseImage: map['house_image'] as String,
      housePrice: _toDouble(map['house_price'])!,
      houseRating: _toDouble(map['house_rating'])!,
      bedrooms: _toInt(map['bedrooms'])!,
      bathrooms: _toInt(map['bathrooms'])!,
      userEmail: map['user_email'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
