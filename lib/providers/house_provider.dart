import 'package:collo/models/house.dart';
import 'package:collo/data/sample_houses.dart';
import 'package:collo/database/database_helper.dart';
import 'package:collo/providers/session_provider.dart';
import 'package:collo/services/house_availability_calculator.dart';

class HouseProvider {
  static final HouseProvider _instance = HouseProvider._internal();
  
  factory HouseProvider() {
    return _instance;
  }
  
  HouseProvider._internal();
  
  List<House> _houses = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _initialized = false;
  
  List<House> get houses {
    return _houses;
  }
  
  Future<void> addHouse(House house) async {
    // Attach current user as owner
    final currentUser = SessionProvider().currentUser;
    final ownerEmail = currentUser?.email ?? '';
    final ownerUsername = currentUser?.username ?? '';
    
    final houseWithOwner = House(
      id: house.id,
      title: house.title,
      address: house.address,
      imageUrl: house.imageUrl,
      price: house.price,
      rating: house.rating,
      bedrooms: house.bedrooms,
      bathrooms: house.bathrooms,
      area: house.area,
      description: house.description,
      agentName: house.agentName,
      agentRole: house.agentRole,
      agentImage: house.agentImage,
      isFavorite: house.isFavorite,
      ownerEmail: ownerEmail,
      ownerUsername: ownerUsername,
      propertyType: house.propertyType,
      ownershipStatus: house.ownershipStatus,
    );

    _houses.add(houseWithOwner);
    // Persist to database
    await _dbHelper.insert(
      DatabaseHelper.tableHouses,
      {
        'id': houseWithOwner.id,
        'title': houseWithOwner.title,
        'description': houseWithOwner.description,
        'price': houseWithOwner.price,
        'address': houseWithOwner.address,
        'bedrooms': houseWithOwner.bedrooms,
        'bathrooms': houseWithOwner.bathrooms,
        'area': houseWithOwner.area,
        'imageUrl': houseWithOwner.imageUrl,
        'isFavorite': houseWithOwner.isFavorite ? 1 : 0,
        'rating': houseWithOwner.rating,
        'owner_email': houseWithOwner.ownerEmail,
        'owner_username': houseWithOwner.ownerUsername,
        'property_type': houseWithOwner.propertyType,
        'ownership_status': houseWithOwner.ownershipStatus,
        'created_at': DateTime.now().toIso8601String(),
      },
    );
  }
  
  Future<void> initialize() async {
    if (_initialized) return;
    
    // Load from database first
    final dbHouses = await _loadHousesFromDatabase();
    
    if (dbHouses.isNotEmpty) {
      _houses = dbHouses;
    } else {
      // If database is empty, load sample houses and save them
      _houses = SampleHouses.getHouses();
      for (var house in _houses) {
        await _dbHelper.insert(
          DatabaseHelper.tableHouses,
          {
            'id': house.id,
            'title': house.title,
            'description': house.description,
            'price': house.price,
            'address': house.address,
            'bedrooms': house.bedrooms,
            'bathrooms': house.bathrooms,
            'area': house.area,
            'imageUrl': house.imageUrl,
            'isFavorite': house.isFavorite ? 1 : 0,
            'rating': house.rating,
            'owner_email': house.ownerEmail,
            'created_at': DateTime.now().toIso8601String(),
          },
        );
      }
    }
    
    _initialized = true;
  }
  
  Future<List<House>> _loadHousesFromDatabase() async {
    try {
      final results = await _dbHelper.queryAll(DatabaseHelper.tableHouses);
      return results.map((row) {
        return House(
          id: row['id'] as int,
          title: row['title'] as String,
          description: row['description'] as String,
          price: (row['price'] is int) ? (row['price'] as int).toDouble() : row['price'] as double,
          address: row['address'] as String,
          bedrooms: row['bedrooms'] as int,
          bathrooms: row['bathrooms'] as int,
          area: (row['area'] is int) ? (row['area'] as int).toDouble() : row['area'] as double,
          imageUrl: row['imageUrl'] as String,
          isFavorite: (row['isFavorite'] as int) == 1,
          rating: (row['rating'] is int) ? (row['rating'] as int).toDouble() : row['rating'] as double,
          ownerEmail: (row['owner_email'] ?? '') as String,
          ownerUsername: (row['owner_username'] ?? '') as String,
          propertyType: (row['property_type'] ?? 'House') as String,
          ownershipStatus: (row['ownership_status'] ?? 'For Rent') as String,
          tag: (row['tag'] ?? 'Available') as String,
        );
      }).toList();
    } catch (e) {
      print('Error loading houses from database: $e');
      return [];
    }
  }
  
  Future<void> deleteHouse(int id) async {
    _houses.removeWhere((house) => house.id == id);
    await _dbHelper.delete(DatabaseHelper.tableHouses, id);
  }
  
  Future<void> updateHouse(House house) async {
    final index = _houses.indexWhere((h) => h.id == house.id);
    if (index != -1) {
      _houses[index] = house;
      await _dbHelper.update(
        DatabaseHelper.tableHouses,
        {
          'id': house.id,
          'title': house.title,
          'description': house.description,
          'price': house.price,
          'address': house.address,
          'bedrooms': house.bedrooms,
          'bathrooms': house.bathrooms,
          'area': house.area,
          'imageUrl': house.imageUrl,
          'isFavorite': house.isFavorite ? 1 : 0,
          'rating': house.rating,
          'owner_email': house.ownerEmail,
        },
      );
    }
  }

  /// Get a house by ID
  Future<House?> getHouseById(int houseId) async {
    try {
      return _houses.firstWhere((h) => h.id == houseId);
    } catch (e) {
      return null;
    }
  }

  /// Get all houses with dynamically calculated availability status
  Future<List<House>> getHousesWithDynamicStatus() async {
    final calculator = HouseAvailabilityCalculator();
    return await calculator.getHousesWithCalculatedStatus(_houses);
  }

  /// Get a single house with dynamically calculated status
  Future<House?> getHouseWithDynamicStatus(int houseId) async {
    final house = await getHouseById(houseId);
    if (house == null) return null;
    
    final calculator = HouseAvailabilityCalculator();
    final calculatedStatus = await calculator.calculateHouseStatus(house);
    return house.copyWith(tag: calculatedStatus);
  }
}
