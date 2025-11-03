import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:gestion_user_app/models/user.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'users.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE users(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL,
      email TEXT NOT NULL,
      password TEXT NOT NULL,
      role TEXT NOT NULL,
      imagePath TEXT,
      dateOfBirth TEXT,
      phone TEXT,
      address TEXT
    )
  ''');
  }


  // Ajouter un utilisateur
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', {
      'username': user.username,
      'email': user.email,
      'password': user.password,
      'role': user.role.toString().split('.').last,
    });
  }

  // Obtenir tous les utilisateurs
  Future<List<User>> getUsers() async {
    final db = await database;
    final result = await db.query('users');
    return result.map((json) => User(
      username: json['username'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      role: json['role'] == 'admin' ? Role.admin : Role.user,
    )).toList();
  }

  // Vérifier utilisateur par email et mot de passe
   Future<User?> getUserByEmailAndPassword(String email, String password) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    if (result.isNotEmpty) {
      final json = result.first;
      return User(
        username: json['username'] as String,
        email: json['email'] as String,
        password: json['password'] as String,
        role: json['role'] == 'admin' ? Role.admin : Role.user,
        imagePath: json['imagePath'] as String?, // <-- récupère l'image
        dateOfBirth: json['dateOfBirth'] as String?,
        phone: json['phone'] as String?,
        address: json['address'] as String?,
      );
    }
    return null;
  }
// Vérifier utilisateur par email uniquement
  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (result.isNotEmpty) {
      final json = result.first;
      return User(
        username: json['username'] as String,
        email: json['email'] as String,
        password: json['password'] as String,
        role: json['role'] == 'admin' ? Role.admin : Role.user,
        imagePath: json['imagePath'] as String?,

      );
    }
    return null;
  }


  Future<int> updateUserImage(String email, String imagePath) async {
    final db = await database;
    return await db.update(
      'users',
      {'imagePath': imagePath},
      where: 'email = ?',
      whereArgs: [email],
    );
  }


  // Mettre à jour le mot de passe
  Future<int> updateUserPassword(String email, String newPassword) async {
    final db = await database;
    return await db.update(
      'users',
      {'password': newPassword},
      where: 'email = ?',
      whereArgs: [email],
    );
  }

  Future<int> updateUserProfile(User user) async {
    final db = await database;
    return await db.update(
      'users',
      {
        'username': user.username,
        'dateOfBirth': user.dateOfBirth,
        'phone': user.phone,
        'address': user.address,
        'imagePath': user.imagePath,
      },
      where: 'email = ?',
      whereArgs: [user.email],
    );
  }
  Future<bool> changePassword(String email, String oldPassword, String newPassword) async {
    final db = await database;
    final result = await db.update(
      'users',
      {'password': newPassword},
      where: 'email = ? AND password = ?',
      whereArgs: [email, oldPassword],
    );
    return result > 0; // true si mot de passe changé
  }


}
