import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/collection_provider.dart';
import '../../models/card.dart' as model;
import '../../models/user_collection.dart';
import '../../services/firestore_service.dart';
import '../user_sales_screen.dart';
import 'dart:convert';
import 'dart:typed_data';

class MarketTab extends StatefulWidget {
  const MarketTab({super.key});

  @override
  State<MarketTab> createState() => _MarketTabState();
}

class _MarketTabState extends State<MarketTab>
    with AutomaticKeepAliveClientMixin {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _cardsForSale = [];
  List<Map<String, dynamic>> _filteredCards = [];
  String? _errorMessage;

  // Filtros
  String _searchQuery = '';
  List<String> _seriesFilter = [];
  List<model.CardRarity> _rarityFilter = [];
  List<model.CardType> _typeFilter = [];
  RangeValues _priceRange = const RangeValues(0, 1000);

  // Para la lista desplegable de series
  List<String> _availableSeries = [];

  // Método para construir la imagen de la carta (maneja URL y base64)
  Widget _buildCardImage(String imageUrl) {
    // Verificar si la imagen está en formato base64
    final imageBytes = _getImageBytes(imageUrl);

    if (imageBytes != null) {
      // Si es base64, mostrar usando Image.memory
      return Image.memory(
        imageBytes,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 100,
            height: 100,
            color: Colors.grey.shade300,
            child: const Icon(
              Icons.broken_image,
              color: Colors.grey,
            ),
          );
        },
      );
    } else {
      // Si es URL, mostrar usando Image.network
      return Image.network(
        imageUrl,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 100,
            height: 100,
            color: Colors.grey.shade300,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 100,
            height: 100,
            color: Colors.grey.shade300,
            child: const Icon(
              Icons.broken_image,
              color: Colors.grey,
            ),
          );
        },
      );
    }
  }

  // Método para extraer los bytes de la imagen de un string base64
  Uint8List? _getImageBytes(String url) {
    if (url.startsWith('data:')) {
      final parts = url.split(',');
      if (parts.length > 1) {
        try {
          return base64Decode(parts[1]);
        } catch (e) {
          return null;
        }
      }
    }
    return null;
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    // Cargar los datos después del primer frame para evitar problemas durante el build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMarketCards();
    });
  }

  Future<void> _loadMarketCards() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Utilizar los filtros actuales para la carga de cartas
      final cards = await _firestoreService.getCardsForSale(
        series: _seriesFilter.isNotEmpty ? _seriesFilter : null,
        rarities: _rarityFilter.isNotEmpty ? _rarityFilter : null,
        types: _typeFilter.isNotEmpty ? _typeFilter : null,
        minPrice: _priceRange.start > 0 ? _priceRange.start.toInt() : null,
        maxPrice: _priceRange.end < 1000 ? _priceRange.end.toInt() : null,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      setState(() {
        _cardsForSale = cards;
        _filteredCards = cards;
        _isLoading = false;

        // Extraer series únicas disponibles
        _extractAvailableSeries();
      });

      // Cargar series disponibles para el filtro
      _loadAvailableSeries();
    } catch (e) {
      setState(() {
        _errorMessage = "Error al cargar el mercado: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAvailableSeries() async {
    try {
      final series = await _firestoreService.getAvailableSeriesInMarket();
      setState(() {
        _availableSeries = series;
      });
    } catch (e) {
      print('Error al cargar series disponibles: $e');
    }
  }

  void _extractAvailableSeries() {
    final seriesSet = <String>{};
    for (final item in _cardsForSale) {
      final card = model.Card.fromMap(item['card']);
      if (card.series.isNotEmpty) {
        seriesSet.add(card.series);
      }
    }
    _availableSeries = seriesSet.toList()..sort();
  }

  void _applyFilters() {
    setState(() {
      _filteredCards = _cardsForSale.where((item) {
        final card = model.Card.fromMap(item['card']);
        final price = item['price'] as int;

        // Filtro por texto de búsqueda
        final matchesSearch = _searchQuery.isEmpty ||
            card.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            card.description.toLowerCase().contains(_searchQuery.toLowerCase());

        // Filtro por series
        final matchesSeries =
            _seriesFilter.isEmpty || _seriesFilter.contains(card.series);

        // Filtro por rareza
        final matchesRarity =
            _rarityFilter.isEmpty || _rarityFilter.contains(card.rarity);

        // Filtro por tipo
        final matchesType =
            _typeFilter.isEmpty || _typeFilter.contains(card.type);

        // Filtro por rango de precio
        final matchesPrice =
            price >= _priceRange.start && price <= _priceRange.end;

        return matchesSearch &&
            matchesSeries &&
            matchesRarity &&
            matchesType &&
            matchesPrice;
      }).toList();
    });
  }

  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _seriesFilter = [];
      _rarityFilter = [];
      _typeFilter = [];
      _priceRange = const RangeValues(0, 1000);
      _filteredCards = _cardsForSale;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final collectionProvider = Provider.of<CollectionProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MERCADO',
          style: TextStyle(
            fontFamily: 'CCSoothsayer',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Botón para ver mis ventas
          IconButton(
            icon: const Icon(Icons.sell),
            tooltip: 'Mis ventas',
            onPressed: () {
              Navigator.of(context).pushNamed(UserSalesScreen.routeName);
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMarketCards,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/home_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : Column(
                    children: [
                      // Información del usuario con estilo gaming más sutil
                      Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              const Color(0xFF1A1A2E).withOpacity(0.6),
                              const Color(0xFF16213E).withOpacity(0.4),
                              const Color(0xFF0F3460).withOpacity(0.6),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFFFD700).withOpacity(0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.account_balance_wallet,
                                color: const Color(0xFFFFD700).withOpacity(0.8),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'TUS MONEDAS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white60,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFFFFD700).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFFFD700)
                                        .withOpacity(0.4),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  '${collectionProvider.userCollection?.coins ?? 0}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFFD700),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Barra de búsqueda
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Buscar cartas...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                      _applyFilters();
                                    },
                                  )
                                : null,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                            _applyFilters();
                          },
                        ),
                      ),

                      // Chips de filtros activos
                      if (_seriesFilter.isNotEmpty ||
                          _rarityFilter.isNotEmpty ||
                          _typeFilter.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              ..._seriesFilter.map((series) => Chip(
                                    label: Text(series),
                                    onDeleted: () {
                                      setState(() {
                                        _seriesFilter.remove(series);
                                      });
                                      _applyFilters();
                                    },
                                  )),
                              ..._rarityFilter.map((rarity) => Chip(
                                    backgroundColor: _getRarityColor(rarity)
                                        .withOpacity(0.2),
                                    label: Text(_getRarityText(rarity)),
                                    onDeleted: () {
                                      setState(() {
                                        _rarityFilter.remove(rarity);
                                      });
                                      _applyFilters();
                                    },
                                  )),
                              ..._typeFilter.map((type) => Chip(
                                    label: Text(_getTypeText(type)),
                                    onDeleted: () {
                                      setState(() {
                                        _typeFilter.remove(type);
                                      });
                                      _applyFilters();
                                    },
                                  )),
                              if (_priceRange.start > 0 ||
                                  _priceRange.end < 1000)
                                Chip(
                                  label: Text(
                                      '${_priceRange.start.toInt()} - ${_priceRange.end.toInt()} 💰'),
                                  onDeleted: () {
                                    setState(() {
                                      _priceRange = const RangeValues(0, 1000);
                                    });
                                    _applyFilters();
                                  },
                                ),
                              ActionChip(
                                label: const Text('Limpiar todos'),
                                onPressed: () {
                                  _resetFilters();
                                },
                              ),
                            ],
                          ),
                        ),

                      // Lista de cartas en venta
                      Expanded(
                        child: _filteredCards.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.search_off,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _cardsForSale.isEmpty
                                          ? 'No hay cartas a la venta en este momento'
                                          : 'No se encontraron cartas con los filtros actuales',
                                      style: const TextStyle(fontSize: 16),
                                      textAlign: TextAlign.center,
                                    ),
                                    if (_cardsForSale.isNotEmpty &&
                                        _filteredCards.isEmpty)
                                      const SizedBox(height: 16),
                                    if (_cardsForSale.isNotEmpty &&
                                        _filteredCards.isEmpty)
                                      ElevatedButton(
                                        onPressed: _resetFilters,
                                        child: const Text('Limpiar filtros'),
                                      ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _loadMarketCards,
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(16.0),
                                  itemCount: _filteredCards.length,
                                  itemBuilder: (context, index) {
                                    final marketItem = _filteredCards[index];
                                    final card =
                                        model.Card.fromMap(marketItem['card']);

                                    // Verificar si es el vendedor
                                    final bool isCurrentUserSeller =
                                        marketItem['sellerId'] ==
                                            authProvider.user?.uid;

                                    return Container(
                                      margin:
                                          const EdgeInsets.only(bottom: 16.0),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            const Color(0xFF1A1A2E)
                                                .withOpacity(0.9),
                                            const Color(0xFF16213E)
                                                .withOpacity(0.8),
                                            const Color(0xFF0F3460)
                                                .withOpacity(0.9),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: _getRarityColor(card.rarity)
                                              .withOpacity(0.6),
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _getRarityColor(card.rarity)
                                                .withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.2),
                                            blurRadius: 12,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          // Header con efecto neón
                                          Container(
                                            height: 4,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  _getRarityColor(card.rarity)
                                                      .withOpacity(0.8),
                                                  _getRarityColor(card.rarity),
                                                  _getRarityColor(card.rarity)
                                                      .withOpacity(0.8),
                                                ],
                                              ),
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                top: Radius.circular(14),
                                              ),
                                            ),
                                          ),

                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Imagen de la carta con efecto holográfico
                                              Container(
                                                margin:
                                                    const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: _getRarityColor(
                                                              card.rarity)
                                                          .withOpacity(0.5),
                                                      blurRadius: 12,
                                                      offset:
                                                          const Offset(0, 4),
                                                    ),
                                                  ],
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child: Stack(
                                                    children: [
                                                      _buildCardImage(
                                                          card.imageUrl),
                                                      // Efecto holográfico
                                                      Positioned.fill(
                                                        child: Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                            gradient:
                                                                LinearGradient(
                                                              begin: Alignment
                                                                  .topLeft,
                                                              end: Alignment
                                                                  .bottomRight,
                                                              colors: [
                                                                _getRarityColor(card
                                                                        .rarity)
                                                                    .withOpacity(
                                                                        0.1),
                                                                Colors
                                                                    .transparent,
                                                                _getRarityColor(card
                                                                        .rarity)
                                                                    .withOpacity(
                                                                        0.1),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),

                                              // Información de la carta con diseño futurista
                                              Expanded(
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                      12.0),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      // Nombre de la carta
                                                      Text(
                                                        card.name,
                                                        style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white,
                                                          fontFamily:
                                                              'PrimalScream',
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),

                                                      // Fila con rareza y serie
                                                      Row(
                                                        children: [
                                                          // Rareza
                                                          Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                              horizontal: 10,
                                                              vertical: 4,
                                                            ),
                                                            decoration:
                                                                BoxDecoration(
                                                              gradient:
                                                                  LinearGradient(
                                                                colors: [
                                                                  _getRarityColor(
                                                                      card.rarity),
                                                                  _getRarityColor(card
                                                                          .rarity)
                                                                      .withOpacity(
                                                                          0.7),
                                                                ],
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12),
                                                              boxShadow: [
                                                                BoxShadow(
                                                                  color: _getRarityColor(card
                                                                          .rarity)
                                                                      .withOpacity(
                                                                          0.4),
                                                                  blurRadius: 4,
                                                                  offset:
                                                                      const Offset(
                                                                          0, 2),
                                                                ),
                                                              ],
                                                            ),
                                                            child: Text(
                                                              _getRarityText(
                                                                  card.rarity),
                                                              style:
                                                                  const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 11,
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 12),

                                                          // Serie
                                                          Expanded(
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          8,
                                                                      vertical:
                                                                          4),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: const Color(
                                                                        0xFF4FC3F7)
                                                                    .withOpacity(
                                                                        0.2),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8),
                                                                border:
                                                                    Border.all(
                                                                  color: const Color(
                                                                          0xFF4FC3F7)
                                                                      .withOpacity(
                                                                          0.5),
                                                                  width: 1,
                                                                ),
                                                              ),
                                                              child: InkWell(
                                                                onTap: () {
                                                                  setState(() {
                                                                    if (!_seriesFilter
                                                                        .contains(
                                                                            card.series)) {
                                                                      _seriesFilter =
                                                                          [
                                                                        card.series
                                                                      ];
                                                                      _applyFilters();
                                                                    }
                                                                  });
                                                                },
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: [
                                                                    const Icon(
                                                                      Icons
                                                                          .movie,
                                                                      color: Color(
                                                                          0xFF4FC3F7),
                                                                      size: 14,
                                                                    ),
                                                                    const SizedBox(
                                                                        width:
                                                                            4),
                                                                    Flexible(
                                                                      child:
                                                                          Text(
                                                                        card.series,
                                                                        style:
                                                                            const TextStyle(
                                                                          color:
                                                                              Color(0xFF4FC3F7),
                                                                          fontSize:
                                                                              11,
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                        ),
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(
                                                          height: 16),

                                                      // Fila inferior con precio y estado
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        children: [
                                                          // Precio
                                                          Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                              horizontal: 12,
                                                              vertical: 8,
                                                            ),
                                                            decoration:
                                                                BoxDecoration(
                                                              gradient:
                                                                  LinearGradient(
                                                                colors: [
                                                                  const Color(
                                                                          0xFFFFD700)
                                                                      .withOpacity(
                                                                          0.3),
                                                                  const Color(
                                                                          0xFFFFD700)
                                                                      .withOpacity(
                                                                          0.1),
                                                                ],
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12),
                                                              border:
                                                                  Border.all(
                                                                color: const Color(
                                                                        0xFFFFD700)
                                                                    .withOpacity(
                                                                        0.6),
                                                                width: 1,
                                                              ),
                                                              boxShadow: [
                                                                BoxShadow(
                                                                  color: const Color(
                                                                          0xFFFFD700)
                                                                      .withOpacity(
                                                                          0.3),
                                                                  blurRadius: 6,
                                                                  offset:
                                                                      const Offset(
                                                                          0, 2),
                                                                ),
                                                              ],
                                                            ),
                                                            child: Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                const Icon(
                                                                  Icons
                                                                      .monetization_on,
                                                                  color: Color(
                                                                      0xFFFFD700),
                                                                  size: 18,
                                                                ),
                                                                const SizedBox(
                                                                    width: 6),
                                                                Text(
                                                                  '${marketItem['price']}',
                                                                  style:
                                                                      const TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        16,
                                                                    color: Color(
                                                                        0xFFFFD700),
                                                                    fontFamily:
                                                                        'PrimalScream',
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),

                                                          // Estado "Tu carta" si aplica
                                                          if (isCurrentUserSeller)
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                horizontal: 8,
                                                                vertical: 4,
                                                              ),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Colors
                                                                    .purple
                                                                    .withOpacity(
                                                                        0.2),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8),
                                                                border:
                                                                    Border.all(
                                                                  color: Colors
                                                                      .purple
                                                                      .withOpacity(
                                                                          0.5),
                                                                  width: 1,
                                                                ),
                                                              ),
                                                              child: const Text(
                                                                'TU CARTA',
                                                                style:
                                                                    TextStyle(
                                                                  fontStyle:
                                                                      FontStyle
                                                                          .italic,
                                                                  color: Colors
                                                                      .purple,
                                                                  fontSize: 11,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),

                                          // Botón de compra con estilo gaming
                                          if (!isCurrentUserSeller)
                                            Container(
                                              width: double.infinity,
                                              margin:
                                                  const EdgeInsets.all(12.0),
                                              child: ElevatedButton(
                                                onPressed: () => _buyCard(
                                                    marketItem,
                                                    collectionProvider),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 16),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  elevation: 0,
                                                ).copyWith(
                                                  backgroundColor:
                                                      MaterialStateProperty.all(
                                                          Colors.transparent),
                                                ),
                                                child: Container(
                                                  width: double.infinity,
                                                  height: 50,
                                                  decoration: BoxDecoration(
                                                    gradient:
                                                        const LinearGradient(
                                                      colors: [
                                                        Color(0xFFFF5722),
                                                        Color(0xFFFF7043),
                                                        Color(0xFFFF5722),
                                                      ],
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: const Color(
                                                                0xFFFF5722)
                                                            .withOpacity(0.4),
                                                        blurRadius: 8,
                                                        offset:
                                                            const Offset(0, 4),
                                                      ),
                                                    ],
                                                  ),
                                                  child: const Center(
                                                    child: Text(
                                                      'COMPRAR CARTA',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                        fontFamily:
                                                            'PrimalScream',
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),

                                          // Botón de cancelar venta con estilo gaming
                                          if (isCurrentUserSeller)
                                            Container(
                                              width: double.infinity,
                                              margin:
                                                  const EdgeInsets.all(12.0),
                                              child: OutlinedButton(
                                                onPressed: () =>
                                                    _cancelSale(marketItem),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: Colors.red,
                                                  side: BorderSide(
                                                    color: Colors.red
                                                        .withOpacity(0.6),
                                                    width: 2,
                                                  ),
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 16),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  backgroundColor: Colors.red
                                                      .withOpacity(0.1),
                                                ),
                                                child: const Text(
                                                  'CANCELAR VENTA',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    fontFamily: 'PrimalScream',
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                      ),
                    ],
                  ),
      ),
      // FAB para vender una carta con diseño gaming mejorado
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 90.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFF5722),
                Color(0xFFFF7043),
                Color(0xFFFF5722),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF5722).withOpacity(0.6),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: const Color(0xFFFF5722).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showSellCardDialog(
                  context, collectionProvider, authProvider),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_shopping_cart,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'VENDER',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: Colors.white,
                            fontFamily: 'PrimalScream',
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Future<void> _buyCard(Map<String, dynamic> marketItem,
      CollectionProvider collectionProvider) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null) return;

    final bool userHasEnoughCoins =
        (collectionProvider.userCollection?.coins ?? 0) >= marketItem['price'];

    if (!userHasEnoughCoins) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('No tienes suficientes monedas para comprar esta carta'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _firestoreService.buyCard(
        authProvider.user!.uid,
        marketItem['marketId'],
      );

      if (success) {
        // Actualizar la colección del usuario
        await collectionProvider.loadUserCollection(authProvider.user!.uid);
        // Recargar el mercado
        await _loadMarketCards();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Carta comprada con éxito!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo completar la compra'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _cancelSale(Map<String, dynamic> marketItem) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _firestoreService.cancelCardSale(
        authProvider.user!.uid,
        marketItem['cardId'],
      );

      if (success) {
        // Actualizar la colección del usuario
        await Provider.of<CollectionProvider>(context, listen: false)
            .loadUserCollection(authProvider.user!.uid);
        // Recargar el mercado
        await _loadMarketCards();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Venta cancelada con éxito'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo cancelar la venta'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSellCardDialog(
    BuildContext context,
    CollectionProvider collectionProvider,
    AuthProvider authProvider,
  ) async {
    if (authProvider.user == null) {
      print('Error: Usuario no autenticado');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para vender cartas'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('Abriendo diálogo de venta. User ID: ${authProvider.user!.uid}');
    print(
        'Cartas del usuario cargadas: ${collectionProvider.userCardsWithDetails.length}');

    if (collectionProvider.userCardsWithDetails.isEmpty) {
      print('Error: No hay cartas cargadas en collectionProvider');

      // Intentamos recargar la colección del usuario
      await collectionProvider.loadUserCollection(authProvider.user!.uid);

      // Verificamos si se cargaron las cartas
      if (collectionProvider.userCardsWithDetails.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'No tienes cartas para vender. Por favor, recarga la aplicación.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Obtener IDs reales de las cartas en la colección del usuario
    final userCollection = collectionProvider.userCollection;
    if (userCollection != null) {
      print(
          '🔍 IDs de cartas en la colección: ${userCollection.cards.keys.toList()}');
    }

    // Filtrar cartas que tengan al menos 1 disponible y no estén ya a la venta
    final sellableCards = collectionProvider.userCardsWithDetails.where((item) {
      final userCard = item['userCard'];
      return userCard.quantity >= 1 && !userCard.isForSale;
    }).toList();

    if (sellableCards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes cartas disponibles para vender'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('Cartas vendibles encontradas: ${sellableCards.length}');

    // Extraer el userCard de cada elemento para acceder al verdadero ID
    for (int i = 0; i < sellableCards.length; i++) {
      final item = sellableCards[i];
      final userCard = item['userCard'] as UserCard;
      final cardDetail = item['cardDetail'] as model.Card;

      // Mostrar información del ID real vs ID de detalle
      print('Carta #$i: ${cardDetail.name}');
      print('  - ID en userCard: ${userCard.cardId}');
      print('  - ID en cardDetail: ${cardDetail.id}');

      // Si el ID de cardDetail está vacío pero el userCard tiene ID válido,
      // actualizar el cardDetail con el ID correcto
      if (cardDetail.id.isEmpty && userCard.cardId.isNotEmpty) {
        print(
            '  ✅ Actualizando ID vacío con ID de userCard: ${userCard.cardId}');
        final updatedCard = model.Card(
          id: userCard.cardId,
          name: cardDetail.name,
          description: cardDetail.description,
          imageUrl: cardDetail.imageUrl,
          rarity: cardDetail.rarity,
          type: cardDetail.type,
          stats: cardDetail.stats,
          power: cardDetail.power,
          abilities: cardDetail.abilities,
          tags: cardDetail.tags,
          series: cardDetail.series,
        );

        // Reemplazar la carta en el mapa
        sellableCards[i]['cardDetail'] = updatedCard;
      }
    }

    // Mapa para almacenar cartas vendibles por ID para acceso fácil
    final Map<String, Map<String, dynamic>> cardMap = {};
    for (final item in sellableCards) {
      final card = item['cardDetail'] as model.Card;
      final userCard = item['userCard'] as UserCard;
      // Usar el ID de userCard que es el real
      cardMap[userCard.cardId] = item;
    }

    // Código reescrito para utilizar un StatefulWidget dentro del diálogo
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A1A2E),
                  Color(0xFF16213E),
                  Color(0xFF0F3460),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header con título e icono
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFF5722).withOpacity(0.8),
                        const Color(0xFFFF7043).withOpacity(0.6),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Icono de fondo decorativo
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20)),
                          child: Opacity(
                            opacity: 0.1,
                            child: Icon(
                              Icons.sell,
                              size: 150,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      // Contenido del header
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          children: [
                            // Icono principal
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.add_shopping_cart,
                                size: 48,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Información del header
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Vender Carta',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontFamily: 'PrimalScream',
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${sellableCards.length} cartas disponibles',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Botón cerrar
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Contenido scrolleable
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _SellCardDialogContent(
                      sellableCards: sellableCards,
                      cardMap: cardMap,
                      onSell: (String cardId, int price) async {
                        print('Intentando vender carta: $cardId por $price');

                        // Mostrar indicador de carga
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (ctx) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );

                        // Intentar vender la carta con el ID real
                        final success = await _firestoreService.putCardForSale(
                          authProvider.user!.uid,
                          cardId,
                          price,
                        );

                        // Cerrar el indicador de carga
                        Navigator.of(context).pop();

                        // Cerrar el diálogo de venta
                        Navigator.of(dialogContext).pop();

                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Carta puesta a la venta exitosamente'),
                            ),
                          );
                          // Recargar datos
                          await collectionProvider
                              .loadUserCollection(authProvider.user!.uid);
                          await _loadMarketCards();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Error al poner la carta a la venta'),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filtrar cartas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _seriesFilter = [];
                            _rarityFilter = [];
                            _typeFilter = [];
                            _priceRange = const RangeValues(0, 1000);
                          });
                        },
                        child: const Text('Limpiar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Filtro por series
                  const Text(
                    'Series:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 0,
                    children: _availableSeries.map((series) {
                      final isSelected = _seriesFilter.contains(series);
                      return FilterChip(
                        label: Text(series),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _seriesFilter.add(series);
                            } else {
                              _seriesFilter.remove(series);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Filtro por rarezas
                  const Text(
                    'Rarezas:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 0,
                    children: model.CardRarity.values.map((rarity) {
                      final isSelected = _rarityFilter.contains(rarity);
                      return FilterChip(
                        label: Text(_getRarityText(rarity)),
                        selected: isSelected,
                        selectedColor: _getRarityColor(rarity).withOpacity(0.2),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _rarityFilter.add(rarity);
                            } else {
                              _rarityFilter.remove(rarity);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Filtro por tipo
                  const Text(
                    'Tipo de carta:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 0,
                    children: model.CardType.values.map((type) {
                      final isSelected = _typeFilter.contains(type);
                      return FilterChip(
                        label: Text(_getTypeText(type)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _typeFilter.add(type);
                            } else {
                              _typeFilter.remove(type);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Filtro por rango de precio
                  const Text(
                    'Rango de precio:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(_priceRange.start.toInt().toString()),
                      Expanded(
                        child: RangeSlider(
                          values: _priceRange,
                          min: 0,
                          max: 1000,
                          divisions: 20,
                          labels: RangeLabels(
                            _priceRange.start.toInt().toString(),
                            _priceRange.end.toInt().toString(),
                          ),
                          onChanged: (values) {
                            setState(() {
                              _priceRange = values;
                            });
                          },
                        ),
                      ),
                      Text(_priceRange.end.toInt().toString()),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Botones
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          _applyFilters();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5722),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Aplicar'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// Widget separado para el contenido del diálogo de venta
class _SellCardDialogContent extends StatefulWidget {
  final List<Map<String, dynamic>> sellableCards;
  final Map<String, Map<String, dynamic>> cardMap;
  final Function(String cardId, int price) onSell;

  const _SellCardDialogContent({
    required this.sellableCards,
    required this.cardMap,
    required this.onSell,
  });

  @override
  _SellCardDialogContentState createState() => _SellCardDialogContentState();
}

class _SellCardDialogContentState extends State<_SellCardDialogContent> {
  int? selectedIndex;
  int price = 10;
  bool isSelling = false;

  @override
  void initState() {
    super.initState();
    // Imprimir información de todas las cartas para depuración
    for (var i = 0; i < widget.sellableCards.length; i++) {
      final item = widget.sellableCards[i];
      final card = item['cardDetail'] as model.Card;
      print('Carta disponible [$i]: ID=${card.id}, Nombre=${card.name}');

      // Verificar y mostrar advertencia si alguna carta tiene ID vacío
      if (card.id.isEmpty) {
        print(
            '⚠️ ADVERTENCIA: Carta ${card.name} en posición $i tiene ID vacío');
      }
    }
  }

  String? getCardId(int index) {
    if (index < 0 || index >= widget.sellableCards.length) return null;

    final selectedCard = widget.sellableCards[index];
    // Obtener primero el UserCard que tiene el ID real de la carta
    final userCard = selectedCard['userCard'];

    if (userCard is UserCard) {
      final id = userCard.cardId;
      if (id.isEmpty) {
        print(
            '⚠️ ADVERTENCIA: getCardId - La carta en índice $index tiene ID de userCard vacío');
        // Si userCard no tiene ID, intentamos con el cardDetail
        final cardDetail = selectedCard['cardDetail'];
        if (cardDetail is model.Card && cardDetail.id.isNotEmpty) {
          print('  ✅ Usando ID de cardDetail como respaldo: ${cardDetail.id}');
          return cardDetail.id;
        }
        return null;
      }
      print('✅ Usando ID real de userCard: $id');
      return id;
    } else {
      print(
          'ERROR: El objeto userCard no es una instancia de UserCard: ${userCard.runtimeType}');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sección de selección de carta
        _buildInfoSection(
          'Selecciona una carta',
          Icons.style,
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.sellableCards.length,
              itemBuilder: (context, index) {
                final item = widget.sellableCards[index];
                final card = item['cardDetail'] as model.Card;
                final userCard = item['userCard'];

                final isSelected = selectedIndex == index;
                final rarityColor = _getRarityColor(card.rarity);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? rarityColor.withOpacity(0.2)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? rarityColor
                          : Colors.white.withOpacity(0.1),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: rarityColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      final cardId = card.id;
                      final userCardId = userCard.cardId;
                      print(
                          'Seleccionando carta índice [$index]: ${card.name}');
                      print('  - ID en card: $cardId');
                      print('  - ID real en userCard: $userCardId');

                      setState(() {
                        selectedIndex = (selectedIndex == index) ? null : index;
                      });

                      if (selectedIndex != null) {
                        final selectedId = getCardId(selectedIndex!);
                        print(
                            'Después de selección - Índice: $selectedIndex, ID a usar: $selectedId');
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          // Imagen de la carta
                          Container(
                            width: 60,
                            height: 84,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: rarityColor.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _buildCardImage(card.imageUrl),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Indicador de selección con animación
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  isSelected ? rarityColor : Colors.transparent,
                              border: Border.all(
                                color:
                                    isSelected ? rarityColor : Colors.white30,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),

                          // Información de la carta
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  card.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: rarityColor.withOpacity(0.3),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: rarityColor.withOpacity(0.6),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          _getRarityText(card.rarity),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: rarityColor,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      Icons.inventory,
                                      size: 14,
                                      color: Colors.white70,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        'Cant: ${userCard.quantity}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Sección de precio
        _buildInfoSection(
          'Establece el precio',
          Icons.monetization_on,
          Column(
            children: [
              TextField(
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Ingresa el precio de venta',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(
                    Icons.monetization_on,
                    color: Color(0xFFFFD700),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFFF5722),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                ),
                onChanged: (value) {
                  setState(() {
                    price = int.tryParse(value) ?? 0;
                    print('Precio actualizado: $price');
                  });
                },
              ),
              if (price > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFFFD700).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFFFFD700),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Recibirás $price monedas por esta venta',
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Botones de acción
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: (selectedIndex != null && price > 0 && !isSelling)
                    ? () {
                        final String? cardId = getCardId(selectedIndex!);
                        print(
                            'Enviando venta - Índice: $selectedIndex, CardID: $cardId, Precio: $price');

                        if (cardId == null || cardId.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Error: ID de carta inválido')),
                          );
                          return;
                        }

                        setState(() {
                          isSelling = true;
                        });

                        widget.onSell(cardId, price);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5722),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: isSelling
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Poner en Venta',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoSection(String title, IconData icon, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFFFF5722),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'PrimalScream',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: content,
        ),
      ],
    );
  }

  // Método para construir la imagen de la carta (maneja URL y base64)
  Widget _buildCardImage(String imageUrl) {
    // Verificar si la imagen está en formato base64
    final imageBytes = _getImageBytes(imageUrl);

    if (imageBytes != null) {
      // Si es base64, mostrar usando Image.memory
      return Image.memory(
        imageBytes,
        width: 60,
        height: 84,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 60,
            height: 84,
            color: Colors.grey.shade300,
            child: const Icon(
              Icons.broken_image,
              color: Colors.grey,
              size: 20,
            ),
          );
        },
      );
    } else {
      // Si es URL, mostrar usando Image.network
      return Image.network(
        imageUrl,
        width: 60,
        height: 84,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 60,
            height: 84,
            color: Colors.grey.shade300,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 60,
            height: 84,
            color: Colors.grey.shade300,
            child: const Icon(
              Icons.broken_image,
              color: Colors.grey,
              size: 20,
            ),
          );
        },
      );
    }
  }

  // Método para extraer los bytes de la imagen de un string base64
  Uint8List? _getImageBytes(String url) {
    if (url.startsWith('data:')) {
      final parts = url.split(',');
      if (parts.length > 1) {
        try {
          return base64Decode(parts[1]);
        } catch (e) {
          return null;
        }
      }
    }
    return null;
  }
}

Color _getRarityColor(model.CardRarity rarity) {
  switch (rarity) {
    case model.CardRarity.common:
      return Colors.grey;
    case model.CardRarity.uncommon:
      return Colors.green;
    case model.CardRarity.rare:
      return Colors.blue;
    case model.CardRarity.superRare:
      return Colors.purple;
    case model.CardRarity.ultraRare:
      return Colors.orange;
    case model.CardRarity.legendary:
      return Colors.red;
  }
}

String _getRarityText(model.CardRarity rarity) {
  switch (rarity) {
    case model.CardRarity.common:
      return 'Común';
    case model.CardRarity.uncommon:
      return 'Poco común';
    case model.CardRarity.rare:
      return 'Rara';
    case model.CardRarity.superRare:
      return 'Super rara';
    case model.CardRarity.ultraRare:
      return 'Ultra rara';
    case model.CardRarity.legendary:
      return 'Legendaria';
  }
}

String _getTypeText(model.CardType type) {
  switch (type) {
    case model.CardType.character:
      return 'Personaje';
    case model.CardType.support:
      return 'Soporte';
    case model.CardType.event:
      return 'Evento';
    case model.CardType.equipment:
      return 'Equipamiento';
  }
}
