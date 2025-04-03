import 'dart:math';
import '../models/card_pack.dart';
import '../models/card.dart';
import 'firestore_service.dart';

class PackOpeningService {
  final FirestoreService _firestoreService = FirestoreService();
  final Random _random = Random();

  // Método principal para abrir un sobre y obtener cartas aleatorias
  Future<List<Card>> openPack(CardPack pack) async {
    try {
      // Obtener todas las cartas disponibles
      final List<Card> allCards = await _firestoreService.getAllCards();

      if (allCards.isEmpty) {
        throw Exception('No hay cartas disponibles');
      }

      // Agrupar cartas por rareza
      final Map<CardRarity, List<Card>> cardsByRarity = {};
      for (final rarity in CardRarity.values) {
        cardsByRarity[rarity] =
            allCards.where((card) => card.rarity == rarity).toList();
      }

      // Verificar que hay cartas de cada rareza
      for (final rarity in CardRarity.values) {
        if (cardsByRarity[rarity]!.isEmpty) {
          throw Exception(
              'No hay cartas disponibles de rareza ${rarity.toString()}');
        }
      }

      // Determinar el número de cartas por rareza según el tipo de sobre
      final cardsToOpen = <Card>[];

      switch (pack.type) {
        case CardPackType.basic:
          // 5 cartas - 3 comunes, 1 poco común, 1 rara o superior con baja probabilidad
          cardsToOpen
              .addAll(_getRandomCards(cardsByRarity[CardRarity.common]!, 3));
          cardsToOpen
              .addAll(_getRandomCards(cardsByRarity[CardRarity.uncommon]!, 1));

          // 10% de probabilidad de carta rara, 2% de superRare, 0.5% de legendaria
          final rarityRoll = _random.nextDouble() * 100;
          if (rarityRoll < 0.5) {
            cardsToOpen.addAll(
                _getRandomCards(cardsByRarity[CardRarity.legendary]!, 1));
          } else if (rarityRoll < 2.5) {
            cardsToOpen.addAll(
                _getRandomCards(cardsByRarity[CardRarity.superRare]!, 1));
          } else if (rarityRoll < 12.5) {
            cardsToOpen
                .addAll(_getRandomCards(cardsByRarity[CardRarity.rare]!, 1));
          } else {
            cardsToOpen.addAll(
                _getRandomCards(cardsByRarity[CardRarity.uncommon]!, 1));
          }
          break;

        case CardPackType.premium:
          // 5 cartas - 2 comunes, 2 poco comunes, 1 rara o superior con alta probabilidad
          cardsToOpen
              .addAll(_getRandomCards(cardsByRarity[CardRarity.common]!, 2));
          cardsToOpen
              .addAll(_getRandomCards(cardsByRarity[CardRarity.uncommon]!, 2));

          // 50% de probabilidad de carta rara, 15% de superRare, 5% de legendaria
          final rarityRoll = _random.nextDouble() * 100;
          if (rarityRoll < 5) {
            cardsToOpen.addAll(
                _getRandomCards(cardsByRarity[CardRarity.legendary]!, 1));
          } else if (rarityRoll < 20) {
            cardsToOpen.addAll(
                _getRandomCards(cardsByRarity[CardRarity.superRare]!, 1));
          } else {
            cardsToOpen
                .addAll(_getRandomCards(cardsByRarity[CardRarity.rare]!, 1));
          }
          break;

        case CardPackType.ultra:
          // 5 cartas - 1 común, 2 poco comunes, 1 rara, 1 superRare o legendaria
          cardsToOpen
              .addAll(_getRandomCards(cardsByRarity[CardRarity.common]!, 1));
          cardsToOpen
              .addAll(_getRandomCards(cardsByRarity[CardRarity.uncommon]!, 2));
          cardsToOpen
              .addAll(_getRandomCards(cardsByRarity[CardRarity.rare]!, 1));

          // 30% de probabilidad de legendaria, 70% de superRare
          final rarityRoll = _random.nextDouble() * 100;
          if (rarityRoll < 30) {
            cardsToOpen.addAll(
                _getRandomCards(cardsByRarity[CardRarity.legendary]!, 1));
          } else {
            cardsToOpen.addAll(
                _getRandomCards(cardsByRarity[CardRarity.superRare]!, 1));
          }
          break;

        case CardPackType.legendary:
          // 5 cartas - 2 poco comunes, 2 raras, 1 superRare o legendaria garantizada
          cardsToOpen
              .addAll(_getRandomCards(cardsByRarity[CardRarity.uncommon]!, 2));
          cardsToOpen
              .addAll(_getRandomCards(cardsByRarity[CardRarity.rare]!, 2));

          // 50% de probabilidad de legendaria, 50% de superRare
          final rarityRoll = _random.nextDouble() * 100;
          if (rarityRoll < 50) {
            cardsToOpen.addAll(
                _getRandomCards(cardsByRarity[CardRarity.legendary]!, 1));
          } else {
            cardsToOpen.addAll(
                _getRandomCards(cardsByRarity[CardRarity.superRare]!, 1));
          }
          break;

        case CardPackType.special:
          // 5 cartas dependiendo de la temática del sobre
          // Este caso se manejaría diferente dependiendo del sobre especial
          // Aquí se podría usar el campo 'seriesFilter' del sobre para filtrar cartas
          if (pack.seriesFilter != null && pack.seriesFilter!.isNotEmpty) {
            final seriesCards = allCards
                .where((card) => pack.seriesFilter!.contains(card.series))
                .toList();

            if (seriesCards.length >= 5) {
              cardsToOpen.addAll(_getRandomCards(seriesCards, 5));
            } else {
              // Si no hay suficientes cartas de la serie, usar distribución normal
              cardsToOpen.addAll(
                  _getRandomCards(cardsByRarity[CardRarity.common]!, 2));
              cardsToOpen.addAll(
                  _getRandomCards(cardsByRarity[CardRarity.uncommon]!, 1));
              cardsToOpen
                  .addAll(_getRandomCards(cardsByRarity[CardRarity.rare]!, 1));
              cardsToOpen.addAll(
                  _getRandomCards(cardsByRarity[CardRarity.superRare]!, 1));
            }
          } else {
            // Distribución normal para sobres especiales sin filtro de serie
            cardsToOpen
                .addAll(_getRandomCards(cardsByRarity[CardRarity.common]!, 2));
            cardsToOpen.addAll(
                _getRandomCards(cardsByRarity[CardRarity.uncommon]!, 1));
            cardsToOpen
                .addAll(_getRandomCards(cardsByRarity[CardRarity.rare]!, 1));
            cardsToOpen.addAll(
                _getRandomCards(cardsByRarity[CardRarity.superRare]!, 1));
          }
          break;

        case CardPackType.ultimate:
          // 5 cartas - 1 común, 1 poco común, 1 rara, 1 superRare, 1 ultra o legendaria
          cardsToOpen
              .addAll(_getRandomCards(cardsByRarity[CardRarity.common]!, 1));
          cardsToOpen
              .addAll(_getRandomCards(cardsByRarity[CardRarity.uncommon]!, 1));
          cardsToOpen
              .addAll(_getRandomCards(cardsByRarity[CardRarity.rare]!, 1));
          cardsToOpen
              .addAll(_getRandomCards(cardsByRarity[CardRarity.superRare]!, 1));

          // 40% de probabilidad de legendaria, 60% de ultraRare
          final rarityRoll = _random.nextDouble() * 100;
          if (rarityRoll < 40) {
            cardsToOpen.addAll(
                _getRandomCards(cardsByRarity[CardRarity.legendary]!, 1));
          } else {
            cardsToOpen.addAll(
                _getRandomCards(cardsByRarity[CardRarity.ultraRare]!, 1));
          }
          break;
      }

      return cardsToOpen;
    } catch (e) {
      print('Error al abrir sobre: $e');
      rethrow;
    }
  }

  // Método auxiliar para obtener cartas aleatorias de una lista
  List<Card> _getRandomCards(List<Card> cards, int count) {
    if (cards.isEmpty) {
      return [];
    }

    if (cards.length <= count) {
      return List.from(cards);
    }

    final result = <Card>[];
    final cardsCopy = List<Card>.from(cards);

    for (var i = 0; i < count; i++) {
      final randomIndex = _random.nextInt(cardsCopy.length);
      result.add(cardsCopy[randomIndex]);
      cardsCopy.removeAt(randomIndex); // Evitar duplicados
    }

    return result;
  }
}
