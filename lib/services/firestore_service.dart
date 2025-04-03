import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/card.dart';
import '../models/card_pack.dart';
import '../models/user_collection.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Colecciones de Firestore
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _cardsCollection => _firestore.collection('cards');
  CollectionReference get _packsCollection => _firestore.collection('packs');
  CollectionReference get _marketCollection => _firestore.collection('market');

  // MÉTODOS PARA CARTAS ==================================

  // Obtener todas las cartas
  Future<List<Card>> getAllCards() async {
    try {
      final QuerySnapshot snapshot = await _cardsCollection.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Card.fromMap(data);
      }).toList();
    } catch (e) {
      print('Error al obtener cartas: $e');
      return [];
    }
  }

  // Obtener carta por ID
  Future<Card?> getCardById(String cardId) async {
    try {
      final DocumentSnapshot doc = await _cardsCollection.doc(cardId).get();
      if (doc.exists) {
        return Card.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error al obtener carta: $e');
      return null;
    }
  }

  // MÉTODOS PARA SOBRES DE CARTAS =======================

  // Obtener sobres disponibles
  Future<List<CardPack>> getAvailablePacks() async {
    try {
      final QuerySnapshot snapshot =
          await _packsCollection.where('isAvailable', isEqualTo: true).get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return CardPack.fromMap(data);
      }).toList();
    } catch (e) {
      print('Error al obtener sobres disponibles: $e');
      return [];
    }
  }

  // Verificar si el usuario puede permitirse un sobre
  Future<bool> canUserAffordPack(String userId, CardPack pack) async {
    try {
      final collection = await getUserCollection(userId);
      if (collection == null) return false;

      if (pack.currency == CardPackCurrency.coins) {
        return collection.coins >= pack.price;
      } else {
        return collection.gems >= pack.price;
      }
    } catch (e) {
      print('Error al verificar si el usuario puede permitirse un sobre: $e');
      return false;
    }
  }

  // Verificar si el usuario ha comprado un sobre limitado
  Future<bool> hasUserPurchasedLimitedPack(String userId, String packId) async {
    try {
      final DocumentSnapshot doc = await _usersCollection
          .doc(userId)
          .collection('purchasedPacks')
          .doc(packId)
          .get();

      return doc.exists;
    } catch (e) {
      print('Error al verificar compra de sobre limitado: $e');
      return false;
    }
  }

  // Registrar la apertura de un sobre
  Future<void> recordPackOpening(String userId, String packId,
      List<String> cardIds, DateTime timestamp) async {
    try {
      await _usersCollection.doc(userId).collection('packOpenings').add({
        'packId': packId,
        'cardIds': cardIds,
        'timestamp': timestamp,
      });
    } catch (e) {
      print('Error al registrar apertura de sobre: $e');
      rethrow;
    }
  }

  // MÉTODOS PARA COLECCIÓN DE USUARIO ===================

  // Obtener colección del usuario
  Future<UserCollection?> getUserCollection(String userId) async {
    try {
      final DocumentSnapshot doc = await _usersCollection.doc(userId).get();

      if (doc.exists) {
        return UserCollection.fromMap({
          'userId': userId,
          ...doc.data() as Map<String, dynamic>,
        });
      } else {
        // Si el usuario no tiene colección, crear una nueva
        final newCollection = UserCollection(
          userId: userId,
          coins: 1000, // Monedas iniciales
          gems: 50, // Gemas iniciales
        );

        await _usersCollection.doc(userId).set(newCollection.toMap());
        return newCollection;
      }
    } catch (e) {
      print('Error al obtener colección de usuario: $e');
      return null;
    }
  }

  // Actualizar colección del usuario
  Future<bool> updateUserCollection(
      String userId, UserCollection collection) async {
    try {
      // Convertir la colección a un Map
      final Map<String, dynamic> collectionData = collection.toMap();

      // Actualizar en Firestore
      await _usersCollection.doc(userId).update(collectionData);

      return true;
    } catch (e) {
      print('Error al actualizar colección de usuario: $e');
      return false;
    }
  }

  // Añadir cartas a la colección del usuario
  Future<bool> addCardsToUserCollection(
    String userId,
    List<String> cardIds,
    int packPrice,
    CardPackCurrency currency,
  ) async {
    try {
      return await _firestore.runTransaction((transaction) async {
        // Obtener documento de la colección del usuario
        final DocumentSnapshot userDoc =
            await _usersCollection.doc(userId).get();

        if (!userDoc.exists) {
          throw Exception('Usuario no encontrado');
        }

        // Convertir a UserCollection
        final userCollection = UserCollection.fromMap({
          'userId': userId,
          ...userDoc.data() as Map<String, dynamic>,
        });

        // Verificar si el usuario puede permitirse el sobre
        if (currency == CardPackCurrency.coins) {
          if (userCollection.coins < packPrice) {
            return false;
          }
        } else {
          if (userCollection.gems < packPrice) {
            return false;
          }
        }

        // Actualizar las cartas del usuario
        final updatedCards = Map<String, UserCard>.from(userCollection.cards);

        for (final cardId in cardIds) {
          if (updatedCards.containsKey(cardId)) {
            // Incrementar cantidad si ya tiene la carta
            final existingCard = updatedCards[cardId]!;
            updatedCards[cardId] = existingCard.copyWith(
              quantity: existingCard.quantity + 1,
            );
          } else {
            // Añadir nueva carta
            updatedCards[cardId] = UserCard(cardId: cardId);
          }
        }

        // Actualizar monedas o gemas
        final updatedCoins = currency == CardPackCurrency.coins
            ? userCollection.coins - packPrice
            : userCollection.coins;

        final updatedGems = currency == CardPackCurrency.gems
            ? userCollection.gems - packPrice
            : userCollection.gems;

        // Actualizar en Firestore
        transaction.update(_usersCollection.doc(userId), {
          'cards':
              updatedCards.map((key, value) => MapEntry(key, value.toMap())),
          'coins': updatedCoins,
          'gems': updatedGems,
        });

        return true;
      });
    } catch (e) {
      print('Error al añadir cartas a la colección: $e');
      return false;
    }
  }

  // Marcar/desmarcar carta como favorita
  Future<UserCollection?> toggleCardFavorite(
      String userId, String cardId) async {
    try {
      return await _firestore.runTransaction((transaction) async {
        // Obtener documento de la colección del usuario
        final DocumentSnapshot userDoc =
            await _usersCollection.doc(userId).get();

        if (!userDoc.exists) {
          throw Exception('Usuario no encontrado');
        }

        // Convertir a UserCollection
        final userCollection = UserCollection.fromMap({
          'userId': userId,
          ...userDoc.data() as Map<String, dynamic>,
        });

        // Verificar si el usuario tiene la carta
        if (!userCollection.cards.containsKey(cardId)) {
          return null;
        }

        // Obtener la carta actual
        final currentCard = userCollection.cards[cardId];

        // Invertir el estado de favorito
        final updatedCard = currentCard?.copyWith(
          isFavorite: !currentCard.isFavorite,
        );

        // Actualizar las cartas del usuario
        final updatedCards = Map<String, UserCard>.from(userCollection.cards);
        updatedCards[cardId] = updatedCard!;

        // Actualizar en Firestore
        transaction.update(_usersCollection.doc(userId), {
          'cards':
              updatedCards.map((key, value) => MapEntry(key, value.toMap())),
        });

        // Devolver la colección actualizada
        return userCollection.copyWith(cards: updatedCards);
      });
    } catch (e) {
      print('Error al marcar carta como favorita: $e');
      return null;
    }
  }

  // MÉTODOS PARA MERCADO DE CARTAS ======================

  // Obtener cartas a la venta
  Future<List<Map<String, dynamic>>> getCardsForSale() async {
    try {
      final QuerySnapshot snapshot =
          await _marketCollection.where('isActive', isEqualTo: true).get();

      final List<Map<String, dynamic>> cardsForSale = [];

      // Para cada oferta de venta, obtener los detalles de la carta
      for (final doc in snapshot.docs) {
        final marketData = doc.data() as Map<String, dynamic>;
        final String cardId = marketData['cardId'];

        // Obtener detalles de la carta
        final card = await getCardById(cardId);

        if (card != null) {
          cardsForSale.add({
            'marketId': doc.id,
            'sellerId': marketData['sellerId'],
            'cardId': cardId,
            'price': marketData['price'],
            'listedDate': marketData['listedDate'],
            'card': card.toMap(),
          });
        }
      }

      return cardsForSale;
    } catch (e) {
      print('Error al obtener cartas a la venta: $e');
      return [];
    }
  }

  // Poner carta a la venta
  Future<bool> putCardForSale(String userId, String cardId, int price) async {
    try {
      return await _firestore.runTransaction((transaction) async {
        // Obtener documento de la colección del usuario
        final DocumentSnapshot userDoc =
            await _usersCollection.doc(userId).get();

        if (!userDoc.exists) {
          throw Exception('Usuario no encontrado');
        }

        // Convertir a UserCollection
        final userCollection = UserCollection.fromMap({
          'userId': userId,
          ...userDoc.data() as Map<String, dynamic>,
        });

        // Verificar si el usuario tiene la carta
        if (!userCollection.cards.containsKey(cardId)) {
          return false;
        }

        // Obtener la carta actual
        final currentCard = userCollection.cards[cardId];

        // Verificar que la carta no esté ya a la venta
        if (currentCard?.isForSale ?? false) {
          return false;
        }

        // Asegurarse de que tiene al menos una carta para uso personal
        if ((currentCard?.quantity ?? 0) <= 1) {
          return false;
        }

        // Actualizar la carta para marcarla como en venta
        final updatedCard = currentCard?.copyWith(
          isForSale: true,
          salePrice: price,
        );

        // Actualizar las cartas del usuario
        final updatedCards = Map<String, UserCard>.from(userCollection.cards);
        updatedCards[cardId] = updatedCard!;

        // Añadir la carta al mercado
        final marketRef = _marketCollection.doc();
        transaction.set(marketRef, {
          'sellerId': userId,
          'cardId': cardId,
          'price': price,
          'isActive': true,
          'listedDate': Timestamp.now(),
        });

        // Actualizar en Firestore
        transaction.update(_usersCollection.doc(userId), {
          'cards':
              updatedCards.map((key, value) => MapEntry(key, value.toMap())),
        });

        return true;
      });
    } catch (e) {
      print('Error al poner carta a la venta: $e');
      return false;
    }
  }

  // Cancelar venta de carta
  Future<bool> cancelCardSale(String userId, String cardId) async {
    try {
      return await _firestore.runTransaction((transaction) async {
        // Obtener documento de la colección del usuario
        final DocumentSnapshot userDoc =
            await _usersCollection.doc(userId).get();

        if (!userDoc.exists) {
          throw Exception('Usuario no encontrado');
        }

        // Convertir a UserCollection
        final userCollection = UserCollection.fromMap({
          'userId': userId,
          ...userDoc.data() as Map<String, dynamic>,
        });

        // Verificar si el usuario tiene la carta
        if (!userCollection.cards.containsKey(cardId)) {
          return false;
        }

        // Obtener la carta actual
        final currentCard = userCollection.cards[cardId];

        // Verificar que la carta esté a la venta
        if (!(currentCard?.isForSale ?? false)) {
          return false;
        }

        // Obtener la oferta del mercado
        final QuerySnapshot marketDocs = await _marketCollection
            .where('sellerId', isEqualTo: userId)
            .where('cardId', isEqualTo: cardId)
            .where('isActive', isEqualTo: true)
            .get();

        if (marketDocs.docs.isEmpty) {
          return false;
        }

        // Actualizar la carta para cancelar la venta
        final updatedCard = currentCard!.copyWith(
          isForSale: false,
          salePrice: null,
        );

        // Actualizar las cartas del usuario
        final updatedCards = Map<String, UserCard>.from(userCollection.cards);
        updatedCards[cardId] = updatedCard;

        // Eliminar la oferta del mercado
        for (final doc in marketDocs.docs) {
          transaction.update(doc.reference, {
            'isActive': false,
          });
        }

        // Actualizar en Firestore
        transaction.update(_usersCollection.doc(userId), {
          'cards':
              updatedCards.map((key, value) => MapEntry(key, value.toMap())),
        });

        return true;
      });
    } catch (e) {
      print('Error al cancelar venta: $e');
      return false;
    }
  }

  // Comprar carta
  Future<bool> buyCard(String buyerId, String marketId) async {
    try {
      return await _firestore.runTransaction((transaction) async {
        // Obtener oferta del mercado
        final DocumentSnapshot marketDoc =
            await _marketCollection.doc(marketId).get();

        if (!marketDoc.exists ||
            !(marketDoc.data() as Map<String, dynamic>)['isActive']) {
          return false;
        }

        final marketData = marketDoc.data() as Map<String, dynamic>;
        final String sellerId = marketData['sellerId'];
        final String cardId = marketData['cardId'];
        final int price = marketData['price'];

        // Evitar que un usuario compre su propia carta
        if (sellerId == buyerId) {
          return false;
        }

        // Obtener colección del comprador
        final DocumentSnapshot buyerDoc =
            await _usersCollection.doc(buyerId).get();

        if (!buyerDoc.exists) {
          return false;
        }

        final buyerCollection = UserCollection.fromMap({
          'userId': buyerId,
          ...buyerDoc.data() as Map<String, dynamic>,
        });

        // Verificar si el comprador tiene suficientes monedas
        if (buyerCollection.coins < price) {
          return false;
        }

        // Obtener colección del vendedor
        final DocumentSnapshot sellerDoc =
            await _usersCollection.doc(sellerId).get();

        if (!sellerDoc.exists) {
          return false;
        }

        final sellerCollection = UserCollection.fromMap({
          'userId': sellerId,
          ...sellerDoc.data() as Map<String, dynamic>,
        });

        // Verificar si el vendedor todavía tiene la carta
        if (!sellerCollection.cards.containsKey(cardId)) {
          return false;
        }

        // Obtener la carta del vendedor
        final sellerCard = sellerCollection.cards[cardId];

        // Verificar que la carta esté a la venta
        if (!sellerCard!.isForSale) {
          return false;
        }

        // Actualizar carta del vendedor
        final updatedSellerCards =
            Map<String, UserCard>.from(sellerCollection.cards);

        if (sellerCard.quantity > 1) {
          // Si tiene más de una, reducir la cantidad
          updatedSellerCards[cardId] = sellerCard.copyWith(
            quantity: sellerCard.quantity - 1,
          );
        } else {
          // Si solo tiene una, eliminarla de su colección
          updatedSellerCards.remove(cardId);
        }

        // Actualizar carta del comprador
        final updatedBuyerCards =
            Map<String, UserCard>.from(buyerCollection.cards);

        if (updatedBuyerCards.containsKey(cardId)) {
          // Si ya tiene la carta, incrementar cantidad
          final buyerCard = updatedBuyerCards[cardId]!;
          updatedBuyerCards[cardId] = buyerCard.copyWith(
            quantity: buyerCard.quantity + 1,
          );
        } else {
          // Si no tiene la carta, añadirla
          updatedBuyerCards[cardId] = UserCard(cardId: cardId);
        }

        // Transferir monedas
        final updatedBuyerCoins = buyerCollection.coins - price;
        final updatedSellerCoins = sellerCollection.coins + price;

        // Desactivar oferta del mercado
        transaction.update(_marketCollection.doc(marketId), {
          'isActive': false,
          'soldDate': Timestamp.now(),
          'buyerId': buyerId,
        });

        // Actualizar vendedor
        transaction.update(_usersCollection.doc(sellerId), {
          'cards': updatedSellerCards
              .map((key, value) => MapEntry(key, value.toMap())),
          'coins': updatedSellerCoins,
        });

        // Actualizar comprador
        transaction.update(_usersCollection.doc(buyerId), {
          'cards': updatedBuyerCards
              .map((key, value) => MapEntry(key, value.toMap())),
          'coins': updatedBuyerCoins,
        });

        return true;
      });
    } catch (e) {
      print('Error al comprar carta: $e');
      return false;
    }
  }
}
