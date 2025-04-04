import 'package:flutter/material.dart';
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
      // Obtener las cartas del sobre
      final packCards = await _packOpeningService.openPack(_selectedPack!);

      // Registrar la apertura del sobre en Firestore
      await _firestoreService.recordPackOpening(userId, _selectedPack!.id,
          packCards.map((card) => card.id).toList(), DateTime.now());

      _openedCards = packCards;
      _isOpening = false;
      notifyListeners();

      return true;
    } catch (e) {
      _isOpening = false;
      _error = 'Error al abrir el sobre: $e';
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
