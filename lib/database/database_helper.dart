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
  static const int _databaseVersion = 12;

  // Tables
  static const String tableTransactions = 'transactions';
  static const String tableBookings = 'bookings';
  static const String tableFavorites = 'favorites';
  static const String tableNotifications = 'notifications';
  static const String tableExample = 'example_table';
  static const String tableHouses = 'houses';
  static const String tableChat = 'chat_messages';
  static const String tablePayments = 'payments';
  
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

    // Table des maisons
    await db.execute('''
      CREATE TABLE $tableHouses (
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        price REAL NOT NULL,
        address TEXT NOT NULL,
        bedrooms INTEGER NOT NULL,
        bathrooms INTEGER NOT NULL,
        area REAL NOT NULL,
        imageUrl TEXT NOT NULL,
        isFavorite INTEGER NOT NULL DEFAULT 0,
        rating REAL NOT NULL DEFAULT 0,
        owner_email TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )
    ''');
  }

  // Mise à jour de la base de données
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Gérer les migrations de schéma ici
    if (oldVersion < 2 && newVersion >= 2) {
      // Create houses table for version 2
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableHouses (
          id INTEGER PRIMARY KEY,
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          price REAL NOT NULL,
          address TEXT NOT NULL,
          bedrooms INTEGER NOT NULL,
          bathrooms INTEGER NOT NULL,
          area REAL NOT NULL,
          imageUrl TEXT NOT NULL,
          isFavorite INTEGER NOT NULL DEFAULT 0,
          rating REAL NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 3 && newVersion >= 3) {
      // Add owner_email column to houses
      await db.execute(
        "ALTER TABLE $tableHouses ADD COLUMN owner_email TEXT NOT NULL DEFAULT ''",
      );
    }
    if (oldVersion < 4 && newVersion >= 4) {
      // Add user_email column to favorites for user-specific favorites
      await db.execute(
        "ALTER TABLE $tableFavorites ADD COLUMN user_email TEXT NOT NULL DEFAULT ''",
      );
    }
    if (oldVersion < 5 && newVersion >= 5) {
      // Create notifications table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableNotifications (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          house_owner_email TEXT NOT NULL,
          booker_email TEXT NOT NULL,
          house_id INTEGER NOT NULL,
          house_title TEXT NOT NULL,
          booker_name TEXT NOT NULL,
          check_in_date TEXT NOT NULL,
          check_out_date TEXT NOT NULL,
          total_price REAL NOT NULL,
          status TEXT NOT NULL DEFAULT 'pending',
          created_at TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 7 && newVersion >= 7) {
      // Create chat messages table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableChat (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          reservation_id INTEGER NOT NULL,
          sender_email TEXT NOT NULL,
          sender_name TEXT NOT NULL,
          message TEXT NOT NULL,
          timestamp TEXT NOT NULL,
          is_read INTEGER NOT NULL DEFAULT 0
        )
      ''');
    }
    if (oldVersion < 8 && newVersion >= 8) {
      // Add property_type, ownership_status, and owner_username columns to houses
      try {
        await db.execute(
          "ALTER TABLE $tableHouses ADD COLUMN property_type TEXT NOT NULL DEFAULT 'House'",
        );
      } catch (e) {
        // Column might already exist
      }
      try {
        await db.execute(
          "ALTER TABLE $tableHouses ADD COLUMN ownership_status TEXT NOT NULL DEFAULT 'For Rent'",
        );
      } catch (e) {
        // Column might already exist
      }
      try {
        await db.execute(
          "ALTER TABLE $tableHouses ADD COLUMN owner_username TEXT NOT NULL DEFAULT ''",
        );
      } catch (e) {
        // Column might already exist
      }
    }
    if (oldVersion < 9 && newVersion >= 9) {
      // Create payments table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tablePayments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          transaction_id INTEGER NOT NULL,
          card_holder_name TEXT NOT NULL,
          card_number TEXT NOT NULL,
          expiry_date TEXT NOT NULL,
          amount REAL NOT NULL,
          status TEXT NOT NULL DEFAULT 'pending',
          payment_method TEXT NOT NULL DEFAULT 'credit_card',
          created_at TEXT NOT NULL,
          completed_at TEXT,
          failure_reason TEXT
        )
      ''');
    }
    if (oldVersion < 10 && newVersion >= 10) {
      // Add availability column to houses
      try {
        await db.execute(
          "ALTER TABLE $tableHouses ADD COLUMN availability TEXT NOT NULL DEFAULT 'available'",
        );
      } catch (e) {
        // Column might already exist
      }
    }
    if (oldVersion < 11 && newVersion >= 11) {
      // Create bookings table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableBookings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          house_id INTEGER NOT NULL,
          house_title TEXT NOT NULL,
          house_image TEXT NOT NULL,
          booker_name TEXT NOT NULL,
          booker_email TEXT NOT NULL,
          booker_phone TEXT NOT NULL,
          check_in_date TEXT NOT NULL,
          check_out_date TEXT NOT NULL,
          number_of_guests INTEGER NOT NULL,
          total_price REAL NOT NULL,
          status TEXT NOT NULL DEFAULT 'pending',
          created_at TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 12 && newVersion >= 12) {
      // Add tag column to houses
      try {
        await db.execute(
          "ALTER TABLE $tableHouses ADD COLUMN tag TEXT NOT NULL DEFAULT 'Available'",
        );
      } catch (e) {
        // Column might already exist
      }
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

  // Raw Update
  Future<int> rawUpdate(String sql, [List<dynamic>? arguments]) async {
    Database db = await database;
    return await db.rawUpdate(sql, arguments);
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
