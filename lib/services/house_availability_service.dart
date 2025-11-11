import '../database/database_helper.dart';
import '../utils/logger.dart';

/// Service for managing house availability status
class HouseAvailabilityService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Update house availability status
  /// availability: 'available', 'unavailable', 'booked'
  Future<bool> updateHouseAvailability(int houseId, String availability) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.update(
        DatabaseHelper.tableHouses,
        {'availability': availability},
        where: 'id = ?',
        whereArgs: [houseId],
      );
      
      if (result > 0) {
        Logger.info('House $houseId availability updated to: $availability');
        return true;
      }
      return false;
    } catch (e) {
      Logger.error('Error updating house availability', e);
      return false;
    }
  }

  /// Get house availability status
  Future<String?> getHouseAvailability(int houseId) async {
    try {
      final map = await _dbHelper.queryById(DatabaseHelper.tableHouses, houseId);
      if (map != null) {
        return map['availability'] as String?;
      }
      return null;
    } catch (e) {
      Logger.error('Error fetching house availability', e);
      return null;
    }
  }

  /// Mark house as unavailable (booked)
  Future<bool> markHouseAsUnavailable(int houseId) async {
    return updateHouseAvailability(houseId, 'unavailable');
  }

  /// Mark house as available
  Future<bool> markHouseAsAvailable(int houseId) async {
    return updateHouseAvailability(houseId, 'available');
  }
}
