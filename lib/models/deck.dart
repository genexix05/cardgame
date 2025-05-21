import 'card.dart';

class Deck {
  final String id;
  final String name;
  final String userId;
  final List<String> cardIds;
  final DateTime createdAt;
  final DateTime lastModified;

  Deck({
    required this.id,
    required this.name,
    required this.userId,
    required this.cardIds,
    required this.createdAt,
    required this.lastModified,
  });

  // Validar que el mazo cumple con las restricciones
  bool isValid(List<Card> cards) {
    print('Validando mazo con ${cardIds.length} cartas');
    print('IDs de cartas en el mazo: ${cardIds.join(", ")}');
    print('Total de cartas disponibles: ${cards.length}');

    if (cardIds.length != 3) {
      print('❌ El mazo debe tener exactamente 3 cartas');
      return false;
    }

    // Contar cartas por tipo
    Map<CardType, int> typeCount = {};
    for (String cardId in cardIds) {
      try {
        print('Buscando carta con ID: $cardId');
        final matchingCards = cards.where((c) => c.id == cardId).toList();

        if (matchingCards.isEmpty) {
          print('❌ No se encontró la carta con ID: $cardId');
          print('IDs disponibles: ${cards.map((c) => c.id).join(", ")}');
          return false;
        }

        final foundCard = matchingCards.first;
        print('Carta encontrada: ${foundCard.name} (${foundCard.type})');
        typeCount[foundCard.type] = (typeCount[foundCard.type] ?? 0) + 1;
      } catch (e) {
        print('❌ Error al buscar carta: $e');
        return false;
      }
    }

    // Imprimir conteo de tipos
    print('Conteo de tipos:');
    typeCount.forEach((type, count) {
      print('- $type: $count');
    });

    // Verificar restricciones
    bool hasCharacter = typeCount.containsKey(CardType.character);
    int characterCount = typeCount[CardType.character] ?? 0;
    int supportCount = typeCount[CardType.support] ?? 0;
    int equipmentCount = typeCount[CardType.equipment] ?? 0;

    print('Resumen de restricciones:');
    print('- Tiene personaje: $hasCharacter');
    print('- Cantidad de personajes: $characterCount');
    print('- Cantidad de soportes: $supportCount');
    print('- Cantidad de equipamientos: $equipmentCount');

    if (!hasCharacter) {
      print('❌ El mazo debe tener al menos 1 personaje');
      return false;
    }

    if (characterCount > 2) {
      print('❌ El mazo no puede tener más de 2 personajes');
      return false;
    }

    if (supportCount > 2) {
      print('❌ El mazo no puede tener más de 2 soportes');
      return false;
    }

    if (equipmentCount > 2) {
      print('❌ El mazo no puede tener más de 2 equipamientos');
      return false;
    }

    print('✅ El mazo cumple con todas las restricciones');
    return true;
  }

  // Convertir desde Map (para Firestore)
  factory Deck.fromMap(Map<String, dynamic> map) {
    return Deck(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      userId: map['userId'] ?? '',
      cardIds: List<String>.from(map['cardIds'] ?? []),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
      lastModified: map['lastModified'] != null
          ? (map['lastModified'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  // Convertir a Map (para Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'userId': userId,
      'cardIds': cardIds,
      'createdAt': createdAt,
      'lastModified': lastModified,
    };
  }

  // Crear una copia del mazo con modificaciones
  Deck copyWith({
    String? id,
    String? name,
    String? userId,
    List<String>? cardIds,
    DateTime? createdAt,
    DateTime? lastModified,
  }) {
    return Deck(
      id: id ?? this.id,
      name: name ?? this.name,
      userId: userId ?? this.userId,
      cardIds: cardIds ?? this.cardIds,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}
