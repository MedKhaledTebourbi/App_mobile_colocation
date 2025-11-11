import '../database/database_helper.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insertNotification(NotificationModel notification) async {
    try {
      return await _dbHelper.insert(
        DatabaseHelper.tableNotifications,
        _notificationToMap(notification),
      );
    } catch (e) {
      print('Error inserting notification: $e');
      return 0;
    }
  }

  Future<List<NotificationModel>> getNotificationsForOwner(String ownerEmail) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      DatabaseHelper.tableNotifications,
      where: 'house_owner_email = ?',
      whereArgs: [ownerEmail],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) {
      return _notificationFromMap(maps[i]);
    });
  }

  Future<List<NotificationModel>> getPendingNotificationsForOwner(String ownerEmail) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      DatabaseHelper.tableNotifications,
      where: 'house_owner_email = ? AND status = ?',
      whereArgs: [ownerEmail, 'pending'],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) {
      return _notificationFromMap(maps[i]);
    });
  }

  Future<List<NotificationModel>> getNotificationsForBooker(String bookerEmail) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      DatabaseHelper.tableNotifications,
      where: 'booker_email = ?',
      whereArgs: [bookerEmail],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) {
      return _notificationFromMap(maps[i]);
    });
  }

  Future<NotificationModel?> getNotificationById(int id) async {
    final map = await _dbHelper.queryById(
      DatabaseHelper.tableNotifications,
      id,
    );
    return map != null ? _notificationFromMap(map) : null;
  }

  Future<int> updateNotificationStatus(int id, String status) async {
    final db = await _dbHelper.database;
    return await db.update(
      DatabaseHelper.tableNotifications,
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteNotification(int id) async {
    return await _dbHelper.delete(
      DatabaseHelper.tableNotifications,
      id,
    );
  }

  Future<int> countPendingNotificationsForOwner(String ownerEmail) async {
    final result = await _dbHelper.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseHelper.tableNotifications} WHERE house_owner_email = ? AND status = ?',
      [ownerEmail, 'pending'],
    );
    return result.first['count'] as int;
  }

  /// Check if a client has an active booking for a specific house
  /// Active means: pending or approved status
  Future<bool> hasActiveBookingForHouse(String bookerEmail, int houseId) async {
    try {
      final result = await _dbHelper.rawQuery(
        'SELECT COUNT(*) as count FROM ${DatabaseHelper.tableNotifications} WHERE booker_email = ? AND house_id = ? AND (status = ? OR status = ?)',
        [bookerEmail, houseId, 'pending', 'approved'],
      );
      return (result.first['count'] as int) > 0;
    } catch (e) {
      print('Error checking active booking: $e');
      return false;
    }
  }

  /// Get active booking for a client on a specific house
  Future<NotificationModel?> getActiveBookingForHouse(String bookerEmail, int houseId) async {
    try {
      final List<Map<String, dynamic>> maps = await _dbHelper.query(
        DatabaseHelper.tableNotifications,
        where: 'booker_email = ? AND house_id = ? AND (status = ? OR status = ?)',
        whereArgs: [bookerEmail, houseId, 'pending', 'approved'],
      );
      if (maps.isNotEmpty) {
        return _notificationFromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('Error getting active booking: $e');
      return null;
    }
  }

  /// Get all active bookings for a client
  Future<List<NotificationModel>> getActiveBookingsForBooker(String bookerEmail) async {
    try {
      final List<Map<String, dynamic>> maps = await _dbHelper.query(
        DatabaseHelper.tableNotifications,
        where: 'booker_email = ? AND (status = ? OR status = ?)',
        whereArgs: [bookerEmail, 'pending', 'approved'],
      );
      return List.generate(maps.length, (i) {
        return _notificationFromMap(maps[i]);
      });
    } catch (e) {
      print('Error getting active bookings: $e');
      return [];
    }
  }

  /// Get all bookings for a client (any status)
  Future<List<NotificationModel>> getAllBookingsForBooker(String bookerEmail) async {
    try {
      final List<Map<String, dynamic>> maps = await _dbHelper.query(
        DatabaseHelper.tableNotifications,
        where: 'booker_email = ?',
        whereArgs: [bookerEmail],
        orderBy: 'created_at DESC',
      );
      return List.generate(maps.length, (i) {
        return _notificationFromMap(maps[i]);
      });
    } catch (e) {
      print('Error getting all bookings: $e');
      return [];
    }
  }

  /// Get all notifications for a specific house
  Future<List<NotificationModel>> getNotificationsForHouse(int houseId) async {
    try {
      final List<Map<String, dynamic>> maps = await _dbHelper.query(
        DatabaseHelper.tableNotifications,
        where: 'house_id = ?',
        whereArgs: [houseId],
        orderBy: 'created_at DESC',
      );
      return List.generate(maps.length, (i) {
        return _notificationFromMap(maps[i]);
      });
    } catch (e) {
      print('Error getting notifications for house: $e');
      return [];
    }
  }

  // Helper methods
  Map<String, dynamic> _notificationToMap(NotificationModel notification) {
    return {
      'id': notification.id,
      'house_owner_email': notification.houseOwnerEmail,
      'booker_email': notification.bookerEmail,
      'house_id': notification.houseId,
      'house_title': notification.houseTitle,
      'booker_name': notification.bookerName,
      'check_in_date': notification.checkInDate.toIso8601String(),
      'check_out_date': notification.checkOutDate.toIso8601String(),
      'total_price': notification.totalPrice,
      'status': notification.status,
      'created_at': notification.createdAt.toIso8601String(),
    };
  }

  NotificationModel _notificationFromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] as int?,
      houseOwnerEmail: map['house_owner_email'] as String,
      bookerId: 0, // Not stored in DB, can be derived from booker_email if needed
      houseId: map['house_id'] as int,
      houseTitle: map['house_title'] as String,
      bookerName: map['booker_name'] as String,
      bookerEmail: map['booker_email'] as String,
      checkInDate: DateTime.parse(map['check_in_date'] as String),
      checkOutDate: DateTime.parse(map['check_out_date'] as String),
      totalPrice: (map['total_price'] as num).toDouble(),
      status: map['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
