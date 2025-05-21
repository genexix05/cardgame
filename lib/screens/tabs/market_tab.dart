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
        title: const Text('Mercado de Cartas'),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : Column(
                  children: [
                    // Información del usuario
                    Card(
                      margin: const EdgeInsets.all(16.0),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Column(
                              children: [
                                const Text(
                                  'Tus monedas',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${collectionProvider.userCollection?.coins ?? 0}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFFD700),
                                  ),
                                ),
                              ],
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
                                  backgroundColor:
                                      _getRarityColor(rarity).withOpacity(0.2),
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
                            if (_priceRange.start > 0 || _priceRange.end < 1000)
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

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 16.0),
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: _getRarityColor(card.rarity)
                                            .withOpacity(0.5),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Imagen de la carta
                                            ClipRRect(
                                              borderRadius:
                                                  const BorderRadius.only(
                                                topLeft: Radius.circular(12),
                                                bottomLeft: Radius.circular(12),
                                              ),
                                              child: _buildCardImage(
                                                  card.imageUrl),
                                            ),

                                            // Información de la carta
                                            Expanded(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(12.0),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            card.name,
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                          decoration:
                                                              BoxDecoration(
                                                            color:
                                                                _getRarityColor(
                                                                    card.rarity),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                          ),
                                                          child: Text(
                                                            _getRarityText(
                                                                card.rarity),
                                                            style:
                                                                const TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    InkWell(
                                                      onTap: () {
                                                        // Filtrar por esta serie al hacer tap
                                                        setState(() {
                                                          if (!_seriesFilter
                                                              .contains(card
                                                                  .series)) {
                                                            _seriesFilter = [
                                                              card.series
                                                            ];
                                                            _applyFilters();
                                                          }
                                                        });
                                                      },
                                                      child: Row(
                                                        children: [
                                                          const Icon(
                                                              Icons.movie,
                                                              size: 14),
                                                          const SizedBox(
                                                              width: 4),
                                                          Text(
                                                            'Serie: ${card.series}',
                                                            style: TextStyle(
                                                              color: Colors.grey
                                                                  .shade700,
                                                              fontSize: 14,
                                                              decoration:
                                                                  TextDecoration
                                                                      .underline,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Row(
                                                      children: [
                                                        const Icon(
                                                          Icons.flash_on,
                                                          color:
                                                              Color(0xFFFF5722),
                                                          size: 16,
                                                        ),
                                                        const SizedBox(
                                                            width: 4),
                                                        Text(
                                                          'Poder: ${card.power}',
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: const Color(
                                                                    0xFFFFD700)
                                                                .withOpacity(
                                                                    0.2),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                          ),
                                                          child: Row(
                                                            children: [
                                                              const Icon(
                                                                Icons
                                                                    .monetization_on,
                                                                color: Color(
                                                                    0xFFFFD700),
                                                                size: 16,
                                                              ),
                                                              const SizedBox(
                                                                  width: 4),
                                                              Text(
                                                                '${marketItem['price']}',
                                                                style:
                                                                    const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        if (isCurrentUserSeller)
                                                          const Text(
                                                            'Tu carta',
                                                            style: TextStyle(
                                                              fontStyle:
                                                                  FontStyle
                                                                      .italic,
                                                              color:
                                                                  Colors.grey,
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

                                        // Botón de compra
                                        if (!isCurrentUserSeller)
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(12.0),
                                            child: ElevatedButton(
                                              onPressed: () => _buyCard(
                                                  marketItem,
                                                  collectionProvider),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    const Color(0xFFFF5722),
                                                foregroundColor: Colors.white,
                                              ),
                                              child:
                                                  const Text('Comprar carta'),
                                            ),
                                          ),

                                        // Botón de cancelar venta si es el vendedor
                                        if (isCurrentUserSeller)
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(12.0),
                                            child: OutlinedButton(
                                              onPressed: () =>
                                                  _cancelSale(marketItem),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.red,
                                                side: const BorderSide(
                                                    color: Colors.red),
                                              ),
                                              child:
                                                  const Text('Cancelar venta'),
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

      // FAB para vender una carta
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            _showSellCardDialog(context, collectionProvider, authProvider),
        backgroundColor: const Color(0xFFFF5722),
        child: const Icon(Icons.sell),
      ),
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
      builder: (BuildContext dialogContext) {
        return _SellCardDialogContent(
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
                  content: Text('Carta puesta a la venta exitosamente'),
                ),
              );
              // Recargar datos
              await collectionProvider
                  .loadUserCollection(authProvider.user!.uid);
              await _loadMarketCards();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Error al poner la carta a la venta'),
                ),
              );
            }
          },
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
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vender carta',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Selecciona una carta para vender:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10.0),

            // Lista de cartas (limitada en altura)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.sellableCards.length,
                itemBuilder: (context, index) {
                  final item = widget.sellableCards[index];
                  final card = item['cardDetail'] as model.Card;
                  final userCard = item['userCard'];

                  // Generar un color basado en la selección
                  final isSelected = selectedIndex == index;
                  final backgroundColor = isSelected
                      ? _getRarityColor(card.rarity).withOpacity(0.2)
                      : Colors.transparent;

                  return Card(
                    color: backgroundColor,
                    elevation: isSelected ? 4 : 1,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: InkWell(
                      onTap: () {
                        // Registrar detalladamente la selección
                        final cardId = card.id;
                        final userCardId = userCard.cardId;
                        print(
                            'Seleccionando carta índice [$index]: ${card.name}');
                        print('  - ID en card: $cardId');
                        print('  - ID real en userCard: $userCardId');

                        setState(() {
                          selectedIndex =
                              (selectedIndex == index) ? null : index;
                        });

                        // Verificación adicional
                        if (selectedIndex != null) {
                          final selectedId = getCardId(selectedIndex!);
                          print(
                              'Después de selección - Índice: $selectedIndex, ID a usar: $selectedId');
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            // Indicador de selección
                            Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: isSelected ? Colors.green : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            // Información de la carta
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    card.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Rareza: ${_getRarityText(card.rarity)} • Cantidad: ${userCard.quantity}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
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

            const SizedBox(height: 16.0),
            const Text(
              'Precio de venta:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ingresa el precio',
                prefixIcon: Icon(Icons.monetization_on),
              ),
              onChanged: (value) {
                setState(() {
                  price = int.tryParse(value) ?? 0;
                  print('Precio actualizado: $price');
                });
              },
            ),

            const SizedBox(height: 20.0),
            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8.0),
                ElevatedButton(
                  onPressed: (selectedIndex != null && price > 0 && !isSelling)
                      ? () {
                          // Obtener el ID de la carta directamente usando nuestra función auxiliar
                          final String? cardId = getCardId(selectedIndex!);

                          print(
                              'Enviando venta - Índice: $selectedIndex, CardID: $cardId, Precio: $price');

                          // Verificar que el ID no esté vacío
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
                      : const Text('Vender'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
