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
      // Primero, verificar si el sobre tiene cartas fijas en 'packCards'
      final List<String> fixedCardIds =
          await _firestoreService.getPackCards(pack.id);
      if (fixedCardIds.isNotEmpty) {
        print(
            'El sobre tiene ${fixedCardIds.length} cartas fijas predefinidas');

        // Verificar que los ID de cartas sean válidos antes de continuar
        bool allIdsValid = true;
        for (final cardId in fixedCardIds) {
          if (cardId.isEmpty || cardId.trim().isEmpty) {
            print('⚠️ Se encontró un ID de carta inválido: "$cardId"');
            allIdsValid = false;
            break;
          }
        }

        if (!allIdsValid) {
          print(
              '⚠️ Hay IDs de cartas inválidos. Usando distribución aleatoria.');
        } else {
          // Obtener las cartas completas a partir de los IDs
          final List<Card> fixedCards = [];
          for (final cardId in fixedCardIds) {
            try {
              final card = await _firestoreService.getCardById(cardId);
              if (card != null) {
                // Asegurarse de que el ID de la carta esté correctamente asignado
                final cardWithCorrectId = Card(
                  id: cardId,
                  name: card.name,
                  description: card.description,
                  imageUrl: card.imageUrl,
                  rarity: card.rarity,
                  type: card.type,
                  stats: card.stats,
                  power: card.power,
                  abilities: card.abilities,
                  tags: card.tags,
                  series: card.series,
                );

                fixedCards.add(cardWithCorrectId);
                print(
                    '✅ Carta cargada correctamente: ${card.name} (ID: $cardId)');
                print('✅ Verificación de ID en carta: ${cardWithCorrectId.id}');
              } else {
                print('⚠️ No se pudo encontrar la carta con ID: $cardId');
              }
            } catch (e) {
              print('⚠️ Error al cargar la carta $cardId: $e');
            }
          }

          if (fixedCards.isNotEmpty) {
            if (fixedCards.length < fixedCardIds.length) {
              print(
                  '⚠️ Advertencia: Solo se pudieron cargar ${fixedCards.length} de ${fixedCardIds.length} cartas fijas');
            }
            print('Retornando ${fixedCards.length} cartas fijas del sobre');
            return fixedCards;
          } else {
            print(
                'No se pudieron cargar las cartas fijas, continuando con distribución normal');
          }
        }
      }

      // Si no hay cartas fijas o no se pudieron cargar, continuar con la distribución normal
      // Obtener todas las cartas disponibles
      final List<Card> allCards = await _firestoreService.getAllCards();

      if (allCards.isEmpty) {
        throw Exception('No hay cartas disponibles en el sistema');
      }

      // Agrupar cartas por rareza
      final Map<CardRarity, List<Card>> cardsByRarity = {};
      for (final rarity in CardRarity.values) {
        cardsByRarity[rarity] =
            allCards.where((card) => card.rarity == rarity).toList();
      }

      // Verificar disponibilidad de cartas y registrar rarezas faltantes
      bool hasMissingRarities = false;
      String missingRaritiesMessage =
          'Faltan cartas de las siguientes rarezas: ';

      for (final rarity in CardRarity.values) {
        if (cardsByRarity[rarity]!.isEmpty) {
          hasMissingRarities = true;
          missingRaritiesMessage += '${_getRarityDisplayName(rarity)}, ';
        }
      }

      if (hasMissingRarities) {
        print(missingRaritiesMessage);
      }

      // IMPORTANTE: Si no hay suficientes cartas de cada rareza, simplemente devolvemos
      // cartas aleatorias de las disponibles, sin importar su rareza
      if (hasMissingRarities || allCards.length < 5) {
        print('Usando cartas disponibles sin respetar distribución de rareza');
        int cardsToReturn = allCards.length >= 5 ? 5 : allCards.length;
        return _getRandomCards(allCards, cardsToReturn);
      }

      // Si hay suficientes cartas, continuamos con la distribución normal según el tipo de sobre
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

      // En caso de error, intentar devolver algunas cartas aleatorias del pool disponible
      try {
        final fallbackCards = await _firestoreService.getAllCards();
        if (fallbackCards.isNotEmpty) {
          print('Usando cartas de fallback debido a un error');
          final count = fallbackCards.length > 5 ? 5 : fallbackCards.length;
          return _getRandomCards(fallbackCards, count);
        }
      } catch (fallbackError) {
        print('Error adicional al intentar recuperarse: $fallbackError');
      }

      // Si realmente no hay cartas disponibles, devolver una lista vacía
      return [];
    }
  }

  // Método para obtener el nombre legible de una rareza
  String _getRarityDisplayName(CardRarity rarity) {
    switch (rarity) {
      case CardRarity.common:
        return 'Común';
      case CardRarity.uncommon:
        return 'Poco común';
      case CardRarity.rare:
        return 'Rara';
      case CardRarity.superRare:
        return 'Super rara';
      case CardRarity.ultraRare:
        return 'Ultra rara';
      case CardRarity.legendary:
        return 'Legendaria';
      default:
        return rarity.toString();
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
