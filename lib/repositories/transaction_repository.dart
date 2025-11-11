import '../database/database_helper.dart';
import '../models/transaction.dart';

class TransactionRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insertTransaction(Transaction transaction) async {
    return await _dbHelper.insert(
      DatabaseHelper.tableTransactions,
      transaction.toMap(),
    );
  }

  Future<List<Transaction>> getAllTransactions() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      DatabaseHelper.tableTransactions,
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) {
      return Transaction.fromMap(maps[i]);
    });
  }

  Future<Transaction?> getTransactionById(int id) async {
    final map = await _dbHelper.queryById(
      DatabaseHelper.tableTransactions,
      id,
    );
    return map != null ? Transaction.fromMap(map) : null;
  }

  Future<List<Transaction>> getTransactionsByStatus(String status) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      DatabaseHelper.tableTransactions,
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) {
      return Transaction.fromMap(maps[i]);
    });
  }

  Future<int> updateTransaction(Transaction transaction) async {
    return await _dbHelper.update(
      DatabaseHelper.tableTransactions,
      transaction.toMap(),
    );
  }

  Future<int> deleteTransaction(int id) async {
    return await _dbHelper.delete(
      DatabaseHelper.tableTransactions,
      id,
    );
  }

  Future<int> deleteAllTransactions() async {
    return await _dbHelper.deleteAll(DatabaseHelper.tableTransactions);
  }

  Future<int> countTransactions() async {
    final result = await _dbHelper.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseHelper.tableTransactions}',
    );
    return result.first['count'] as int;
  }

  Future<double> getTotalRevenue() async {
    final result = await _dbHelper.rawQuery(
      'SELECT SUM(total_price) as total FROM ${DatabaseHelper.tableTransactions} WHERE status != "cancelled"',
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<List<Transaction>> getTransactionsByCustomerEmail(String customerEmail) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      DatabaseHelper.tableTransactions,
      where: 'customer_email = ?',
      whereArgs: [customerEmail],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) {
      return Transaction.fromMap(maps[i]);
    });
  }
}
