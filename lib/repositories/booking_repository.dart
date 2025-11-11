import '../database/database_helper.dart';
import '../models/booking.dart';

class BookingRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insertBooking(Booking booking) async {
    try {
      return await _dbHelper.insert(
        DatabaseHelper.tableBookings,
        booking.toMap(),
      );
    } catch (e) {
      print('Error inserting booking: $e');
      return 0;
    }
  }

  Future<List<Booking>> getBookingsForHouse(int houseId) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      DatabaseHelper.tableBookings,
      where: 'house_id = ?',
      whereArgs: [houseId],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) {
      return Booking.fromMap(maps[i]);
    });
  }

  Future<List<Booking>> getPendingBookingsForHouse(int houseId) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      DatabaseHelper.tableBookings,
      where: 'house_id = ? AND status = ?',
      whereArgs: [houseId, 'pending'],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) {
      return Booking.fromMap(maps[i]);
    });
  }

  Future<List<Booking>> getBookingsByBooker(String bookerEmail) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      DatabaseHelper.tableBookings,
      where: 'booker_email = ?',
      whereArgs: [bookerEmail],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) {
      return Booking.fromMap(maps[i]);
    });
  }

  Future<Booking?> getBookingById(int id) async {
    final map = await _dbHelper.queryById(
      DatabaseHelper.tableBookings,
      id,
    );
    return map != null ? Booking.fromMap(map) : null;
  }

  Future<int> updateBookingStatus(int id, String status) async {
    final db = await _dbHelper.database;
    return await db.update(
      DatabaseHelper.tableBookings,
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteBooking(int id) async {
    return await _dbHelper.delete(
      DatabaseHelper.tableBookings,
      id,
    );
  }

  Future<int> countPendingBookingsForHouse(int houseId) async {
    final result = await _dbHelper.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseHelper.tableBookings} WHERE house_id = ? AND status = ?',
      [houseId, 'pending'],
    );
    return result.first['count'] as int;
  }

  /// Check if a client has an active booking for a specific house
  /// Active means: pending or approved status
  Future<bool> hasActiveBookingForHouse(String bookerEmail, int houseId) async {
    try {
      final result = await _dbHelper.rawQuery(
        'SELECT COUNT(*) as count FROM ${DatabaseHelper.tableBookings} WHERE booker_email = ? AND house_id = ? AND (status = ? OR status = ?)',
        [bookerEmail, houseId, 'pending', 'approved'],
      );
      return (result.first['count'] as int) > 0;
    } catch (e) {
      print('Error checking active booking: $e');
      return false;
    }
  }

  /// Get active booking for a client on a specific house
  Future<Booking?> getActiveBookingForHouse(String bookerEmail, int houseId) async {
    try {
      final List<Map<String, dynamic>> maps = await _dbHelper.query(
        DatabaseHelper.tableBookings,
        where: 'booker_email = ? AND house_id = ? AND (status = ? OR status = ?)',
        whereArgs: [bookerEmail, houseId, 'pending', 'approved'],
      );
      if (maps.isNotEmpty) {
        return Booking.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('Error getting active booking: $e');
      return null;
    }
  }

  /// Get all active bookings for a client
  Future<List<Booking>> getActiveBookingsForBooker(String bookerEmail) async {
    try {
      final List<Map<String, dynamic>> maps = await _dbHelper.query(
        DatabaseHelper.tableBookings,
        where: 'booker_email = ? AND (status = ? OR status = ?)',
        whereArgs: [bookerEmail, 'pending', 'approved'],
      );
      return List.generate(maps.length, (i) {
        return Booking.fromMap(maps[i]);
      });
    } catch (e) {
      print('Error getting active bookings: $e');
      return [];
    }
  }

  /// Check if a client has any active bookings
  Future<int> countActiveBookingsForBooker(String bookerEmail) async {
    try {
      final result = await _dbHelper.rawQuery(
        'SELECT COUNT(*) as count FROM ${DatabaseHelper.tableBookings} WHERE booker_email = ? AND (status = ? OR status = ?)',
        [bookerEmail, 'pending', 'approved'],
      );
      return result.first['count'] as int;
    } catch (e) {
      print('Error counting active bookings: $e');
      return 0;
    }
  }
}
