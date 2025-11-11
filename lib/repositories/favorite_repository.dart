import '../database/database_helper.dart';
import '../models/favorite.dart';

class FavoriteRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insertFavorite(Favorite favorite) async {
    try {
      return await _dbHelper.insert(
        DatabaseHelper.tableFavorites,
        favorite.toMap(),
      );
    } catch (e) {
      // Si la maison existe déjà (UNIQUE constraint), retourner 0
      return 0;
    }
  }

  Future<List<Favorite>> getAllFavorites(String userEmail) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      DatabaseHelper.tableFavorites,
      where: 'user_email = ?',
      whereArgs: [userEmail],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) {
      return Favorite.fromMap(maps[i]);
    });
  }

  Future<Favorite?> getFavoriteById(int id) async {
    final map = await _dbHelper.queryById(
      DatabaseHelper.tableFavorites,
      id,
    );
    return map != null ? Favorite.fromMap(map) : null;
  }

  Future<bool> isFavorite(int houseId, String userEmail) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      DatabaseHelper.tableFavorites,
      where: 'house_id = ? AND user_email = ?',
      whereArgs: [houseId, userEmail],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  Future<int> deleteFavorite(int id) async {
    return await _dbHelper.delete(
      DatabaseHelper.tableFavorites,
      id,
    );
  }

  Future<int> deleteFavoriteByHouseId(int houseId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseHelper.tableFavorites,
      where: 'house_id = ?',
      whereArgs: [houseId],
    );
  }

  Future<int> deleteAllFavorites() async {
    return await _dbHelper.deleteAll(DatabaseHelper.tableFavorites);
  }

  Future<int> countFavorites() async {
    final result = await _dbHelper.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseHelper.tableFavorites}',
    );
    return result.first['count'] as int;
  }
}
