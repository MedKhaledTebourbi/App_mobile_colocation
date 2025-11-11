import 'package:collo/models/chat_message.dart';
import 'package:collo/database/database_helper.dart';

class ChatRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> sendMessage(ChatMessage message) async {
    try {
      final result = await _dbHelper.insert(
        DatabaseHelper.tableChat,
        {
          'reservation_id': message.reservationId,
          'sender_email': message.senderEmail,
          'sender_name': message.senderName,
          'message': message.message,
          'timestamp': message.timestamp.toIso8601String(),
          'is_read': message.isRead ? 1 : 0,
        },
      );
      print('Message saved with ID: $result');
    } catch (e) {
      print('Error saving message: $e');
      rethrow;
    }
  }

  Future<List<ChatMessage>> getMessagesForReservation(int reservationId) async {
    try {
      final results = await _dbHelper.query(
        DatabaseHelper.tableChat,
        where: 'reservation_id = ?',
        whereArgs: [reservationId],
        orderBy: 'timestamp ASC',
      );
      return results.map((row) => ChatMessage.fromMap(row)).toList();
    } catch (e) {
      print('Error loading chat messages: $e');
      return [];
    }
  }

  Future<void> markMessagesAsRead(int reservationId, String userEmail) async {
    try {
      await _dbHelper.rawUpdate(
        'UPDATE ${DatabaseHelper.tableChat} SET is_read = 1 WHERE reservation_id = ? AND sender_email != ?',
        [reservationId, userEmail],
      );
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  Future<int> getUnreadMessageCount(String userEmail) async {
    try {
      final results = await _dbHelper.rawQuery(
        'SELECT COUNT(*) as count FROM ${DatabaseHelper.tableChat} WHERE sender_email != ? AND is_read = 0',
        [userEmail],
      );
      if (results.isNotEmpty) {
        return results.first['count'] as int? ?? 0;
      }
      return 0;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getAllMessages() async {
    try {
      final results = await _dbHelper.query(
        DatabaseHelper.tableChat,
        orderBy: 'timestamp DESC',
      );
      return results;
    } catch (e) {
      print('Error loading all messages: $e');
      return [];
    }
  }

  Future<void> deleteConversation(int reservationId) async {
    try {
      await _dbHelper.rawUpdate(
        'DELETE FROM ${DatabaseHelper.tableChat} WHERE reservation_id = ?',
        [reservationId],
      );
    } catch (e) {
      print('Error deleting conversation: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getConversationsByReservation() async {
    try {
      final results = await _dbHelper.rawQuery(
        'SELECT DISTINCT reservation_id, sender_email, sender_name, MAX(timestamp) as last_timestamp FROM ${DatabaseHelper.tableChat} GROUP BY reservation_id, sender_email ORDER BY last_timestamp DESC',
      );
      return results;
    } catch (e) {
      print('Error loading conversations: $e');
      return [];
    }
  }

  Future<int> getUnreadConversationCount(String userEmail) async {
    try {
      final results = await _dbHelper.rawQuery(
        'SELECT COUNT(DISTINCT reservation_id) as count FROM ${DatabaseHelper.tableChat} WHERE sender_email != ? AND is_read = 0',
        [userEmail],
      );
      if (results.isNotEmpty) {
        return results.first['count'] as int? ?? 0;
      }
      return 0;
    } catch (e) {
      print('Error getting unread conversation count: $e');
      return 0;
    }
  }
}
