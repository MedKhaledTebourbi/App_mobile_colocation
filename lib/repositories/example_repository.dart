import '../database/database_helper.dart';
import '../models/example_model.dart';

class ExampleRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Insérer un nouvel élément
  Future<int> insertExample(ExampleModel example) async {
    return await _dbHelper.insert(
      DatabaseHelper.tableExample,
      example.toMap(),
    );
  }

  // Récupérer tous les éléments
  Future<List<ExampleModel>> getAllExamples() async {
    final List<Map<String, dynamic>> maps = await _dbHelper.queryAll(
      DatabaseHelper.tableExample,
    );
    return List.generate(maps.length, (i) {
      return ExampleModel.fromMap(maps[i]);
    });
  }

  // Récupérer un élément par ID
  Future<ExampleModel?> getExampleById(int id) async {
    final map = await _dbHelper.queryById(
      DatabaseHelper.tableExample,
      id,
    );
    return map != null ? ExampleModel.fromMap(map) : null;
  }

  // Rechercher des éléments par nom
  Future<List<ExampleModel>> searchExamplesByName(String name) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      DatabaseHelper.tableExample,
      where: 'name LIKE ?',
      whereArgs: ['%$name%'],
    );
    return List.generate(maps.length, (i) {
      return ExampleModel.fromMap(maps[i]);
    });
  }

  // Mettre à jour un élément
  Future<int> updateExample(ExampleModel example) async {
    return await _dbHelper.update(
      DatabaseHelper.tableExample,
      example.toMap(),
    );
  }

  // Supprimer un élément
  Future<int> deleteExample(int id) async {
    return await _dbHelper.delete(
      DatabaseHelper.tableExample,
      id,
    );
  }

  // Supprimer tous les éléments
  Future<int> deleteAllExamples() async {
    return await _dbHelper.deleteAll(DatabaseHelper.tableExample);
  }

  // Compter le nombre d'éléments
  Future<int> countExamples() async {
    final result = await _dbHelper.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseHelper.tableExample}',
    );
    return result.first['count'] as int;
  }
}
