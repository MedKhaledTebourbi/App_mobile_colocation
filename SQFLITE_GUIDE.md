# Guide de Configuration Sqflite

## 📦 Installation

Les dépendances suivantes ont été ajoutées au `pubspec.yaml`:

```yaml
dependencies:
  sqflite: ^2.3.0
  path: ^1.8.3
```

Pour installer les dépendances, exécutez:
```bash
flutter pub get
```

## 🏗️ Structure du Projet

```
lib/
├── database/
│   └── database_helper.dart      # Helper singleton pour gérer la base de données
├── models/
│   └── example_model.dart        # Modèle d'exemple avec toMap() et fromMap()
├── repositories/
│   └── example_repository.dart   # Repository pour les opérations CRUD
└── main.dart                      # Application de démonstration
```

## 🔧 Composants Principaux

### 1. DatabaseHelper (Singleton)

Le `DatabaseHelper` est un singleton qui gère:
- ✅ Création et initialisation de la base de données
- ✅ Gestion des versions et migrations
- ✅ Opérations CRUD génériques
- ✅ Requêtes SQL personnalisées

**Méthodes principales:**
- `insert()` - Insérer un enregistrement
- `query()` / `queryAll()` - Lire des enregistrements
- `update()` - Mettre à jour un enregistrement
- `delete()` - Supprimer un enregistrement
- `rawQuery()` - Exécuter une requête SQL personnalisée

### 2. ExampleModel

Modèle de données avec:
- Propriétés typées
- Méthode `toMap()` pour convertir en Map
- Factory `fromMap()` pour créer depuis un Map
- Méthode `copyWith()` pour créer des copies modifiées

### 3. ExampleRepository

Couche d'abstraction qui:
- Utilise DatabaseHelper pour les opérations
- Convertit les Maps en objets ExampleModel
- Fournit des méthodes métier spécifiques

## 📝 Utilisation

### Créer votre propre table

1. **Définir la table dans DatabaseHelper:**

```dart
// Dans database_helper.dart
static const String tableUsers = 'users';
static const String columnEmail = 'email';
static const String columnAge = 'age';

// Dans _onCreate
await db.execute('''
  CREATE TABLE $tableUsers (
    $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
    $columnName TEXT NOT NULL,
    $columnEmail TEXT UNIQUE NOT NULL,
    $columnAge INTEGER,
    $columnCreatedAt TEXT NOT NULL
  )
''');
```

2. **Créer le modèle:**

```dart
class User {
  int? id;
  String name;
  String email;
  int? age;
  DateTime createdAt;

  User({
    this.id,
    required this.name,
    required this.email,
    this.age,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'age': age,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String,
      age: map['age'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
```

3. **Créer le repository:**

```dart
class UserRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insertUser(User user) async {
    return await _dbHelper.insert(
      DatabaseHelper.tableUsers,
      user.toMap(),
    );
  }

  Future<List<User>> getAllUsers() async {
    final maps = await _dbHelper.queryAll(DatabaseHelper.tableUsers);
    return List.generate(maps.length, (i) => User.fromMap(maps[i]));
  }

  // Autres méthodes...
}
```

### Exemples d'opérations

```dart
// Créer une instance du repository
final repository = ExampleRepository();

// INSERT
final example = ExampleModel(
  name: 'Mon exemple',
  description: 'Description de l\'exemple',
);
int id = await repository.insertExample(example);

// SELECT ALL
List<ExampleModel> examples = await repository.getAllExamples();

// SELECT BY ID
ExampleModel? example = await repository.getExampleById(1);

// SEARCH
List<ExampleModel> results = await repository.searchExamplesByName('exemple');

// UPDATE
example.name = 'Nouveau nom';
await repository.updateExample(example);

// DELETE
await repository.deleteExample(1);

// COUNT
int count = await repository.countExamples();
```

## 🔄 Migrations de Base de Données

Pour ajouter une nouvelle colonne ou modifier le schéma:

```dart
Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    // Migration vers version 2
    await db.execute('ALTER TABLE example_table ADD COLUMN status TEXT');
  }
  if (oldVersion < 3) {
    // Migration vers version 3
    await db.execute('CREATE TABLE new_table (...)');
  }
}
```

N'oubliez pas d'incrémenter `_databaseVersion` dans DatabaseHelper.

## 🎯 Bonnes Pratiques

1. **Utilisez le pattern Repository** pour séparer la logique métier de l'accès aux données
2. **Créez des modèles** avec `toMap()` et `fromMap()` pour faciliter la conversion
3. **Gérez les erreurs** avec try-catch dans vos repositories
4. **Utilisez des transactions** pour les opérations multiples:

```dart
await db.transaction((txn) async {
  await txn.insert('table1', data1);
  await txn.insert('table2', data2);
});
```

5. **Indexez les colonnes** fréquemment recherchées:

```dart
await db.execute('CREATE INDEX idx_name ON example_table(name)');
```

## 🚀 Lancer l'Application

```bash
flutter run
```

L'application de démonstration vous permet de:
- ✅ Ajouter des éléments à la base de données
- ✅ Afficher tous les éléments
- ✅ Supprimer des éléments
- ✅ Voir les dates de création

## 📚 Ressources

- [Documentation Sqflite](https://pub.dev/packages/sqflite)
- [SQL Tutorial](https://www.sqlitetutorial.net/)
- [Flutter Database Guide](https://docs.flutter.dev/cookbook/persistence/sqlite)
