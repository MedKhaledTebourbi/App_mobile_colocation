import 'package:collo/models/house.dart';

class HouseRepository {
  static final HouseRepository _instance = HouseRepository._internal();
  factory HouseRepository() => _instance;
  HouseRepository._internal();

  final List<House> _houses = [];

  Future<void> addHouse(House house) async {
    _houses.add(house);
  }

  Future<List<House>> getHouses() async {
    return _houses;
  }

  Future<void> deleteHouse(int id) async {
    _houses.removeWhere((house) => house.id == id);
  }

  Future<void> updateHouse(House house) async {
    final index = _houses.indexWhere((h) => h.id == house.id);
    if (index != -1) {
      _houses[index] = house;
    }
  }

  /// Update the tag of a house
  Future<void> updateHouseTag(int houseId, String newTag) async {
    final index = _houses.indexWhere((h) => h.id == houseId);
    if (index != -1) {
      _houses[index] = _houses[index].copyWith(tag: newTag);
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
}
