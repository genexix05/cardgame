import 'package:flutter/material.dart';
import '../models/card.dart' as card_model;
import '../models/user_collection.dart';
import '../services/firestore_service.dart';

class CollectionProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  UserCollection? _userCollection;
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>>? _userCardsWithDetails;

  UserCollection? get userCollection => _userCollection;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Lista de cartas con detalles para mostrar en la UI
  List<Map<String, dynamic>> get userCardsWithDetails =>
      _userCardsWithDetails ?? [];

  // Cargar la colección del usuario
  Future<void> loadUserCollection(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _userCollection = await _firestoreService.getUserCollection(userId);

      // Cargar los detalles de las cartas para mostrar en la UI
      await _loadCardDetails();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Error al cargar la colección: $e';
      notifyListeners();
    }
  }

  // Cargar los detalles de las cartas
  Future<void> _loadCardDetails() async {
    if (_userCollection == null) return;

    final tempCards = <Map<String, dynamic>>[];

    for (final entry in _userCollection!.cards.entries) {
      final cardId = entry.key;
      final userCard = entry.value;

      // Obtener detalles de la carta desde Firestore
      final cardDetails = await _firestoreService.getCardById(cardId);

      if (cardDetails != null) {
        tempCards.add({
          'userCard': userCard,
          'cardDetail': cardDetails,
        });
      }
    }

    // Actualizar la lista una vez que tengamos todos los datos
    _userCardsWithDetails = tempCards;
  }

  // Agregar cartas a la colección del usuario
  Future<void> addCardsToCollection(
      String userId, List<card_model.Card> cards) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Primero actualizamos la colección local
      if (_userCollection != null) {
        Map<String, UserCard> updatedCards = Map.from(_userCollection!.cards);

        for (final card in cards) {
          if (updatedCards.containsKey(card.id)) {
            // Si la carta ya existe, incrementamos la cantidad
            final existingCard = updatedCards[card.id]!;
            updatedCards[card.id] = existingCard.copyWith(
              quantity: existingCard.quantity + 1,
            );
          } else {
            // Si es una carta nueva, la agregamos con cantidad 1
            updatedCards[card.id] = UserCard(
              cardId: card.id,
              quantity: 1,
            );
          }
        }

        // Actualizamos stats de la colección
        _userCollection = _userCollection!.copyWith(
          cards: updatedCards,
          totalCards: _userCollection!.totalCards + cards.length,
          lastUpdated: DateTime.now(),
        );
      } else {
        // Si no hay colección, crear una nueva
        Map<String, UserCard> newCards = {};
        for (final card in cards) {
          newCards[card.id] = UserCard(
            cardId: card.id,
            quantity: 1,
          );
        }

        _userCollection = UserCollection(
          userId: userId,
          cards: newCards,
          totalCards: cards.length,
          lastUpdated: DateTime.now(),
        );
      }

      // Luego guardamos en Firestore (si existe un método que lo permita)
      if (_userCollection != null) {
        // Asumiendo que updateUserCollection existe en FirestoreService
        // En caso contrario, usa el método adecuado de tu FirestoreService
        await _firestoreService.updateUserCollection(userId, _userCollection!);
      }

      // Recargamos los detalles de las cartas
      await _loadCardDetails();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Error al actualizar la colección: $e';
      notifyListeners();
    }
  }

  // Obtener cartas por rareza
  List<Map<String, dynamic>> getCardsByRarity(card_model.CardRarity rarity) {
    if (_userCardsWithDetails == null) {
      return [];
    }

    return _userCardsWithDetails!.where((item) {
      final cardDetail = item['cardDetail'] as card_model.Card; // Cambio aquí
      final userCard = item['userCard'] as UserCard;
      return cardDetail.rarity == rarity && userCard.quantity > 0;
    }).toList();
  }

  // Obtener cartas por serie
  List<Map<String, dynamic>> getCardsBySeries(String series) {
    if (_userCardsWithDetails == null) {
      return [];
    }

    return _userCardsWithDetails!.where((item) {
      final cardDetail = item['cardDetail'] as card_model.Card; // Cambio aquí
      final userCard = item['userCard'] as UserCard;
      return cardDetail.series == series && userCard.quantity > 0;
    }).toList();
  }

  // Calcular el porcentaje de compleción de la colección
  double getCompletionPercentage(List<Card> allCards) {
    if (_userCollection == null || allCards.isEmpty) {
      return 0.0;
    }

    final ownedUniqueCards = _userCollection!.cards.entries
        .where((entry) => entry.value.quantity > 0)
        .length;

    return (ownedUniqueCards / allCards.length) * 100;
  }

  // Obtener cartas favoritas
  List<Map<String, dynamic>> getFavoriteCards() {
    if (_userCardsWithDetails == null) {
      return [];
    }

    return _userCardsWithDetails!.where((item) {
      final userCard = item['userCard'];
      return userCard.isFavorite && userCard.quantity > 0;
    }).toList();
  }
}
