class Favorite {
  int? id;
  String houseId;
  String houseTitle;
  String houseAddress;
  String houseImage;
  double housePrice;
  double houseRating;
  int bedrooms;
  int bathrooms;
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
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Favorite.fromMap(Map<String, dynamic> map) {
    return Favorite(
      id: map['id'] as int?,
      houseId: map['house_id'] as String,
      houseTitle: map['house_title'] as String,
      houseAddress: map['house_address'] as String,
      houseImage: map['house_image'] as String,
      housePrice: map['house_price'] as double,
      houseRating: map['house_rating'] as double,
      bedrooms: map['bedrooms'] as int,
      bathrooms: map['bathrooms'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
