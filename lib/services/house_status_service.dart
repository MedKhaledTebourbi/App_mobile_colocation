import 'package:collo/database/database_helper.dart';
import 'package:collo/models/house.dart';
import 'package:collo/providers/house_provider.dart';
import 'package:collo/utils/logger.dart';

/// Service to manage house status changes
class HouseStatusService {
  static final HouseStatusService _instance = HouseStatusService._internal();
  factory HouseStatusService() => _instance;
  HouseStatusService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final HouseProvider _houseProvider = HouseProvider();

  /// Update house tag/status
  /// Tags: 'Available', 'Pending', 'Rented', 'Maintenance', 'Unavailable'
  Future<void> updateHouseTag(int houseId, String newTag) async {
    try {
      final db = await _dbHelper.database;
      await db.update(
        DatabaseHelper.tableHouses,
        {'tag': newTag},
        where: 'id = ?',
        whereArgs: [houseId],
      );

      // Update in memory
      final house = await _houseProvider.getHouseById(houseId);
      if (house != null) {
        final updatedHouse = house.copyWith(tag: newTag);
        await _houseProvider.updateHouse(updatedHouse);
      }

      Logger.info('House $houseId tag updated to: $newTag');
    } catch (e) {
      Logger.error('Error updating house tag', e);
      rethrow;
    }
  }

  /// Mark house as pending when a booking is requested
  Future<void> markAsPending(int houseId) async {
    await updateHouseTag(houseId, 'Pending');
  }

  /// Mark house as rented when booking is confirmed
  Future<void> markAsRented(int houseId) async {
    await updateHouseTag(houseId, 'Rented');
  }

  /// Mark house as available when booking is cancelled
  Future<void> markAsAvailable(int houseId) async {
    await updateHouseTag(houseId, 'Available');
  }

  /// Mark house as unavailable for maintenance
  Future<void> markAsUnavailable(int houseId) async {
    await updateHouseTag(houseId, 'Unavailable');
  }

  /// Mark house as under maintenance
  Future<void> markAsMaintenance(int houseId) async {
    await updateHouseTag(houseId, 'Maintenance');
  }

  /// Get current tag of a house
  Future<String?> getHouseTag(int houseId) async {
    try {
      final house = await _houseProvider.getHouseById(houseId);
      return house?.tag;
    } catch (e) {
      Logger.error('Error getting house tag', e);
      return null;
    }
  }

  /// Get tag color for UI display
  static String getTagColor(String tag) {
    switch (tag) {
      case 'Available':
        return '#4CAF50'; // Green
      case 'Pending':
        return '#FF9800'; // Orange
      case 'Rented':
        return '#2196F3'; // Blue
      case 'Réservée':
        return '#1976D2'; // Dark Blue
      case 'Maintenance':
        return '#9C27B0'; // Purple
      case 'Unavailable':
        return '#F44336'; // Red
      default:
        return '#757575'; // Grey
    }
  }

  /// Get tag display text
  static String getTagDisplayText(String tag) {
    switch (tag) {
      case 'Available':
        return 'Disponible';
      case 'Pending':
        return 'En attente';
      case 'Rented':
        return 'Louée';
      case 'Réservée':
        return 'Réservée';
      case 'Maintenance':
        return 'Maintenance';
      case 'Unavailable':
        return 'Indisponible';
      default:
        return tag;
    }
  }
}
