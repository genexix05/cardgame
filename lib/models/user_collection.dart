import 'card.dart';

class CardInstance {
  final String cardId;
  final String uniqueInstanceId;
  final DateTime acquiredAt;
  final bool isFavorite;
  final bool isLocked;
  final int level;
  final int experience;
  final bool isForSale; // Indica si la carta está a la venta en el mercado
  final int? salePrice; // Precio de venta si está a la venta
  final int quantity; // Cantidad de esta carta en la colección del usuario

  CardInstance({
    required this.cardId,
    required this.uniqueInstanceId,
    required this.acquiredAt,
    this.isFavorite = false,
    this.isLocked = false,
    this.level = 1,
    this.experience = 0,
    this.isForSale = false,
    this.salePrice,
    this.quantity = 1,
  });

  // Convertir desde Map (para Firestore)
  factory CardInstance.fromMap(Map<String, dynamic> map) {
    return CardInstance(
      cardId: map['cardId'] ?? '',
      uniqueInstanceId: map['uniqueInstanceId'] ?? '',
      acquiredAt: map['acquiredAt'] != null
          ? (map['acquiredAt'] as dynamic).toDate()
          : DateTime.now(),
      isFavorite: map['isFavorite'] ?? false,
      isLocked: map['isLocked'] ?? false,
      level: map['level'] ?? 1,
      experience: map['experience'] ?? 0,
      isForSale: map['isForSale'] ?? false,
      salePrice: map['salePrice'],
      quantity: map['quantity'] ?? 1,
    );
  }

  // Convertir a Map (para Firestore)
  Map<String, dynamic> toMap() {
    return {
      'cardId': cardId,
      'uniqueInstanceId': uniqueInstanceId,
      'acquiredAt': acquiredAt,
      'isFavorite': isFavorite,
      'isLocked': isLocked,
      'level': level,
      'experience': experience,
      'isForSale': isForSale,
      'salePrice': salePrice,
      'quantity': quantity,
    };
  }

  // Crear una copia del objeto con propiedades actualizadas
  CardInstance copyWith({
    bool? isFavorite,
    bool? isLocked,
    int? level,
    int? experience,
    bool? isForSale,
    int? salePrice,
    int? quantity,
  }) {
    return CardInstance(
      cardId: cardId,
      uniqueInstanceId: uniqueInstanceId,
      acquiredAt: acquiredAt,
      isFavorite: isFavorite ?? this.isFavorite,
      isLocked: isLocked ?? this.isLocked,
      level: level ?? this.level,
      experience: experience ?? this.experience,
      isForSale: isForSale ?? this.isForSale,
      salePrice: salePrice ?? this.salePrice,
      quantity: quantity ?? this.quantity,
    );
  }
}

class UserCollection {
  final String userId;
  final Map<String, UserCard>
      cards; // Mapa de cardId -> UserCard para la colección
  final Map<String, int> resources;
  final int totalCards;
  final Map<CardRarity, int> rarityDistribution;
  final int coins; // Moneda común para compras básicas
  final int gems; // Moneda premium para compras especiales
  final DateTime lastUpdated; // Fecha de última actualización

  UserCollection({
    required this.userId,
    Map<String, UserCard>? cards,
    this.resources = const {
      'coins': 0,
      'gems': 0,
    },
    this.totalCards = 0,
    this.rarityDistribution = const {},
    this.coins = 0,
    this.gems = 0,
    DateTime? lastUpdated,
  })  : cards = cards ?? {},
        lastUpdated = lastUpdated ?? DateTime.now();

  // Convertir desde Map (para Firestore)
  factory UserCollection.fromMap(Map<String, dynamic> map) {
    Map<String, UserCard> cardsMap = {};

    if (map['cards'] != null) {
      final cards = map['cards'] as Map<String, dynamic>;
      cards.forEach((cardId, cardData) {
        cardsMap[cardId] = UserCard.fromMap(cardData);
      });
    }

    Map<CardRarity, int> rarityMap = {};
    if (map['rarityDistribution'] != null) {
      map['rarityDistribution'].forEach((key, value) {
        final rarity = _parseRarity(key);
        rarityMap[rarity] = value;
      });
    }

    return UserCollection(
      userId: map['userId'] ?? '',
      cards: cardsMap,
      resources:
          Map<String, int>.from(map['resources'] ?? {'coins': 0, 'gems': 0}),
      totalCards: map['totalCards'] ?? 0,
      rarityDistribution: rarityMap,
      coins: map['coins'] ?? 0,
      gems: map['gems'] ?? 0,
      lastUpdated: map['lastUpdated'] != null
          ? (map['lastUpdated'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  // Convertir a Map (para Firestore)
  Map<String, dynamic> toMap() {
    Map<String, dynamic> cardsMap = {};
    cards.forEach((cardId, card) {
      cardsMap[cardId] = card.toMap();
    });

    Map<String, dynamic> rarityMap = {};
    rarityDistribution.forEach((key, value) {
      rarityMap[key.toString().split('.').last] = value;
    });

    return {
      'userId': userId,
      'cards': cardsMap,
      'resources': resources,
      'totalCards': totalCards,
      'rarityDistribution': rarityMap,
      'coins': coins,
      'gems': gems,
      'lastUpdated': lastUpdated,
    };
  }

  // Añadir una nueva carta a la colección
  UserCollection addCard(String cardId) {
    Map<String, UserCard> updatedCards = Map.from(cards);

    if (updatedCards.containsKey(cardId)) {
      // Si ya tiene la carta, incrementar cantidad
      final existingCard = updatedCards[cardId]!;
      updatedCards[cardId] = existingCard.copyWith(
        quantity: existingCard.quantity + 1,
      );
    } else {
      // Si no tiene la carta, añadirla
      updatedCards[cardId] = UserCard(cardId: cardId);
    }

    // Actualizar la distribución por rareza podría hacerse aquí si se tiene la información de rareza

    return UserCollection(
      userId: userId,
      cards: updatedCards,
      resources: resources,
      totalCards: totalCards + 1,
      rarityDistribution: rarityDistribution,
      coins: coins,
      gems: gems,
      lastUpdated: DateTime.now(),
    );
  }

  // Actualizar recursos
  UserCollection updateResources(String resourceType, int amount) {
    Map<String, int> updatedResources = Map.from(resources);
    updatedResources[resourceType] =
        (updatedResources[resourceType] ?? 0) + amount;

    int updatedCoins = coins;
    int updatedGems = gems;

    // Actualizar también coins o gems directamente para mantener consistencia
    if (resourceType == 'coins') {
      updatedCoins += amount;
    } else if (resourceType == 'gems') {
      updatedGems += amount;
    }

    return UserCollection(
      userId: userId,
      cards: cards,
      resources: updatedResources,
      totalCards: totalCards,
      rarityDistribution: rarityDistribution,
      coins: updatedCoins,
      gems: updatedGems,
      lastUpdated: DateTime.now(),
    );
  }

  // Verificar si el usuario tiene suficientes recursos
  bool hasEnoughResources(String resourceType, int amount) {
    return (resources[resourceType] ?? 0) >= amount;
  }

  // Parsear rareza desde string
  static CardRarity _parseRarity(String rarityStr) {
    switch (rarityStr.toLowerCase()) {
      case 'common':
        return CardRarity.common;
      case 'uncommon':
        return CardRarity.uncommon;
      case 'rare':
        return CardRarity.rare;
      case 'superrare':
      case 'super_rare':
      case 'epic': // Para mantener compatibilidad
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

  // Método para crear una copia con cambios
  UserCollection copyWith({
    Map<String, UserCard>? cards,
    Map<String, int>? resources,
    int? totalCards,
    Map<CardRarity, int>? rarityDistribution,
    int? coins,
    int? gems,
    DateTime? lastUpdated,
  }) {
    return UserCollection(
      userId: userId,
      cards: cards ?? this.cards,
      resources: resources ?? this.resources,
      totalCards: totalCards ?? this.totalCards,
      rarityDistribution: rarityDistribution ?? this.rarityDistribution,
      coins: coins ?? this.coins,
      gems: gems ?? this.gems,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

// Clase para representar una carta en la colección de un usuario
class UserCard {
  final String cardId;
  final int quantity;
  final bool isForSale;
  final int? salePrice;
  final bool isFavorite;

  UserCard({
    required this.cardId,
    this.quantity = 1,
    this.isForSale = false,
    this.salePrice,
    this.isFavorite = false,
  });

  factory UserCard.fromMap(Map<String, dynamic> map) {
    return UserCard(
      cardId: map['cardId'] ?? '',
      quantity: map['quantity'] ?? 1,
      isForSale: map['isForSale'] ?? false,
      salePrice: map['salePrice'],
      isFavorite: map['isFavorite'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cardId': cardId,
      'quantity': quantity,
      'isForSale': isForSale,
      'salePrice': salePrice,
      'isFavorite': isFavorite,
    };
  }

  UserCard copyWith({
    String? cardId,
    int? quantity,
    bool? isForSale,
    int? salePrice,
    bool? isFavorite,
  }) {
    return UserCard(
      cardId: cardId ?? this.cardId,
      quantity: quantity ?? this.quantity,
      isForSale: isForSale ?? this.isForSale,
      salePrice: salePrice ?? this.salePrice,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
