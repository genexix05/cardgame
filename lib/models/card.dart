enum CardRarity { common, uncommon, rare, superRare, ultraRare, legendary }

enum CardType { character, support, event, equipment }

class Card {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final CardRarity rarity;
  final CardType type;
  final Map<String, int> stats;
  final int power;
  final List<String> abilities;
  final List<String> tags;
  final String series;

  // Atributos de combate para cartas de personaje
  final int maxHealth;
  final int attack;
  final int defense;

  const Card({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.rarity,
    required this.type,
    this.stats = const {},
    required this.power,
    this.abilities = const [],
    this.tags = const [],
    required this.series,
    this.maxHealth = 0,
    this.attack = 0,
    this.defense = 0,
  });

  // Convertir desde Map (para Firestore)
  factory Card.fromMap(Map<String, dynamic> map, {String? documentId}) {
    print('\nProcesando carta desde Map:');

    // Usar el ID del documento si está disponible y el ID en los datos está vacío
    String id = map['id'] ?? '';
    if (id.isEmpty && documentId != null && documentId.isNotEmpty) {
      id = documentId;
      print('⚠️ ID de carta vacío o nulo, usando ID del documento: $id');
    }

    if (id.isEmpty) {
      print('⚠️ ID de carta vacío o nulo');

      // Intentar identificar la carta por nombre
      final String name = map['name'] ?? '';
      if (name.isNotEmpty) {
        print('📄 Carta sin ID identificada por nombre: $name');
      }
    } else {
      print('✅ ID de carta válido: $id');
    }

    final String type = map['type'] ?? '';
    print('Tipo de carta encontrado: $type');

    // Procesar la imagen
    String imageUrl = map['imageUrl'] ?? '';

    return Card(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      imageUrl: imageUrl,
      rarity: _parseRarity(map['rarity']),
      type: _parseType(map['type']),
      stats: Map<String, int>.from(map['stats'] ?? {}),
      power: map['power'] ?? 0,
      abilities: List<String>.from(map['abilities'] ?? []),
      tags: List<String>.from(map['tags'] ?? []),
      series: map['series'] ?? '',
      maxHealth: map['maxHealth'] ?? 0,
      attack: map['attack'] ?? 0,
      defense: map['defense'] ?? 0,
    );
  }

  // Convertir a Map (para Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'rarity': rarity.toString().split('.').last,
      'type': type.toString().split('.').last,
      'stats': stats,
      'power': power,
      'abilities': abilities,
      'tags': tags,
      'series': series,
      'maxHealth': maxHealth,
      'attack': attack,
      'defense': defense,
    };
  }

  // Parsear rareza desde string
  static CardRarity _parseRarity(String? rarityStr) {
    if (rarityStr == null) return CardRarity.common;

    switch (rarityStr.toLowerCase()) {
      case 'common':
        return CardRarity.common;
      case 'uncommon':
        return CardRarity.uncommon;
      case 'rare':
        return CardRarity.rare;
      case 'superrare':
      case 'super_rare':
      case 'epic': // Mantener compatibilidad con datos antiguos
        return CardRarity.superRare;
      case 'ultrarare':
      case 'ultra_rare':
        return CardRarity.ultraRare;
      case 'legendary':
        return CardRarity.legendary;
      default:
        return CardRarity.common;
    }
  }

  // Parsear tipo desde string
  static CardType _parseType(String? typeStr) {
    if (typeStr == null) {
      print('⚠️ Tipo de carta nulo, usando valor por defecto: character');
      return CardType.character;
    }

    print('Procesando tipo de carta: $typeStr');
    final normalizedType = typeStr.toLowerCase().trim();

    switch (normalizedType) {
      case 'character':
      case 'personaje':
        print('Tipo identificado como: character');
        return CardType.character;
      case 'support':
      case 'soporte':
        print('Tipo identificado como: support');
        return CardType.support;
      case 'event':
      case 'evento':
        print('Tipo identificado como: event');
        return CardType.event;
      case 'equipment':
      case 'equipamiento':
        print('Tipo identificado como: equipment');
        return CardType.equipment;
      default:
        print(
            '⚠️ Tipo de carta desconocido: $typeStr, usando valor por defecto: character');
        return CardType.character;
    }
  }
}
