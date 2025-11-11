class House {
  final int id;
  final String title;
  final String address;
  final String imageUrl;
  final double price;
  final double rating;
  final int bedrooms;
  final int bathrooms;
  final double area;
  final String description;
  final String agentName;
  final String agentRole;
  final String agentImage;
  final bool isFavorite;
  final String ownerEmail;
  final String ownerUsername; // Username of the house owner
  final String propertyType; // 'House' or 'Villa'
  final String ownershipStatus; // 'Owned' or 'For Rent'
  final String tag; // Tag/status of the house (e.g., 'Available', 'Rented', 'Maintenance')

  House({
    required this.id,
    required this.title,
    required this.address,
    required this.imageUrl,
    required this.price,
    this.rating = 4.5,
    required this.bedrooms,
    required this.bathrooms,
    required this.area,
    required this.description,
    this.agentName = 'Agent',
    this.agentRole = 'Real Estate Agent',
    this.agentImage = 'https://via.placeholder.com/150',
    this.isFavorite = false,
    this.ownerEmail = '',
    this.ownerUsername = '',
    this.propertyType = 'House',
    this.ownershipStatus = 'For Rent',
    this.tag = 'Available',
  });

  /// Create a copy of this house with modified fields
  House copyWith({
    int? id,
    String? title,
    String? address,
    String? imageUrl,
    double? price,
    double? rating,
    int? bedrooms,
    int? bathrooms,
    double? area,
    String? description,
    String? agentName,
    String? agentRole,
    String? agentImage,
    bool? isFavorite,
    String? ownerEmail,
    String? ownerUsername,
    String? propertyType,
    String? ownershipStatus,
    String? tag,
  }) {
    return House(
      id: id ?? this.id,
      title: title ?? this.title,
      address: address ?? this.address,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      rating: rating ?? this.rating,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      area: area ?? this.area,
      description: description ?? this.description,
      agentName: agentName ?? this.agentName,
      agentRole: agentRole ?? this.agentRole,
      agentImage: agentImage ?? this.agentImage,
      isFavorite: isFavorite ?? this.isFavorite,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      ownerUsername: ownerUsername ?? this.ownerUsername,
      propertyType: propertyType ?? this.propertyType,
      ownershipStatus: ownershipStatus ?? this.ownershipStatus,
      tag: tag ?? this.tag,
    );
  }
}
