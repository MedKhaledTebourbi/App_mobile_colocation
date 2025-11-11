import '../database/database_helper.dart';
import '../models/payment.dart';

class PaymentRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insertPayment(Payment payment) async {
    return await _dbHelper.insert(
      DatabaseHelper.tablePayments,
      payment.toMap(),
    );
  }

  Future<List<Payment>> getAllPayments() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      DatabaseHelper.tablePayments,
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) {
      return Payment.fromMap(maps[i]);
    });
  }

  Future<Payment?> getPaymentById(int id) async {
    final map = await _dbHelper.queryById(
      DatabaseHelper.tablePayments,
      id,
    );
    return map != null ? Payment.fromMap(map) : null;
  }

  Future<Payment?> getPaymentByTransactionId(int transactionId) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      DatabaseHelper.tablePayments,
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
      limit: 1,
    );
    return maps.isNotEmpty ? Payment.fromMap(maps.first) : null;
  }

  Future<List<Payment>> getPaymentsByStatus(String status) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      DatabaseHelper.tablePayments,
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) {
      return Payment.fromMap(maps[i]);
    });
  }

  Future<int> updatePayment(Payment payment) async {
    return await _dbHelper.update(
      DatabaseHelper.tablePayments,
      payment.toMap(),
    );
  }

  Future<int> deletePayment(int id) async {
    return await _dbHelper.delete(
      DatabaseHelper.tablePayments,
      id,
    );
  }

  Future<int> deleteAllPayments() async {
    return await _dbHelper.deleteAll(DatabaseHelper.tablePayments);
  }

  Future<int> countPayments() async {
    final result = await _dbHelper.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseHelper.tablePayments}',
    );
    return result.first['count'] as int;
  }

  Future<double> getTotalRevenue() async {
    final result = await _dbHelper.rawQuery(
      'SELECT SUM(amount) as total FROM ${DatabaseHelper.tablePayments} WHERE status = "completed"',
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<int> countCompletedPayments() async {
    final result = await _dbHelper.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseHelper.tablePayments} WHERE status = "completed"',
    );
    return result.first['count'] as int;
  }

  Future<int> countFailedPayments() async {
    final result = await _dbHelper.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseHelper.tablePayments} WHERE status = "failed"',
    );
    return result.first['count'] as int;
  }
}
