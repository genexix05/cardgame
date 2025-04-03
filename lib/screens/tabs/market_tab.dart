import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/collection_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/card.dart' as model;

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
  String? _errorMessage;

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
      final cards = await _firestoreService.getCardsForSale();
      setState(() {
        _cardsForSale = cards;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Error al cargar el mercado: ${e.toString()}";
        _isLoading = false;
      });
    }
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

                    // Lista de cartas en venta
                    Expanded(
                      child: _cardsForSale.isEmpty
                          ? const Center(
                              child: Text(
                                'No hay cartas a la venta en este momento',
                                style: TextStyle(fontSize: 16),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadMarketCards,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16.0),
                                itemCount: _cardsForSale.length,
                                itemBuilder: (context, index) {
                                  final marketItem = _cardsForSale[index];
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
                                              child: Image.network(
                                                card.imageUrl,
                                                width: 100,
                                                height: 100,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                    stackTrace) {
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
                                              ),
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
                                                    Text(
                                                      'Serie: ${card.series}',
                                                      style: TextStyle(
                                                        color: Colors
                                                            .grey.shade700,
                                                        fontSize: 14,
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

  Future<void> _showSellCardDialog(
    BuildContext context,
    CollectionProvider collectionProvider,
    AuthProvider authProvider,
  ) async {
    if (authProvider.user == null ||
        collectionProvider.userCardsWithDetails.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes cartas para vender'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Filtrar para mostrar solo cartas con cantidad > 1
    final sellableCards = collectionProvider.userCardsWithDetails.where((item) {
      final userCard = item['userCard'];
      return userCard.quantity > 1 && !userCard.isForSale;
    }).toList();

    if (sellableCards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'No tienes cartas disponibles para vender. Debes tener al menos 2 copias de una carta para poder venderla.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String? selectedCardId;
    int price = 100; // Precio predeterminado

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Vender carta'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Selecciona una carta para vender:'),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: sellableCards.length,
                        itemBuilder: (context, index) {
                          final item = sellableCards[index];
                          final card = item['cardDetail'] as model.Card;
                          final userCard = item['userCard'];

                          return RadioListTile<String>(
                            title: Text(card.name),
                            subtitle: Text(
                                '${_getRarityText(card.rarity)} - Cantidad: ${userCard.quantity}'),
                            value: card.id,
                            groupValue: selectedCardId,
                            onChanged: (value) {
                              setState(() {
                                selectedCardId = value;
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Establece un precio:'),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: price > 50
                              ? () {
                                  setState(() {
                                    price -= 50;
                                  });
                                }
                              : null,
                        ),
                        Expanded(
                          child: Slider(
                            value: price.toDouble(),
                            min: 50,
                            max: 1000,
                            divisions: 19,
                            label: price.toString(),
                            onChanged: (value) {
                              setState(() {
                                price = value.round();
                              });
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: price < 1000
                              ? () {
                                  setState(() {
                                    price += 50;
                                  });
                                }
                              : null,
                        ),
                      ],
                    ),
                    Text(
                      'Precio: $price monedas',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: selectedCardId == null
                      ? null
                      : () {
                          Navigator.of(context).pop(true);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5722),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Vender'),
                ),
              ],
            );
          },
        );
      },
    ).then((confirmed) async {
      if (confirmed == true && selectedCardId != null) {
        setState(() {
          _isLoading = true;
        });

        try {
          final success = await _firestoreService.putCardForSale(
            authProvider.user!.uid,
            selectedCardId!,
            price,
          );

          if (success) {
            // Actualizar la colección del usuario
            await collectionProvider.loadUserCollection(authProvider.user!.uid);
            // Recargar el mercado
            await _loadMarketCards();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Carta puesta a la venta con éxito'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No se pudo poner la carta a la venta'),
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
    });
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
}
