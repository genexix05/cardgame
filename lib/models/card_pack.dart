enum CardPackType { basic, premium, ultra, ultimate, legendary, special }

enum CardPackCurrency { coins, gems }

class CardPack {
  final String id;
  final String name;
  final String imageUrl;
  final String description;
  final CardPackType type;
  final int cardCount;
  int get cardsPerPack => cardCount;
  final int price;
  final CardPackCurrency currency;
  final bool isLimited;
  final bool isAvailable;
  final DateTime? expiresAt;
  final List<String>? seriesFilter; // Filtro de series para sobres temáticos
  final RarityDistribution?
      rarityDistribution; // Distribución de rareza personalizada

  CardPack({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.type,
    required this.cardCount,
    required this.price,
    required this.currency,
    this.isLimited = false,
    this.isAvailable = true,
    this.expiresAt,
    this.seriesFilter,
    this.rarityDistribution,
  });

  // Convertir desde Map (para Firestore)
  factory CardPack.fromMap(Map<String, dynamic> map) {
    return CardPack(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      description: map['description'] ?? '',
      type: _parsePackType(map['type']),
      cardCount: map['cardCount'] ?? 5,
      price: map['price'] ?? 0,
      currency: _parseCurrency(map['currency']),
      isLimited: map['isLimited'] ?? false,
      isAvailable: map['isAvailable'] ?? true,
      expiresAt: map['expiresAt'] != null
          ? (map['expiresAt'] as dynamic).toDate()
          : null,
      seriesFilter: map['seriesFilter'] != null
          ? List<String>.from(map['seriesFilter'])
          : null,
      rarityDistribution: map['rarityDistribution'] != null
          ? RarityDistribution.fromMap(map['rarityDistribution'])
          : null,
    );
  }

  // Convertir a Map (para Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'description': description,
      'type': type.toString().split('.').last,
      'cardCount': cardCount,
      'price': price,
      'currency': currency.toString().split('.').last,
      'isLimited': isLimited,
      'isAvailable': isAvailable,
      'expiresAt': expiresAt,
      'seriesFilter': seriesFilter,
      'rarityDistribution': rarityDistribution?.toMap(),
    };
  }

  // Parsear tipo de sobre desde string
  static CardPackType _parsePackType(String? typeStr) {
    if (typeStr == null) return CardPackType.basic;

    switch (typeStr.toLowerCase()) {
      case 'basic':
        return CardPackType.basic;
      case 'premium':
        return CardPackType.premium;
      case 'ultra':
        return CardPackType.ultra;
      case 'ultimate':
        return CardPackType.ultimate;
      case 'legendary':
        return CardPackType.legendary;
      case 'special':
        return CardPackType.special;
      default:
        return CardPackType.basic;
    }
  }

  // Parsear moneda desde string
  static CardPackCurrency _parseCurrency(String? currencyStr) {
    if (currencyStr == null) return CardPackCurrency.coins;

    switch (currencyStr.toLowerCase()) {
      case 'coins':
        return CardPackCurrency.coins;
      case 'gems':
        return CardPackCurrency.gems;
      default:
        return CardPackCurrency.coins;
    }
  }

  // Método para verificar si el sobre ha expirado
  bool isExpired() {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  // Método para obtener un icono basado en la moneda
  String getCurrencyIcon() {
    return currency == CardPackCurrency.coins ? '🪙' : '💎';
  }

  // Método para obtener el color del sobre según su tipo
  String getPackColor() {
    switch (type) {
      case CardPackType.basic:
        return '#ADADAD'; // Gris
      case CardPackType.premium:
        return '#3BB9FF'; // Azul
      case CardPackType.ultra:
        return '#FF5722'; // Naranja
      case CardPackType.ultimate:
        return '#8E35EF'; // Púrpura
      case CardPackType.legendary:
        return '#FDD017'; // Dorado
      case CardPackType.special:
        return '#E91E63'; // Rosa
      default:
        return '#ADADAD';
    }
  }
}

// Clase para representar la distribución de rarezas en un sobre
class RarityDistribution {
  final double common;
  final double uncommon;
  final double rare;
  final double superRare;
  final double ultraRare;
  final double legendary;

  RarityDistribution({
    this.common = 0.0,
    this.uncommon = 0.0,
    this.rare = 0.0,
    this.superRare = 0.0,
    this.ultraRare = 0.0,
    this.legendary = 0.0,
  });

  factory RarityDistribution.fromMap(Map<String, dynamic> map) {
    return RarityDistribution(
      common: (map['common'] ?? 0.0).toDouble(),
      uncommon: (map['uncommon'] ?? 0.0).toDouble(),
      rare: (map['rare'] ?? 0.0).toDouble(),
      superRare: (map['superRare'] ?? map['super_rare'] ?? map['epic'] ?? 0.0)
          .toDouble(), // Compatibilidad
      ultraRare: (map['ultraRare'] ?? map['ultra_rare'] ?? 0.0)
          .toDouble(), // Compatibilidad
      legendary: (map['legendary'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'common': common,
      'uncommon': uncommon,
      'rare': rare,
      'superRare': superRare,
      'ultraRare': ultraRare,
      'legendary': legendary,
    };
  }
}
