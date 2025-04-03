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
  final String
      series; // Para agrupar cartas por sagas (Freezer, Cell, Majin Buu, etc.)

  Card({
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
  });

  // Convertir desde Map (para Firestore)
  factory Card.fromMap(Map<String, dynamic> map) {
    return Card(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      rarity: _parseRarity(map['rarity']),
      type: _parseType(map['type']),
      stats: Map<String, int>.from(map['stats'] ?? {}),
      power: map['power'] ?? 0,
      abilities: List<String>.from(map['abilities'] ?? []),
      tags: List<String>.from(map['tags'] ?? []),
      series: map['series'] ?? '',
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
    if (typeStr == null) return CardType.character;

    switch (typeStr.toLowerCase()) {
      case 'character':
        return CardType.character;
      case 'support':
        return CardType.support;
      case 'event':
        return CardType.event;
      case 'equipment':
        return CardType.equipment;
      default:
        return CardType.character;
    }
  }
}
