import 'package:flutter/material.dart' hide Card;
import 'package:flutter/foundation.dart';
import '../models/deck.dart';
import '../models/card.dart';
import '../services/firestore_service.dart';

class DeckProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<Deck> _userDecks = [];
  final Map<String, List<Card>> _deckCards = {};
  bool _isLoading = false;
  String? _error;

  List<Deck> get userDecks => _userDecks;
  Map<String, List<Card>> get deckCards => _deckCards;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Cargar los mazos del usuario
  Future<void> loadUserDecks(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (kDebugMode) {
        print('DeckProvider: Cargando mazos para el usuario $userId');
      }

      _userDecks = await _firestoreService.getUserDecks(userId);

      if (kDebugMode) {
        print('DeckProvider: Se cargaron ${_userDecks.length} mazos');
      }

      // Cargar las cartas de cada mazo
      await _loadDeckCards();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('DeckProvider: Error al cargar los mazos: $e');
      }
      _isLoading = false;
      _error = 'Error al cargar los mazos: $e';
      notifyListeners();
    }
  }

  // Cargar las cartas de cada mazo
  Future<void> _loadDeckCards() async {
    _deckCards.clear();

    for (final deck in _userDecks) {
      final cards = <Card>[];
      int missingCards = 0;
      List<String> missingCardIds = [];

      for (final cardId in deck.cardIds) {
        if (cardId.isEmpty) {
          print('⚠️ ID de carta vacío en el mazo ${deck.name} (${deck.id})');
          missingCardIds.add("ID vacío");
          missingCards++;
          continue;
        }

        final card = await _firestoreService.getCardById(cardId);
        if (card != null) {
          if (card.id.isEmpty) {
            print('⚠️ Carta cargada sin ID: ${card.name} (Tipo: ${card.type})');
            missingCards++;
          }
          cards.add(card);
        } else {
          print(
              '⚠️ No se pudo cargar la carta con ID: $cardId para el mazo ${deck.name}');
          missingCardIds.add(cardId);
          missingCards++;
        }
      }

      if (missingCards > 0) {
        print(
            '⚠️ El mazo ${deck.name} tiene $missingCards cartas faltantes o sin ID');
        print('⚠️ IDs de cartas problemáticas: ${missingCardIds.join(', ')}');
      }

      _deckCards[deck.id] = cards;
    }
  }

  // Crear un nuevo mazo
  Future<void> createDeck(
      String userId, String name, List<String> cardIds) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final deck = await _firestoreService.createDeck(userId, name, cardIds);
      if (deck != null) {
        _userDecks.add(deck);
        await _loadDeckCards();
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Error al crear el mazo: $e';
      notifyListeners();
    }
  }

  // Actualizar un mazo existente
  Future<void> updateDeck(
      String deckId, String name, List<String> cardIds) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final deck = _userDecks.firstWhere((d) => d.id == deckId);
      final updatedDeck = deck.copyWith(
        name: name,
        cardIds: cardIds,
        lastModified: DateTime.now(),
      );
      final success = await _firestoreService.updateDeck(updatedDeck);
      if (success) {
        final index = _userDecks.indexWhere((d) => d.id == deckId);
        if (index != -1) {
          _userDecks[index] = updatedDeck;
          await _loadDeckCards();
        }
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Error al actualizar el mazo: $e';
      notifyListeners();
    }
  }

  // Eliminar un mazo
  Future<void> deleteDeck(String deckId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _firestoreService.deleteDeck(deckId);
      if (success) {
        _userDecks.removeWhere((deck) => deck.id == deckId);
        _deckCards.remove(deckId);
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Error al eliminar el mazo: $e';
      notifyListeners();
    }
  }

  // Reparar mazos eliminando cartas inválidas
  Future<String> repairDeck(String deckId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Encontrar el mazo
      final deckIndex = _userDecks.indexWhere((d) => d.id == deckId);
      if (deckIndex == -1) {
        _isLoading = false;
        _error = 'Mazo no encontrado';
        notifyListeners();
        return 'Mazo no encontrado';
      }

      final deck = _userDecks[deckIndex];

      // Verificar cada ID de carta
      final validCardIds = <String>[];
      final invalidCardIds = <String>[];

      for (final cardId in deck.cardIds) {
        // Si el ID está vacío, ignorarlo
        if (cardId.isEmpty) {
          invalidCardIds.add('ID vacío');
          continue;
        }

        // Verificar si la carta existe en Firestore
        final cardExists = await _firestoreService.checkCardExists(cardId);
        if (cardExists) {
          validCardIds.add(cardId);
        } else {
          invalidCardIds.add(cardId);
        }
      }

      // Si no hay IDs inválidos, no necesitamos reparar
      if (invalidCardIds.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return 'El mazo ya está en buen estado';
      }

      // Actualizar el mazo con solo los IDs válidos
      final updatedDeck = deck.copyWith(
        cardIds: validCardIds,
        lastModified: DateTime.now(),
      );

      // Guardar el mazo actualizado
      final success = await _firestoreService.updateDeck(updatedDeck);

      if (success) {
        // Actualizar la lista local
        _userDecks[deckIndex] = updatedDeck;

        // Recargar las cartas
        await _loadDeckCards();

        _isLoading = false;
        notifyListeners();

        if (invalidCardIds.length == 1) {
          return 'Se eliminó 1 carta inválida del mazo';
        } else {
          return 'Se eliminaron ${invalidCardIds.length} cartas inválidas del mazo';
        }
      } else {
        _isLoading = false;
        _error = 'Error al actualizar el mazo';
        notifyListeners();
        return 'Error al actualizar el mazo';
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Error al reparar el mazo: $e';
      notifyListeners();
      return 'Error: $e';
    }
  }

  // Corregir cartas con ID vacío en un mazo
  Future<bool> fixCardsWithEmptyIds(String deckId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Encontrar el mazo
      final deckIndex = _userDecks.indexWhere((d) => d.id == deckId);
      if (deckIndex == -1) {
        _isLoading = false;
        _error = 'Mazo no encontrado';
        notifyListeners();
        return false;
      }

      final deck = _userDecks[deckIndex];

      // Verificar cada ID de carta
      final validCardIds = deck.cardIds.where((id) => id.isNotEmpty).toList();
      final emptyIdCount = deck.cardIds.length - validCardIds.length;

      if (emptyIdCount == 0) {
        _isLoading = false;
        notifyListeners();
        return true;
      }

      print('🔄 Se eliminarán $emptyIdCount IDs vacíos del mazo ${deck.name}');

      // Obtener cartas de Dragon Ball para reemplazar las faltantes
      final dragonBallCards =
          await _firestoreService.getCardsByQuery('Dragon Ball');

      // Si hay cartas de Dragon Ball y faltan cartas, añadir algunas para mantener el mazo completo
      if (dragonBallCards.isNotEmpty && validCardIds.length < 3) {
        final cardsToAdd = 3 - validCardIds.length;
        print(
            '➕ Añadiendo $cardsToAdd cartas de Dragon Ball para completar el mazo');

        for (int i = 0; i < cardsToAdd && i < dragonBallCards.length; i++) {
          validCardIds.add(dragonBallCards[i].id);
          print(
              '✅ Añadida carta: ${dragonBallCards[i].name} (${dragonBallCards[i].id})');
        }
      }

      // Actualizar el mazo con solo los IDs válidos
      final updatedDeck = deck.copyWith(
        cardIds: validCardIds,
        lastModified: DateTime.now(),
      );

      // Guardar el mazo actualizado
      final success = await _firestoreService.updateDeck(updatedDeck);

      if (success) {
        // Actualizar la lista local
        _userDecks[deckIndex] = updatedDeck;

        // Recargar las cartas
        await _loadDeckCards();

        _isLoading = false;
        notifyListeners();

        return true;
      } else {
        _isLoading = false;
        _error = 'Error al actualizar el mazo';
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('Error al reparar el mazo: $e');
      _isLoading = false;
      _error = 'Error al reparar el mazo: $e';
      notifyListeners();
      return false;
    }
  }

  // Obtener una lista de cartas por sus IDs
  Future<List<Card>> getCardsByIds(List<String> cardIds) async {
    final List<Card> cards = [];
    if (kDebugMode) {
      print('DeckProvider: Obteniendo cartas por IDs: ${cardIds.join(', ')}');
    }
    for (final cardId in cardIds) {
      if (cardId.isEmpty) {
        if (kDebugMode) {
          print('DeckProvider: ID de carta vacío encontrado, omitiendo.');
        }
        continue;
      }
      try {
        final card = await _firestoreService.getCardById(cardId);
        if (card != null) {
          cards.add(card);
        } else {
          if (kDebugMode) {
            print('DeckProvider: No se encontró la carta con ID: $cardId');
          }
          // Opcionalmente, podrías lanzar un error aquí o manejarlo de otra forma
        }
      } catch (e) {
        if (kDebugMode) {
          print('DeckProvider: Error al obtener la carta con ID $cardId: $e');
        }
        // Opcionalmente, podrías re-lanzar el error o manejarlo
      }
    }
    if (kDebugMode) {
      print(
          'DeckProvider: Se obtuvieron ${cards.length} cartas de ${cardIds.length} IDs solicitados.');
    }
    return cards;
  }
}
