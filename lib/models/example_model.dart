class ExampleModel {
  int? id;
  String name;
  String? description;
  DateTime createdAt;

  ExampleModel({
    this.id,
    required this.name,
    this.description,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convertir un objet en Map pour l'insertion dans la base de données
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Créer un objet à partir d'un Map (lecture depuis la base de données)
  factory ExampleModel.fromMap(Map<String, dynamic> map) {
    return ExampleModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // Copier l'objet avec des modifications
  ExampleModel copyWith({
    int? id,
    String? name,
    String? description,
    DateTime? createdAt,
  }) {
    return ExampleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'ExampleModel{id: $id, name: $name, description: $description, createdAt: $createdAt}';
  }
}
