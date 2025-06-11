import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/card.dart';
import '../models/card_pack.dart';
import '../models/user_collection.dart';
import '../models/deck.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Colecciones de Firestore
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _cardsCollection => _firestore.collection('cards');
  CollectionReference get _packsCollection => _firestore.collection('packs');
  CollectionReference get _marketCollection => _firestore.collection('market');
  CollectionReference get _decksCollection => _firestore.collection('decks');

  // MÉTODOS PARA CARTAS ==================================

  // Obtener todas las cartas
  Future<List<Card>> getAllCards() async {
    try {
      print('🔍 Obteniendo todas las cartas...');
      final querySnapshot = await _cardsCollection.get();
      print('📊 Documentos encontrados: ${querySnapshot.docs.length}');

      final List<Card> cards = [];
      int cardsWithEmptyId = 0;

      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          print('\n📄 Procesando carta:');
          print('- ID del documento: ${doc.id}');

          // Asegurarse de que el ID del documento se incluya en los datos
          if (!data.containsKey('id') || (data['id'] as String).isEmpty) {
            print('- ⚠️ ID en datos ausente o vacío, usando ID del documento');
            data['id'] = doc.id;
          } else if (data['id'] != doc.id) {
            print(
                '- ⚠️ ID en datos (${data['id']}) difiere del ID del documento');
            data['id'] = doc.id; // Forzar el uso del ID del documento
          }

          final card = Card.fromMap(data, documentId: doc.id);

          if (card.id.isEmpty) {
            cardsWithEmptyId++;
            print(
                '- ❌ Error: Carta con ID vacío a pesar de usar ID del documento');
          }

          print(
              '- ✅ Carta procesada: ${card.name} (${card.type}) - ID: ${card.id}');
          
          // Añadir log para verificar los valores de combate
          print('- 🔢 Valores de combate: ATK=${card.attack}, DEF=${card.defense}, HP=${card.maxHealth}');
          // Verificar datos originales
          print('- 📊 Datos originales: health=${data['health']}, attack=${data['attack']}, defense=${data['defense']}');
          
          cards.add(card);
        } catch (e) {
          print('❌ Error al procesar carta ${doc.id}: $e');
        }
      }

      print('\n📋 Resumen:');
      print('- Total de cartas procesadas: ${cards.length}');
      print('- Cartas con ID vacío: $cardsWithEmptyId');

      // Buscar cartas de Goku para depuración
      final gokuCards =
          cards.where((c) => c.name.toUpperCase().contains('GOKU')).toList();

      if (gokuCards.isNotEmpty) {
        print('\n🔎 Cartas de GOKU encontradas:');
        for (final card in gokuCards) {
          print('  - ${card.name} (${card.type}) - ID: "${card.id}"');
        }
      } else {
        print('\n⚠️ No se encontraron cartas de GOKU en la base de datos');
      }

      return cards;
    } catch (e) {
      print('❌ Error al obtener cartas: $e');
      if (e is FirebaseException) {
        print('🔥 Código de error: ${e.code}, Mensaje: ${e.message}');
      }
      rethrow;
    }
  }

  // Obtener carta por ID
  Future<Card?> getCardById(String cardId) async {
    try {
      if (cardId.isEmpty || cardId.trim().isEmpty) {
        print('⚠️ getCardById: Se recibió un ID de carta vacío o inválido');
        return null;
      }

      print('🔍 Buscando carta con ID: $cardId');
      final DocumentSnapshot doc = await _cardsCollection.doc(cardId).get();

      if (doc.exists) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          // Pasar el ID del documento para asegurar que la carta tenga un ID válido
          final card = Card.fromMap(data, documentId: doc.id);
          print('✅ Carta encontrada: ${card.name}');
          return card;
        } catch (parseError) {
          print('⚠️ Error al procesar los datos de la carta: $parseError');
          print('Datos de la carta: ${doc.data()}');
          return null;
        }
      } else {
        print('⚠️ La carta con ID $cardId no existe en la base de datos');
        return null;
      }
    } catch (e) {
      print('Error al obtener carta: $e');
      if (e is FirebaseException) {
        print(
            'Detalles del error Firebase - Código: ${e.code}, Mensaje: ${e.message}');
      }
      return null;
    }
  }

  // Verificar si una carta existe en Firestore
  Future<bool> checkCardExists(String cardId) async {
    try {
      if (cardId.isEmpty || cardId.trim().isEmpty) {
        print('⚠️ checkCardExists: Se recibió un ID de carta vacío o inválido');
        return false;
      }

      print('🔍 Verificando si existe la carta con ID: $cardId');
      final DocumentSnapshot doc = await _cardsCollection.doc(cardId).get();
      return doc.exists;
    } catch (e) {
      print('Error al verificar si existe la carta: $e');
      return false;
    }
  }

  // MÉTODOS PARA SOBRES DE CARTAS =======================

  // Obtener sobres disponibles
  Future<List<CardPack>> getAvailablePacks() async {
    try {
      final QuerySnapshot snapshot =
          await _packsCollection.where('available', isEqualTo: true).get();
      print('Sobres obtenidos: ${snapshot.docs.length}');

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Asegurar que pasamos el ID del documento
        return CardPack.fromMap({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      print('Error al obtener sobres disponibles: $e');
      return [];
    }
  }

  // Obtener las cartas específicas de un pack desde la subcolección 'packCards'
  Future<List<String>> getPackCards(String packId) async {
    try {
      if (packId.isEmpty) {
        print('⚠️ ID de sobre vacío. No se pueden obtener cartas.');
        return [];
      }

      print('🔍 Buscando cartas fijas para el sobre con ID: $packId');
      final QuerySnapshot snapshot = await _packsCollection
          .doc(packId)
          .collection('packCards')
          .orderBy('order')
          .get();

      if (snapshot.docs.isEmpty) {
        print('No se encontraron cartas fijas para el sobre $packId');
        return [];
      }

      // Extraer los IDs de las cartas
      final List<String> cardIds = [];

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final String? cardId = data['cardId'] as String?;

          if (cardId != null && cardId.isNotEmpty) {
            cardIds.add(cardId);
            print('🃏 ID de carta obtenido del sobre: $cardId');
          } else {
            print('⚠️ ID de carta nulo o vacío en el documento ${doc.id}');
          }
        } catch (e) {
          print('⚠️ Error al procesar documento ${doc.id}: $e');
        }
      }

      print('Cartas fijas obtenidas para el sobre $packId: ${cardIds.length}');

      // Verificación adicional
      if (cardIds.isEmpty && snapshot.docs.isNotEmpty) {
        print(
            '⚠️ ADVERTENCIA: Se encontraron ${snapshot.docs.length} documentos pero no se obtuvieron IDs válidos');

        // Mostrar datos crudos para depuración
        for (final doc in snapshot.docs) {
          print('Documento en packCards: ${doc.id}');
          print('Datos: ${doc.data()}');
        }
      }

      return cardIds;
    } catch (e) {
      print('Error al obtener cartas del sobre: $e');
      if (e is FirebaseException) {
        print('Código de error Firebase: ${e.code}, Mensaje: ${e.message}');
      }
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

  // Verificar si una carta específica está disponible en un sobre
  Future<bool> isCardInPack(String cardId, String packId) async {
    try {
      if (cardId.isEmpty || packId.isEmpty) {
        return false;
      }

      print('🔍 Verificando si la carta $cardId está en el sobre $packId');

      final QuerySnapshot snapshot = await _packsCollection
          .doc(packId)
          .collection('packCards')
          .where('cardId', isEqualTo: cardId)
          .get();

      final bool isInPack = snapshot.docs.isNotEmpty;
      print('Resultado: La carta ${isInPack ? 'SÍ' : 'NO'} está en el sobre');

      return isInPack;
    } catch (e) {
      print('Error al verificar si la carta está en el sobre: $e');
      return false;
    }
  }

  // Obtener sobres que contienen una carta específica
  Future<List<CardPack>> getPacksContainingCard(String cardId) async {
    try {
      if (cardId.isEmpty) {
        return [];
      }

      print('🔍 Buscando sobres que contengan la carta $cardId');

      // Obtener todos los sobres disponibles
      final availablePacks = await getAvailablePacks();
      final List<CardPack> packsWithCard = [];

      // Verificar cada sobre para ver si contiene la carta
      for (final pack in availablePacks) {
        final bool containsCard = await isCardInPack(cardId, pack.id);
        if (containsCard) {
          packsWithCard.add(pack);
          print('✅ La carta está disponible en el sobre: ${pack.name}');
        }
      }

      print('Total de sobres que contienen la carta: ${packsWithCard.length}');
      return packsWithCard;
    } catch (e) {
      print('Error al obtener sobres que contienen la carta: $e');
      return [];
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
        // Si el usuario no tiene colección, crear una nueva con todos los campos necesarios
        final newCollection = UserCollection(
          userId: userId,
          coins: 1000, // Monedas iniciales
          gems: 50, // Gemas iniciales
          cards: {}, // Inicializar mapa de cartas vacío
          resources: {'coins': 1000, 'gems': 50}, // Inicializar recursos
          totalCards: 0, // Inicializar contador de cartas
          rarityDistribution: {
            CardRarity.common: 0,
            CardRarity.uncommon: 0,
            CardRarity.rare: 0,
            CardRarity.superRare: 0,
            CardRarity.ultraRare: 0,
            CardRarity.legendary: 0,
          }, // Inicializar distribución de rareza
          lastUpdated: DateTime.now(),
        );

        // Guardar la nueva colección en Firestore
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
      // Agregar logs para depuración
      print(
          'Intentando añadir ${cardIds.length} cartas a la colección del usuario $userId');
      print('IDs de cartas a añadir: $cardIds');

      // Validar que no haya IDs vacíos
      final List<String> validCardIds =
          cardIds.where((id) => id.isNotEmpty).toList();

      if (validCardIds.length != cardIds.length) {
        print(
            '⚠️ Se encontraron ${cardIds.length - validCardIds.length} IDs de cartas inválidos que han sido filtrados');

        // Si todos los IDs son inválidos y había cartas inicialmente
        if (validCardIds.isEmpty && cardIds.isNotEmpty) {
          print(
              '⚠️ Todos los IDs de cartas son inválidos. Solo se descontará el precio del sobre.');
          return await deductPackPrice(userId, packPrice, currency);
        }
      }

      // Si no hay cartas válidas para añadir, simplemente descontar el precio sin añadir cartas
      if (validCardIds.isEmpty) {
        print('No hay cartas válidas para añadir, solo descontando precio');
        return await deductPackPrice(userId, packPrice, currency);
      }

      try {
        return await _firestore.runTransaction((transaction) async {
          // Obtener documento de la colección del usuario
          final DocumentSnapshot userDoc =
              await _usersCollection.doc(userId).get();

          if (!userDoc.exists) {
            print('Usuario no encontrado: $userId');
            throw Exception('Usuario no encontrado');
          }

          print('Documento del usuario obtenido correctamente: $userId');

          // Convertir a UserCollection
          final userCollection = UserCollection.fromMap({
            'userId': userId,
            ...userDoc.data() as Map<String, dynamic>,
          });

          print('Colección del usuario convertida correctamente');
          print(
              'Monedas actuales: ${userCollection.coins}, Gemas actuales: ${userCollection.gems}');

          // Verificar si el usuario puede permitirse el sobre
          if (currency == CardPackCurrency.coins) {
            if (userCollection.coins < packPrice) {
              print(
                  'Usuario no tiene suficientes monedas. Tiene: ${userCollection.coins}, Necesita: $packPrice');
              return false;
            }
          } else {
            if (userCollection.gems < packPrice) {
              print(
                  'Usuario no tiene suficientes gemas. Tiene: ${userCollection.gems}, Necesita: $packPrice');
              return false;
            }
          }

          print('Usuario puede permitirse el sobre. Continuando...');

          // Actualizar las cartas del usuario
          final updatedCards = Map<String, UserCard>.from(userCollection.cards);

          for (final cardId in validCardIds) {
            try {
              if (updatedCards.containsKey(cardId)) {
                // Incrementar cantidad si ya tiene la carta
                final existingCard = updatedCards[cardId]!;
                updatedCards[cardId] = existingCard.copyWith(
                  quantity: existingCard.quantity + 1,
                );
                print('Actualizada cantidad de carta existente: $cardId');
              } else {
                // Añadir nueva carta
                updatedCards[cardId] = UserCard(cardId: cardId);
                print('Añadida nueva carta: $cardId');
              }
            } catch (cardError) {
              print('Error al procesar la carta $cardId: $cardError');
              // Continuar con la siguiente carta en lugar de fallar toda la transacción
            }
          }

          // Actualizar monedas o gemas
          final updatedCoins = currency == CardPackCurrency.coins
              ? userCollection.coins - packPrice
              : userCollection.coins;

          final updatedGems = currency == CardPackCurrency.gems
              ? userCollection.gems - packPrice
              : userCollection.gems;

          print(
              'Monedas actualizadas: $updatedCoins, Gemas actualizadas: $updatedGems');

          // Crear mapa de actualización
          final updateData = {
            'cards':
                updatedCards.map((key, value) => MapEntry(key, value.toMap())),
            'coins': updatedCoins,
            'gems': updatedGems,
            'lastUpdated': FieldValue.serverTimestamp(),
          };

          print(
              'Datos de actualización preparados. Actualizando en Firestore...');

          // Actualizar en Firestore
          transaction.update(_usersCollection.doc(userId), updateData);
          print('Transacción completada correctamente');

          return true;
        });
      } catch (transactionError) {
        print('Error en la transacción: $transactionError');

        // Como alternativa, intentar una actualización simple sin transacción
        print(
            'Intentando actualización simple sin transacción como respaldo...');
        return await _simpleAddCardsToCollection(
            userId, validCardIds, packPrice, currency);
      }
    } catch (e) {
      print('Error al añadir cartas a la colección: $e');
      if (e is FirebaseException) {
        print('Código de error Firebase: ${e.code}, Mensaje: ${e.message}');
      }
      return false;
    }
  }

  // Método alternativo para añadir cartas sin usar transacción
  Future<bool> _simpleAddCardsToCollection(
    String userId,
    List<String> cardIds,
    int packPrice,
    CardPackCurrency currency,
  ) async {
    try {
      // Filtrar IDs vacíos por seguridad
      final List<String> validCardIds =
          cardIds.where((id) => id.isNotEmpty).toList();

      // Obtener documento del usuario
      final DocumentSnapshot userDoc = await _usersCollection.doc(userId).get();

      if (!userDoc.exists) {
        print('Usuario no encontrado en _simpleAddCardsToCollection: $userId');
        return false;
      }

      // Convertir a UserCollection
      final userCollection = UserCollection.fromMap({
        'userId': userId,
        ...userDoc.data() as Map<String, dynamic>,
      });

      // Verificar si puede permitirse el sobre
      if (currency == CardPackCurrency.coins) {
        if (userCollection.coins < packPrice) {
          print(
              'Usuario no tiene suficientes monedas: ${userCollection.coins} < $packPrice');
          return false;
        }
      } else {
        if (userCollection.gems < packPrice) {
          print(
              'Usuario no tiene suficientes gemas: ${userCollection.gems} < $packPrice');
          return false;
        }
      }

      // Actualizar cartas
      final updatedCards = Map<String, UserCard>.from(userCollection.cards);

      for (final cardId in validCardIds) {
        print('Procesando carta en actualización simple: $cardId');
        if (updatedCards.containsKey(cardId)) {
          final existingCard = updatedCards[cardId]!;
          updatedCards[cardId] = existingCard.copyWith(
            quantity: existingCard.quantity + 1,
          );
          print('Actualizada cantidad de carta existente (simple): $cardId');
        } else {
          updatedCards[cardId] = UserCard(cardId: cardId);
          print('Añadida nueva carta (simple): $cardId');
        }
      }

      // Calcular nuevos saldos
      final updatedCoins = currency == CardPackCurrency.coins
          ? userCollection.coins - packPrice
          : userCollection.coins;

      final updatedGems = currency == CardPackCurrency.gems
          ? userCollection.gems - packPrice
          : userCollection.gems;

      try {
        // Actualizar en Firestore en pasos separados para reducir el riesgo de fallo
        // Primero actualizamos monedas/gemas
        await _usersCollection.doc(userId).update({
          'coins': updatedCoins,
          'gems': updatedGems,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        print('Monedas/gemas actualizadas correctamente (simple)');

        // Si no hay cartas válidas, no intentamos actualizar ese campo
        if (validCardIds.isNotEmpty) {
          // Luego actualizamos las cartas
          await _usersCollection.doc(userId).update({
            'cards':
                updatedCards.map((key, value) => MapEntry(key, value.toMap())),
          });
          print('Cartas actualizadas correctamente (simple)');
        } else {
          print(
              'No hay cartas válidas que actualizar, omitiendo actualización de cartas');
        }

        print('Actualización simple completada correctamente');
        return true;
      } catch (updateError) {
        print('Error en actualización del documento: $updateError');
        if (updateError is FirebaseException) {
          print(
              'Código de error Firebase: ${updateError.code}, Mensaje: ${updateError.message}');
        }
        return false;
      }
    } catch (e) {
      print('Error en actualización simple: $e');
      return false;
    }
  }

  // Método auxiliar para solo descontar el precio del sobre sin añadir cartas
  Future<bool> deductPackPrice(
      String userId, int packPrice, CardPackCurrency currency) async {
    try {
      // Obtener documento de la colección del usuario
      final DocumentSnapshot userDoc = await _usersCollection.doc(userId).get();

      if (!userDoc.exists) {
        return false;
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

        // Actualizar monedas
        await _usersCollection.doc(userId).update({
          'coins': userCollection.coins - packPrice,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } else {
        if (userCollection.gems < packPrice) {
          return false;
        }

        // Actualizar gemas
        await _usersCollection.doc(userId).update({
          'gems': userCollection.gems - packPrice,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      return true;
    } catch (e) {
      print('Error al descontar precio del sobre: $e');
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

  // Obtener cartas a la venta con opciones de filtrado
  Future<List<Map<String, dynamic>>> getCardsForSale({
    List<String>? series,
    List<CardRarity>? rarities,
    List<CardType>? types,
    int? minPrice,
    int? maxPrice,
    String? searchQuery,
    int limit = 50,
  }) async {
    try {
      // Comenzar con la consulta base
      Query query = _marketCollection.where('isActive', isEqualTo: true);

      // Añadir límite para no cargar demasiadas cartas
      query = query.limit(limit);

      final QuerySnapshot snapshot = await query.get();

      List<Map<String, dynamic>> cardsForSale = [];

      // Para cada oferta de venta, obtener los detalles de la carta
      for (final doc in snapshot.docs) {
        final marketData = doc.data() as Map<String, dynamic>;
        final String cardId = marketData['cardId'];

        // Obtener detalles de la carta
        final card = await getCardById(cardId);

        if (card != null) {
          final Map<String, dynamic> marketItem = {
            'marketId': doc.id,
            'sellerId': marketData['sellerId'],
            'cardId': cardId,
            'price': marketData['price'],
            'listedDate': marketData['listedDate'],
            'card': card.toMap(),
          };

          // Filtrar después de obtener los datos completos
          bool includeCard = true;

          // Filtrar por series (permitiendo múltiples)
          if (series != null &&
              series.isNotEmpty &&
              !series.contains(card.series)) {
            includeCard = false;
          }

          // Filtrar por rarezas
          if (rarities != null &&
              rarities.isNotEmpty &&
              !rarities.contains(card.rarity)) {
            includeCard = false;
          }

          // Filtrar por tipos
          if (types != null && types.isNotEmpty && !types.contains(card.type)) {
            includeCard = false;
          }

          // Filtrar por precio
          final int price = marketData['price'];
          if (minPrice != null && price < minPrice) {
            includeCard = false;
          }
          if (maxPrice != null && price > maxPrice) {
            includeCard = false;
          }

          // Filtrar por búsqueda de texto
          if (searchQuery != null && searchQuery.isNotEmpty) {
            final String searchLower = searchQuery.toLowerCase();
            final bool matchesName =
                card.name.toLowerCase().contains(searchLower);
            final bool matchesDescription =
                card.description.toLowerCase().contains(searchLower);

            if (!matchesName && !matchesDescription) {
              includeCard = false;
            }
          }

          if (includeCard) {
            cardsForSale.add(marketItem);
          }
        }
      }

      // Ordenar por fecha más reciente primero
      cardsForSale.sort((a, b) {
        final Timestamp aDate = a['listedDate'];
        final Timestamp bDate = b['listedDate'];
        return bDate.compareTo(aDate);
      });

      return cardsForSale;
    } catch (e) {
      print('Error al obtener cartas a la venta: $e');
      return [];
    }
  }

  // Obtener las series disponibles en el mercado
  Future<List<String>> getAvailableSeriesInMarket() async {
    try {
      final QuerySnapshot snapshot =
          await _marketCollection.where('isActive', isEqualTo: true).get();

      final Set<String> seriesSet = {};

      // Recolectar todas las series de las cartas en venta
      for (final doc in snapshot.docs) {
        final marketData = doc.data() as Map<String, dynamic>;
        final String cardId = marketData['cardId'];

        final card = await getCardById(cardId);
        if (card != null && card.series.isNotEmpty) {
          seriesSet.add(card.series);
        }
      }

      final List<String> seriesList = seriesSet.toList();
      seriesList.sort(); // Ordenar alfabéticamente

      return seriesList;
    } catch (e) {
      print('Error al obtener series disponibles: $e');
      return [];
    }
  }

  // Poner carta a la venta
  Future<bool> putCardForSale(String userId, String cardId, int price) async {
    try {
      print('------------ VENTA DE CARTA ------------');
      print(
          'putCardForSale: Iniciando proceso para usuario=$userId, carta=$cardId, precio=$price');

      // Validación más estricta de los parámetros
      if (userId.isEmpty) {
        print('putCardForSale: Error - ID de usuario vacío');
        return false;
      }

      if (cardId.isEmpty) {
        print('putCardForSale: Error - ID de carta vacío');
        return false;
      }

      if (price <= 0) {
        print('putCardForSale: Error - Precio no válido ($price)');
        return false;
      }

      print('putCardForSale: Validación básica de parámetros superada');

      // Verificar si el usuario existe antes de iniciar la transacción
      print('putCardForSale: Verificando existencia del usuario...');
      final userDoc = await _usersCollection.doc(userId).get();

      if (!userDoc.exists) {
        print('putCardForSale: Error - Usuario no encontrado');
        return false;
      }

      print('putCardForSale: Usuario encontrado, verificando carta...');

      // Convertir a UserCollection para validación previa
      final preCheckCollection = UserCollection.fromMap({
        'userId': userId,
        ...userDoc.data() as Map<String, dynamic>,
      });

      // Verificar si el usuario tiene la carta
      if (!preCheckCollection.cards.containsKey(cardId)) {
        print(
            'putCardForSale: Error - Usuario no tiene la carta en su colección');
        print(
            'putCardForSale: IDs de cartas en la colección: ${preCheckCollection.cards.keys.toList()}');
        return false;
      }

      // Obtener la carta actual
      final preCheckCard = preCheckCollection.cards[cardId];
      print(
          'putCardForSale: Carta encontrada en la colección, cantidad=${preCheckCard?.quantity}, isForSale=${preCheckCard?.isForSale}');

      // Verificar que la carta no esté ya a la venta
      if (preCheckCard?.isForSale ?? false) {
        print('putCardForSale: Error - La carta ya está a la venta');
        return false;
      }

      // Asegurarse de que tiene al menos una carta para vender
      if ((preCheckCard?.quantity ?? 0) < 1) {
        print(
            'putCardForSale: Error - No hay copias de la carta para vender (cantidad=${preCheckCard?.quantity})');
        return false;
      }

      // Si todas las validaciones previas pasaron, iniciar la transacción
      print(
          'putCardForSale: Todas las validaciones pasadas. Iniciando transacción de Firestore');

      return await _firestore.runTransaction((transaction) async {
        // Obtener documento de la colección del usuario nuevamente
        final userDoc = await transaction.get(_usersCollection.doc(userId));

        if (!userDoc.exists) {
          print('putCardForSale: Error - Usuario no encontrado en transacción');
          throw Exception('Usuario no encontrado');
        }

        print('putCardForSale: Documento del usuario obtenido en transacción');

        // Convertir a UserCollection
        final userCollection = UserCollection.fromMap({
          'userId': userId,
          ...userDoc.data() as Map<String, dynamic>,
        });

        print(
            'putCardForSale: Detalles de la colección en transacción: ${userCollection.cards.length} cartas');

        // Verificar si el usuario tiene la carta
        if (!userCollection.cards.containsKey(cardId)) {
          print(
              'putCardForSale: Error en transacción - Usuario no tiene la carta');
          return false;
        }

        // Obtener la carta actual
        final currentCard = userCollection.cards[cardId];
        print(
            'putCardForSale: Carta en transacción - cantidad: ${currentCard?.quantity}, isForSale: ${currentCard?.isForSale}');

        // Verificar que la carta no esté ya a la venta
        if (currentCard?.isForSale ?? false) {
          print(
              'putCardForSale: Error en transacción - La carta ya está a la venta');
          return false;
        }

        // Asegurarse de que tiene al menos una carta para vender
        if ((currentCard?.quantity ?? 0) < 1) {
          print(
              'putCardForSale: Error en transacción - No hay copias para vender (cantidad=${currentCard?.quantity})');
          return false;
        }

        // Actualizar la carta para marcarla como en venta
        final updatedCard = currentCard?.copyWith(
          isForSale: true,
          salePrice: price,
        );

        if (updatedCard == null) {
          print(
              'putCardForSale: Error en transacción - No se pudo actualizar la carta');
          return false;
        }

        print('putCardForSale: Carta actualizada correctamente en memoria');

        // Actualizar las cartas del usuario
        final updatedCards = Map<String, UserCard>.from(userCollection.cards);
        updatedCards[cardId] = updatedCard;

        // Añadir la carta al mercado
        final marketRef = _marketCollection.doc();

        print(
            'putCardForSale: Añadiendo carta al mercado con ID=${marketRef.id}');

        // Preparar los datos del mercado
        final marketData = {
          'sellerId': userId,
          'cardId': cardId,
          'price': price,
          'isActive': true,
          'listedDate': Timestamp.now(),
        };

        // Registrar para depuración
        print('putCardForSale: Datos del mercado: $marketData');

        // Añadir al mercado
        transaction.set(marketRef, marketData);

        // Actualizar en Firestore - preparar los datos
        final updateData = {
          'cards':
              updatedCards.map((key, value) => MapEntry(key, value.toMap())),
        };

        print('putCardForSale: Actualizando colección del usuario');
        print(
            'putCardForSale: Cantidad de cartas a actualizar: ${updatedCards.length}');

        // Actualizar en Firestore
        transaction.update(_usersCollection.doc(userId), updateData);

        print('putCardForSale: Transacción completada con éxito');
        print('------------ FIN VENTA DE CARTA ------------');
        return true;
      });
    } catch (e) {
      print('Error al poner carta a la venta: $e');

      // Detallar mejor el error si es de Firebase
      if (e is Exception) {
        print('Excepción: ${e.toString()}');
      }

      print('------------ ERROR EN VENTA DE CARTA ------------');
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

  // MÉTODOS PARA MAZOS ==================================

  // Obtener todos los mazos de un usuario
  Future<List<Deck>> getUserDecks(String userId) async {
    try {
      final QuerySnapshot snapshot = await _decksCollection
          .where('userId', isEqualTo: userId)
          .orderBy('lastModified', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Deck.fromMap({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      print('Error al obtener mazos del usuario: $e');
      return [];
    }
  }

  // Crear un nuevo mazo
  Future<Deck?> createDeck(
      String userId, String name, List<String> cardIds) async {
    try {
      if (userId.isEmpty) {
        throw Exception('El ID del usuario no puede estar vacío');
      }
      if (name.isEmpty) {
        throw Exception('El nombre del mazo no puede estar vacío');
      }
      if (cardIds.isEmpty) {
        throw Exception('El mazo debe contener al menos una carta');
      }

      print('Creando mazo:');
      print('- Nombre: $name');
      print('- IDs de cartas: ${cardIds.join(", ")}');

      // Obtener las cartas para validar el mazo
      final List<Card> cards = await getAllCards();
      print('Cartas obtenidas: ${cards.length}');

      // Imprimir detalles de cada carta
      print('\nDetalles de las cartas disponibles:');
      for (var card in cards) {
        print('Carta: ${card.name}');
        print('- ID: ${card.id}');
        print('- Tipo: ${card.type}');
        print('- Rareza: ${card.rarity}');
        print('---');
      }

      // Verificar que todas las cartas existen
      for (String cardId in cardIds) {
        if (!cards.any((card) => card.id == cardId)) {
          throw Exception('No se encontró la carta con ID: $cardId');
        }
      }

      final deck = Deck(
        id: '',
        name: name,
        userId: userId,
        cardIds: cardIds,
        createdAt: DateTime.now(),
        lastModified: DateTime.now(),
      );

      if (!deck.isValid(cards)) {
        throw Exception('El mazo no cumple con las restricciones');
      }

      print('Mazo válido, guardando en Firestore...');
      final docRef = await _decksCollection.add(deck.toMap());
      print('Mazo guardado con ID: ${docRef.id}');

      return deck.copyWith(id: docRef.id);
    } catch (e) {
      print('Error al crear mazo: $e');
      rethrow;
    }
  }

  // Actualizar un mazo existente
  Future<bool> updateDeck(Deck deck) async {
    try {
      await _decksCollection.doc(deck.id).update(deck.toMap());
      return true;
    } catch (e) {
      print('Error al actualizar mazo: $e');
      return false;
    }
  }

  // Eliminar un mazo
  Future<bool> deleteDeck(String deckId) async {
    try {
      await _decksCollection.doc(deckId).delete();
      return true;
    } catch (e) {
      print('Error al eliminar mazo: $e');
      return false;
    }
  }

  // Obtener un mazo por ID
  Future<Deck?> getDeckById(String deckId) async {
    try {
      final DocumentSnapshot doc = await _decksCollection.doc(deckId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return Deck.fromMap({...data, 'id': doc.id});
      }
      return null;
    } catch (e) {
      print('Error al obtener mazo: $e');
      return null;
    }
  }

  // Añadir una nueva carta a Firestore
  Future<String?> addNewCard(Map<String, dynamic> cardData) async {
    try {
      print('🆕 Añadiendo nueva carta a Firestore:');
      print('- Nombre: ${cardData['name']}');
      print('- Tipo: ${cardData['type']}');

      // Validar datos mínimos
      if (cardData['name'] == null || (cardData['name'] as String).isEmpty) {
        print('❌ Error: El nombre de la carta es obligatorio');
        return null;
      }

      // Crear un nuevo documento en la colección de cartas
      final docRef = _cardsCollection.doc();

      // Asignar el ID del documento a los datos de la carta
      cardData['id'] = docRef.id;

      // Guardar la carta en Firestore
      await docRef.set(cardData);

      print('✅ Carta creada correctamente con ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error al crear nueva carta: $e');
      return null;
    }
  }

  // Obtener cartas por consulta de texto (nombre o series)
  Future<List<Card>> getCardsByQuery(String query) async {
    try {
      print('🔍 Buscando cartas relacionadas con: "$query"');
      final querySnapshot = await _cardsCollection.get();

      final List<Card> allCards = [];
      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id; // Asegurar que el ID del documento se incluya
          final card = Card.fromMap(data, documentId: doc.id);
          allCards.add(card);
        } catch (e) {
          print('Error al procesar carta ${doc.id}: $e');
        }
      }

      // Filtrar cartas que coincidan con la consulta
      final filteredCards = allCards.where((card) {
        final nameMatch = card.name.toLowerCase().contains(query.toLowerCase());
        final seriesMatch =
            card.series.toLowerCase().contains(query.toLowerCase());
        return nameMatch || seriesMatch;
      }).toList();

      print(
          '📊 Encontradas ${filteredCards.length} cartas relacionadas con "$query"');

      if (filteredCards.isNotEmpty) {
        print('Ejemplos de cartas encontradas:');
        final limit = filteredCards.length > 5 ? 5 : filteredCards.length;
        for (int i = 0; i < limit; i++) {
          print(
              '- ${filteredCards[i].name} (${filteredCards[i].type}) ID: ${filteredCards[i].id}');
        }
      }

      // Ordenar por nombre
      filteredCards.sort((a, b) => a.name.compareTo(b.name));

      return filteredCards;
    } catch (e) {
      print('Error al buscar cartas por consulta: $e');
      return [];
    }
  }
}
