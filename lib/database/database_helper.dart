import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // Singleton pattern 
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  // Nom de la base de données
  static const String _databaseName = 'collo_database.db';
  static const int _databaseVersion = 1;

  // Tables
  static const String tableTransactions = 'transactions';
  static const String tableFavorites = 'favorites';
  static const String tableExample = 'example_table';
  
  static const String columnId = 'id';
  static const String columnName = 'name';
  static const String columnDescription = 'description';
  static const String columnCreatedAt = 'created_at';

  // Getter pour la base de données
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialisation de la base de données
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Création des tables
  Future<void> _onCreate(Database db, int version) async {
    // Table des transactions
    await db.execute('''
      CREATE TABLE $tableTransactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        house_id TEXT NOT NULL,
        house_title TEXT NOT NULL,
        house_image TEXT NOT NULL,
        customer_name TEXT NOT NULL,
        customer_email TEXT NOT NULL,
        customer_phone TEXT NOT NULL,
        check_in_date TEXT NOT NULL,
        check_out_date TEXT NOT NULL,
        number_of_guests INTEGER NOT NULL,
        total_price REAL NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Table des favoris
    await db.execute('''
      CREATE TABLE $tableFavorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        house_id TEXT NOT NULL UNIQUE,
        house_title TEXT NOT NULL,
        house_address TEXT NOT NULL,
        house_image TEXT NOT NULL,
        house_price REAL NOT NULL,
        house_rating REAL NOT NULL,
        bedrooms INTEGER NOT NULL,
        bathrooms INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Table exemple
    await db.execute('''
      CREATE TABLE $tableExample (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnName TEXT NOT NULL,
        $columnDescription TEXT,
        $columnCreatedAt TEXT NOT NULL
      )
    ''');
  }

  // Mise à jour de la base de données
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Gérer les migrations de schéma ici
    if (oldVersion < newVersion) {
      // Exemple: ajouter une nouvelle colonne
      // await db.execute('ALTER TABLE $tableExample ADD COLUMN new_column TEXT');
    }
  }

  // CRUD Operations - CREATE
  Future<int> insert(String table, Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert(table, row);
  }

  // CRUD Operations - READ
  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    Database db = await database;
    return await db.query(table);
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    Database db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
  }

  Future<Map<String, dynamic>?> queryById(String table, int id) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      table,
      where: '$columnId = ?',
      whereArgs: [id],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  // CRUD Operations - UPDATE
  Future<int> update(String table, Map<String, dynamic> row) async {
    Database db = await database;
    int id = row[columnId];
    return await db.update(
      table,
      row,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  // CRUD Operations - DELETE
  Future<int> delete(String table, int id) async {
    Database db = await database;
    return await db.delete(
      table,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAll(String table) async {
    Database db = await database;
    return await db.delete(table);
  }

  // Requête personnalisée
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? arguments]) async {
    Database db = await database;
    return await db.rawQuery(sql, arguments);
  }

  // Exécution SQL brute
  Future<int> rawExecute(String sql, [List<dynamic>? arguments]) async {
    Database db = await database;
    return await db.rawInsert(sql, arguments);
  }

  // Fermer la base de données
  Future<void> close() async {
    Database db = await database;
    await db.close();
  }

  // Supprimer la base de données
  Future<void> deleteDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
