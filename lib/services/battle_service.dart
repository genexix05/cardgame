import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/battle.dart';
import '../models/card.dart';
import '../models/battle_card.dart';
import '../models/deck.dart';

class BattleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'battles';
  final String _matchmakingCollection = 'matchmaking';

  // Crear una nueva batalla
  Future<Battle> createBattle({
    required String player1Id,
    required String player2Id,
    required Deck player1Deck,
    required Deck player2Deck,
    required List<Card> player1Cards,
    required List<Card> player2Cards,
  }) async {
    // Convertir las cartas a BattleCards
    final player1BattleCards =
        player1Cards.map((card) => BattleCard.fromCard(card)).toList();
    final player2BattleCards =
        player2Cards.map((card) => BattleCard.fromCard(card)).toList();

    final battle = Battle(
      id: _firestore.collection(_collection).doc().id,
      player1Id: player1Id,
      player2Id: player2Id,
      player1Deck: player1Deck,
      player2Deck: player2Deck,
      player1Cards: player1BattleCards,
      player2Cards: player2BattleCards,
      currentTurnPlayerId: player1Id,
    );

    // Optimizar los datos para reducir el tamaño
    final optimizedBattleData = _optimizeBattleData(battle);

    // Guardar los datos optimizados
    await _firestore
        .collection(_collection)
        .doc(battle.id)
        .set(optimizedBattleData);

    return battle;
  }

  // Optimizar los datos de la batalla para reducir su tamaño
  Map<String, dynamic> _optimizeBattleData(Battle battle) {
    // Extraer solo los IDs de las cartas y sus estados de batalla
    final optimizedPlayer1Cards = battle.player1Cards
        .map((card) => {
              'id': card.baseCard.id,
              'currentHealth': card.currentHealth,
              'currentAttack': card.currentAttack,
              'currentDefense': card.currentDefense,
            })
        .toList();

    final optimizedPlayer2Cards = battle.player2Cards
        .map((card) => {
              'id': card.baseCard.id,
              'currentHealth': card.currentHealth,
              'currentAttack': card.currentAttack,
              'currentDefense': card.currentDefense,
            })
        .toList();

    // Crear un objeto optimizado con solo los datos esenciales
    return {
      'id': battle.id,
      'player1Id': battle.player1Id,
      'player2Id': battle.player2Id,
      'player1DeckId': battle.player1Deck.id,
      'player2DeckId': battle.player2Deck.id,
      'player1CardIds': optimizedPlayer1Cards,
      'player2CardIds': optimizedPlayer2Cards,
      'state': battle.state.toString().split('.').last,
      'currentTurnPlayerId': battle.currentTurnPlayerId,
      'lastActions': battle.lastActions.map(
        (key, value) => MapEntry(key, value.toString().split('.').last),
      ),
      'winnerId': battle.winnerId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // Obtener una batalla por ID
  Future<Battle?> getBattle(String battleId) async {
    final doc = await _firestore.collection(_collection).doc(battleId).get();
    if (!doc.exists) return null;

    final data = doc.data()!;

    // Reconstruir la batalla completa a partir de los datos optimizados
    return _reconstructBattle(data, battleId);
  }

  // Reconstruir el objeto Battle completo a partir de los datos optimizados
  Future<Battle?> _reconstructBattle(
      Map<String, dynamic> data, String battleId) async {
    try {
      // Obtener los mazos
      final player1DeckDoc =
          await _firestore.collection('decks').doc(data['player1DeckId']).get();
      final player2DeckDoc =
          await _firestore.collection('decks').doc(data['player2DeckId']).get();

      if (!player1DeckDoc.exists || !player2DeckDoc.exists) {
        print(
            '⚠️ No se pudieron encontrar los mazos para la batalla $battleId');
        return null;
      }

      final player1Deck =
          Deck.fromMap({...player1DeckDoc.data()!, 'id': player1DeckDoc.id});
      final player2Deck =
          Deck.fromMap({...player2DeckDoc.data()!, 'id': player2DeckDoc.id});

      // Reconstruir las cartas de batalla
      final List<BattleCard> player1Cards = [];
      final List<BattleCard> player2Cards = [];

      // Procesar cartas del jugador 1
      for (var cardData in data['player1CardIds']) {
        try {
          final cardDoc =
              await _firestore.collection('cards').doc(cardData['id']).get();
          if (cardDoc.exists) {
            final card = Card.fromMap(cardDoc.data()!, documentId: cardDoc.id);
            final battleCard = BattleCard.fromCard(card)
              ..currentHealth = cardData['currentHealth'] ?? 0
              ..currentAttack = cardData['currentAttack'] ?? 0
              ..currentDefense = cardData['currentDefense'] ?? 0;
            player1Cards.add(battleCard);
          } else {
            print('⚠️ No se encontró la carta ${cardData['id']} del jugador 1');
          }
        } catch (e) {
          print('Error procesando carta del jugador 1: $e');
        }
      }

      // Procesar cartas del jugador 2
      for (var cardData in data['player2CardIds']) {
        try {
          final cardDoc =
              await _firestore.collection('cards').doc(cardData['id']).get();
          if (cardDoc.exists) {
            final card = Card.fromMap(cardDoc.data()!, documentId: cardDoc.id);
            final battleCard = BattleCard.fromCard(card)
              ..currentHealth = cardData['currentHealth'] ?? 0
              ..currentAttack = cardData['currentAttack'] ?? 0
              ..currentDefense = cardData['currentDefense'] ?? 0;
            player2Cards.add(battleCard);
          } else {
            print('⚠️ No se encontró la carta ${cardData['id']} del jugador 2');
          }
        } catch (e) {
          print('Error procesando carta del jugador 2: $e');
        }
      }

      // Verificar que hay cartas disponibles
      if (player1Cards.isEmpty || player2Cards.isEmpty) {
        print('⚠️ No se pudieron cargar las cartas para la batalla $battleId');
        return null;
      }

      // Reconstruir estado de batalla
      final state = BattleState.values.firstWhere(
        (e) => e.toString() == 'BattleState.${data['state']}',
        orElse: () => BattleState.waiting,
      );

      // Reconstruir acciones
      Map<String, BattleAction> lastActions = {};
      if (data['lastActions'] != null) {
        lastActions = Map<String, BattleAction>.from(
          (data['lastActions'] as Map<String, dynamic>).map(
            (key, value) => MapEntry(
              key,
              BattleAction.values.firstWhere(
                (e) => e.toString() == 'BattleAction.$value',
                orElse: () => BattleAction.attack,
              ),
            ),
          ),
        );
      }

      // Crear objeto Battle
      return Battle(
        id: battleId,
        player1Id: data['player1Id'],
        player2Id: data['player2Id'],
        player1Deck: player1Deck,
        player2Deck: player2Deck,
        player1Cards: player1Cards,
        player2Cards: player2Cards,
        state: state,
        currentTurnPlayerId: data['currentTurnPlayerId'],
        lastActions: lastActions,
        winnerId: data['winnerId'],
      );
    } catch (e) {
      print('Error detallado al reconstruir batalla $battleId: $e');
      return null;
    }
  }

  // Actualizar una batalla
  Future<void> updateBattle(Battle battle) async {
    // Optimizar datos para actualización
    final optimizedData = _optimizeBattleData(battle);

    await _firestore
        .collection(_collection)
        .doc(battle.id)
        .update(optimizedData);
  }

  // Realizar una acción en la batalla
  Future<void> performAction(
      String battleId, String playerId, BattleAction action,
      {String? cardId}) async {
    final battle = await getBattle(battleId);
    if (battle == null) return;

    battle.processAction(playerId, action, cardId: cardId);
    await updateBattle(battle);
  }

  // Obtener batallas activas de un jugador
  Stream<List<Battle>> getPlayerActiveBattles(String playerId) {
    return _firestore
        .collection(_collection)
        .where('state',
            isEqualTo: BattleState.inProgress.toString().split('.').last)
        .where(Filter.or(
          Filter('player1Id', isEqualTo: playerId),
          Filter('player2Id', isEqualTo: playerId),
        ))
        .snapshots()
        .asyncMap((snapshot) async {
      List<Battle> battles = [];
      for (var doc in snapshot.docs) {
        final battle = await _reconstructBattle(doc.data(), doc.id);
        if (battle != null) {
          battles.add(battle);
        }
      }
      return battles;
    });
  }

  // Obtener batallas finalizadas de un jugador
  Stream<List<Battle>> getPlayerFinishedBattles(String playerId) {
    return _firestore
        .collection(_collection)
        .where('state',
            isEqualTo: BattleState.finished.toString().split('.').last)
        .where(Filter.or(
          Filter('player1Id', isEqualTo: playerId),
          Filter('player2Id', isEqualTo: playerId),
        ))
        .snapshots()
        .asyncMap((snapshot) async {
      List<Battle> battles = [];
      for (var doc in snapshot.docs) {
        final battle = await _reconstructBattle(doc.data(), doc.id);
        if (battle != null) {
          battles.add(battle);
        }
      }
      return battles;
    });
  }

  // Buscar combate automáticamente
  Future<Battle?> findMatch(
      String playerId, Deck playerDeck, List<Card> playerCards) async {
    try {
      // Filtrar cartas con IDs válidos y evitar problemas con imágenes base64
      final validCards = playerCards.where((card) {
        // Comprobar que la carta tiene ID válido
        if (card.id.isEmpty) {
          print('⚠️ Carta sin ID en el mazo: ${card.name}');
          return false;
        }

        // Si la imagen es base64, sanitizarla
        if (card.imageUrl.startsWith('data:image')) {
          try {
            final parts = card.imageUrl.split(',');
            if (parts.length <= 1 || parts[1].isEmpty) {
              print(
                  '⚠️ Formato de imagen base64 inválido para carta ${card.id}');
              // No rechazar la carta, pero registrar el problema
            }
          } catch (e) {
            print('⚠️ Error al procesar imagen base64: $e');
            // No rechazar la carta, pero registrar el problema
          }
        }

        return true;
      }).toList();

      if (validCards.isEmpty) {
        print('⚠️ No hay cartas válidas en el mazo para combate');
        return null;
      }

      // Extraer solo los IDs de las cartas para reducir tamaño
      final cardIds = validCards.map((card) => card.id).toList();

      // Primero, verificar si ya hay una solicitud de combate pendiente
      final existingRequest = await _firestore
          .collection(_matchmakingCollection)
          .where('status', isEqualTo: 'waiting')
          .get();

      // Filtrar manualmente las solicitudes que no son del jugador actual
      final opponentRequest = existingRequest.docs
          .where((doc) => doc.data()['playerId'] != playerId)
          .firstOrNull;

      if (opponentRequest != null) {
        // Hay una solicitud pendiente, crear la batalla
        final opponentId = opponentRequest.data()['playerId'] as String;
        final opponentDeckId = opponentRequest.data()['deckId'] as String;

        // Obtener el mazo del oponente
        final opponentDeckDoc =
            await _firestore.collection('decks').doc(opponentDeckId).get();
        if (!opponentDeckDoc.exists) {
          print('⚠️ No se pudo encontrar el mazo del oponente');
          await opponentRequest.reference.delete();
          return null;
        }

        final opponentDeck =
            Deck.fromMap({...opponentDeckDoc.data()!, 'id': opponentDeckId});

        // Obtener solo los IDs de las cartas del oponente
        final opponentCardIds =
            List<String>.from(opponentRequest.data()['cardIds'] as List? ?? [])
                .where((id) => id.isNotEmpty)
                .toList();

        if (opponentCardIds.isEmpty) {
          print('⚠️ No hay cartas válidas en el mazo del oponente');
          // Eliminar la solicitud inválida
          await opponentRequest.reference.delete();
          return null;
        }

        // Cargar las cartas reales desde la base de datos
        final opponentCards = await Future.wait(opponentCardIds.map((id) async {
          try {
            final cardDoc = await _firestore.collection('cards').doc(id).get();
            return cardDoc.exists
                ? Card.fromMap(cardDoc.data()!, documentId: cardDoc.id)
                : null;
          } catch (e) {
            print('Error al cargar carta $id: $e');
            return null;
          }
        }));

        // Filtrar cartas nulas
        final validOpponentCards = opponentCards.whereType<Card>().toList();

        if (validOpponentCards.isEmpty) {
          print('⚠️ No se pudieron cargar cartas válidas para el oponente');
          await opponentRequest.reference.delete();
          return null;
        }

        // Eliminar la solicitud de combate
        await opponentRequest.reference.delete();

        // Crear la batalla
        print('Creando batalla entre $playerId y $opponentId');
        return createBattle(
          player1Id: opponentId,
          player2Id: playerId,
          player1Deck: opponentDeck,
          player2Deck: playerDeck,
          player1Cards: validOpponentCards,
          player2Cards: validCards,
        );
      } else {
        // No hay solicitudes pendientes, crear una nueva con datos mínimos
        await _firestore.collection(_matchmakingCollection).add({
          'playerId': playerId,
          'deckId': playerDeck.id,
          'cardIds': cardIds, // Solo guardar los IDs
          'status': 'waiting',
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Esperar a que alguien más busque combate
        return _waitForMatch(playerId, playerDeck, validCards);
      }
    } catch (e) {
      print('Error en findMatch: $e');
      return null;
    }
  }

  // Esperar a que alguien más busque combate
  Future<Battle?> _waitForMatch(
      String playerId, Deck playerDeck, List<Card> playerCards) async {
    try {
      // Esperar hasta 30 segundos por un oponente
      for (int i = 0; i < 30; i++) {
        await Future.delayed(const Duration(seconds: 1));

        // Verificar si alguien aceptó el combate
        final match = await _firestore
            .collection(_matchmakingCollection)
            .where('status', isEqualTo: 'matched')
            .get();

        // Filtrar manualmente las solicitudes que coinciden con el jugador actual
        final matchedRequest = match.docs
            .where((doc) => doc.data()['opponentId'] == playerId)
            .firstOrNull;

        if (matchedRequest != null) {
          final matchData = matchedRequest.data();
          final opponentId = matchData['playerId'] as String;
          final opponentDeckId = matchData['deckId'] as String;

          // Obtener el mazo del oponente
          final opponentDeckDoc =
              await _firestore.collection('decks').doc(opponentDeckId).get();
          if (!opponentDeckDoc.exists) {
            print('⚠️ No se pudo encontrar el mazo del oponente');
            await matchedRequest.reference.delete();
            continue;
          }

          final opponentDeck =
              Deck.fromMap({...opponentDeckDoc.data()!, 'id': opponentDeckId});

          // Obtener las cartas del oponente usando los IDs
          final opponentCardIds =
              List<String>.from(matchData['cardIds'] as List? ?? [])
                  .where((id) => id.isNotEmpty)
                  .toList();

          if (opponentCardIds.isEmpty) {
            print('⚠️ No hay cartas válidas en el mazo del oponente');
            // Eliminar la solicitud inválida
            await matchedRequest.reference.delete();
            continue;
          }

          final opponentCards = await Future.wait(opponentCardIds.map((id) =>
              _firestore.collection('cards').doc(id).get().then((doc) =>
                  doc.exists
                      ? Card.fromMap(doc.data()!, documentId: doc.id)
                      : null)));

          // Filtrar cartas nulas
          final validOpponentCards = opponentCards.whereType<Card>().toList();

          // Obtener los datos del jugador actual
          final playerRequest = await _firestore
              .collection(_matchmakingCollection)
              .where('playerId', isEqualTo: playerId)
              .where('status', isEqualTo: 'waiting')
              .get();

          if (playerRequest.docs.isNotEmpty) {
            // Eliminar ambas solicitudes
            await matchedRequest.reference.delete();
            await playerRequest.docs.first.reference.delete();

            // Crear la batalla
            return createBattle(
              player1Id: playerId,
              player2Id: opponentId,
              player1Deck: playerDeck,
              player2Deck: opponentDeck,
              player1Cards: playerCards,
              player2Cards: validOpponentCards,
            );
          }
        }
      }

      // Si no se encontró un oponente, eliminar la solicitud
      final request = await _firestore
          .collection(_matchmakingCollection)
          .where('playerId', isEqualTo: playerId)
          .where('status', isEqualTo: 'waiting')
          .get();

      if (request.docs.isNotEmpty) {
        await request.docs.first.reference.delete();
      }

      return null;
    } catch (e) {
      print('Error al esperar combate: $e');
      return null;
    }
  }

  // Cancelar la búsqueda de combate
  Future<void> cancelMatchmaking(String playerId) async {
    final request = await _firestore
        .collection(_matchmakingCollection)
        .where('playerId', isEqualTo: playerId)
        .where('status', isEqualTo: 'waiting')
        .limit(1)
        .get();

    if (request.docs.isNotEmpty) {
      await request.docs.first.reference.delete();
    }
  }
}
