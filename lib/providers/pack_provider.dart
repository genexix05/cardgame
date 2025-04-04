import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/card_pack.dart';
import '../models/card.dart' as card_model;
import '../services/firestore_service.dart';
import '../services/pack_opening_service.dart';

class PackProvider with ChangeNotifier {
  FirestoreService _firestoreService;
  PackOpeningService _packOpeningService;

  PackProvider(this._firestoreService, this._packOpeningService);

  List<CardPack> _availablePacks = [];
  CardPack? _selectedPack;
  List<card_model.Card> _openedCards = [];
  bool _isLoading = false;
  bool _isOpening = false;
  String? _error;

  List<CardPack> get availablePacks => _availablePacks;
  CardPack? get selectedPack => _selectedPack;
  List<card_model.Card> get openedCards => _openedCards;
  List<card_model.Card> get lastOpenedCards => _openedCards;
  bool get isLoading => _isLoading;
  bool get isOpening => _isOpening;
  bool get isOpeningPack => _isOpening;
  String? get error => _error;

  // Sobres limitados
  List<CardPack> get limitedPacks =>
      _availablePacks.where((pack) => pack.isLimited).toList();

  // Cargar todos los sobres disponibles
  Future<void> loadAvailablePacks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _availablePacks = await _firestoreService.getAvailablePacks();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Error al cargar los sobres: $e';
      notifyListeners();
    }
  }

  // Seleccionar un sobre
  void selectPack(CardPack pack) {
    _selectedPack = pack;
    notifyListeners();
  }

  // Abrir un sobre
  Future<bool> openPack(String userId) async {
    if (_selectedPack == null) {
      _error = 'No hay un sobre seleccionado';
      notifyListeners();
      return false;
    }

    _isOpening = true;
    _error = null;
    _openedCards = [];
    notifyListeners();

    try {
      print(
          '🎁 Iniciando apertura del sobre: ${_selectedPack!.name} (ID: ${_selectedPack!.id})');

      // Verificar si el usuario puede permitirse el sobre
      final canAfford =
          await _firestoreService.canUserAffordPack(userId, _selectedPack!);
      if (!canAfford) {
        _isOpening = false;
        _error =
            'No tienes suficientes ${_selectedPack!.currency == CardPackCurrency.coins ? 'monedas' : 'gemas'} para abrir este sobre';
        notifyListeners();
        return false;
      }

      print('💰 Usuario puede permitirse el sobre. Obteniendo cartas...');

      // Obtener las cartas del sobre
      final packCards = await _packOpeningService.openPack(_selectedPack!);

      List<String> cardIds = [];
      if (packCards.isNotEmpty) {
        // Verificar que cada carta tenga un ID válido
        bool hasInvalidCards = false;
        for (final card in packCards) {
          if (card.id.isEmpty) {
            print('⚠️ Carta sin ID válido: ${card.name}');
            hasInvalidCards = true;
          }
        }

        if (hasInvalidCards) {
          print(
              '⚠️ Se encontraron cartas con IDs inválidos. Regenerando IDs...');
          // Forzar IDs válidos
          for (int i = 0; i < packCards.length; i++) {
            final card = packCards[i];
            if (card.id.isEmpty) {
              // Si no tiene ID, usar el nombre como referencia temporal
              cardIds.add(
                  'generatedId_${card.name.replaceAll(" ", "_").toLowerCase()}');
            } else {
              cardIds.add(card.id);
            }
          }
        } else {
          // Obtener IDs normalmente
          cardIds = packCards.map((card) => card.id).toList();
        }

        _openedCards = packCards;
        print('🃏 Se obtuvieron ${packCards.length} cartas del sobre');
        print('IDs de cartas obtenidas: $cardIds');

        // Verificación adicional de IDs
        if (cardIds.isEmpty && packCards.isNotEmpty) {
          print(
              '⚠️ ADVERTENCIA: Se tienen ${packCards.length} cartas pero la lista de IDs está vacía');
          print('Información de las cartas:');
          for (int i = 0; i < packCards.length; i++) {
            print(
                'Carta ${i + 1}: ${packCards[i].name}, ID: ${packCards[i].id}');
          }
        }
      } else {
        // Si no hay cartas disponibles, mostrar un mensaje pero continuar con el proceso
        print('⚠️ No hay cartas disponibles en la base de datos');
        _error =
            'No hay cartas disponibles en este momento. Prueba más tarde cuando se añadan cartas al juego.';
      }

      // Verificación final de IDs
      if (cardIds.isEmpty) {
        print('⚠️ Lista de IDs vacía. Abortando el proceso.');
        _isOpening = false;
        _error =
            'Error al procesar las cartas del sobre. Por favor, inténtalo de nuevo.';
        notifyListeners();
        return false;
      }

      print('📝 Registrando apertura del sobre en Firestore');

      // Registrar la apertura del sobre en Firestore (incluso si no hay cartas)
      await _firestoreService.recordPackOpening(
          userId, _selectedPack!.id, cardIds, DateTime.now());

      print('💾 Actualizando colección del usuario');

      // IMPORTANTE: Actualizar la colección del usuario y descontar el precio
      // Esto funcionará incluso si cardIds está vacío, solo descontará el precio
      final updateSuccess = await _firestoreService.addCardsToUserCollection(
        userId,
        cardIds,
        _selectedPack!.price,
        _selectedPack!.currency,
      );

      if (!updateSuccess) {
        _isOpening = false;
        _error = 'Error al actualizar la colección del usuario';
        print('❌ Error al actualizar colección de usuario');
        notifyListeners();
        return false;
      }

      print('✅ Sobre abierto exitosamente');
      _isOpening = false;
      notifyListeners();

      // Si hay un error pero la transacción fue exitosa, seguimos considerándolo
      // un éxito para que se redirija a la pantalla de apertura
      return true;
    } catch (e) {
      _isOpening = false;
      _error = 'Error al abrir el sobre: $e';
      print('❌ Excepción al abrir sobre: $e');
      if (e is FirebaseException) {
        print(
            'Detalles del error Firebase - Código: ${e.code}, Mensaje: ${e.message}');
      }
      notifyListeners();
      return false;
    }
  }

  // Limpiar las cartas abiertas
  void clearOpenedCards() {
    _openedCards = [];
    notifyListeners();
  }

  // Actualizar servicios
  void update(FirestoreService firestoreService,
      PackOpeningService packOpeningService) {
    _firestoreService = firestoreService;
    _packOpeningService = packOpeningService;
    notifyListeners();
  }

  // Obtener sobres por serie
  List<CardPack> getPacksBySeries(String series) {
    return _availablePacks
        .where((pack) => pack.seriesFilter?.contains(series) ?? false)
        .toList();
  }

  // Obtener las probabilidades de rareza de un sobre
  Map<card_model.CardRarity, double> getPackRarityOdds(CardPack pack) {
    return {
      card_model.CardRarity.common: pack.rarityDistribution?.common ?? 0,
      card_model.CardRarity.uncommon: pack.rarityDistribution?.uncommon ?? 0,
      card_model.CardRarity.rare: pack.rarityDistribution?.rare ?? 0,
      card_model.CardRarity.superRare: pack.rarityDistribution?.superRare ?? 0,
      card_model.CardRarity.ultraRare: pack.rarityDistribution?.ultraRare ?? 0,
      card_model.CardRarity.legendary: pack.rarityDistribution?.legendary ?? 0,
    };
  }
}
