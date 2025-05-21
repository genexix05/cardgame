import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/collection_provider.dart';
import '../../widgets/card_grid.dart';
import '../../models/card.dart' as model;
import '../../models/user_collection.dart';
import '../../services/firestore_service.dart';
import 'dart:convert';

class CollectionTab extends StatefulWidget {
  const CollectionTab({super.key});

  @override
  _CollectionTabState createState() => _CollectionTabState();
}

class _CollectionTabState extends State<CollectionTab>
    with AutomaticKeepAliveClientMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final bool _isLoading = false;
  final List<Map<String, dynamic>> _userCards = [];
  final List<model.Card> _cards = [];
  final List<model.Card> _filteredCards = [];
  final List<model.Card> _favouriteCards = [];
  final Map<String, dynamic> _userCardMap = {};
  String? _errorMessage;

  // Filtros
  String _searchQuery = '';
  final List<String> _seriesFilter = [];
  final List<model.CardRarity> _rarityFilter = [];
  final List<model.CardType> _typeFilter = [];
  final bool _onlyFavourites = false;

  // Para la lista desplegable de series
  final List<String> _availableSeries = [];

  // Método para construir la imagen de la carta (maneja URL y base64)
  Widget _buildCardImage(String imageUrl) {
    // Verificar si la imagen está en formato base64
    final imageBytes = _getImageBytes(imageUrl);

    if (imageBytes != null) {
      // Si es base64, mostrar usando Image.memory
      return Image.memory(
        imageBytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
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
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
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

    // Cargamos la colección en initState en lugar de durante el build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCollection();
    });
  }

  // Cargar la colección del usuario
  Future<void> _loadCollection() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final collectionProvider =
        Provider.of<CollectionProvider>(context, listen: false);

    if (authProvider.isAuthenticated && authProvider.user != null) {
      await collectionProvider.loadUserCollection(authProvider.user!.uid);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final collectionProvider = Provider.of<CollectionProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Colección'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: CardSearchDelegate(
                    collectionProvider.userCardsWithDetails, _userCardMap),
              );
            },
          ),
        ],
      ),
      body: collectionProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : collectionProvider.userCollection == null
              ? const Center(child: Text('No se pudo cargar la colección'))
              : Column(
                  children: [
                    // Información de la colección
                    Card(
                      margin: const EdgeInsets.all(16.0),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Text(
                                  'Cartas',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${collectionProvider.userCardsWithDetails.length}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFF5722),
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                const Text(
                                  'Monedas',
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
                            Column(
                              children: [
                                const Text(
                                  'Gemas',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${collectionProvider.userCollection?.gems ?? 0}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E88E5),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Filtros
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          _buildFilterChip('Todas'),
                          _buildFilterChip('Favoritas'),
                          _buildFilterChip('Comunes'),
                          _buildFilterChip('Poco comunes'),
                          _buildFilterChip('Raras'),
                          _buildFilterChip('Super raras'),
                          _buildFilterChip('Ultra raras'),
                          _buildFilterChip('Legendarias'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Grid de cartas
                    Expanded(
                      child: collectionProvider.userCardsWithDetails.isEmpty
                          ? const Center(
                              child: Text(
                                'No tienes cartas en tu colección.\n¡Abre sobres para conseguir algunas!',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 16),
                              ),
                            )
                          : CardGrid(
                              cards: _filterCards(collectionProvider),
                              onCardTap: (cardDetails) {
                                _showCardDetail(cardDetails);
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildFilterChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: _searchQuery == label,
        onSelected: (selected) {
          setState(() {
            _searchQuery = selected ? label : '';
          });
        },
        selectedColor: const Color(0xFFFF5722).withOpacity(0.3),
        checkmarkColor: const Color(0xFFFF5722),
      ),
    );
  }

  List<Map<String, dynamic>> _filterCards(CollectionProvider provider) {
    List<Map<String, dynamic>> filteredCards =
        List.from(provider.userCardsWithDetails);

    // Aplicar filtro seleccionado
    if (_searchQuery.isNotEmpty) {
      filteredCards = filteredCards.where((card) {
        final cardDetail = card['cardDetail'] as model.Card;
        return cardDetail.name
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            cardDetail.description
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            cardDetail.series
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return filteredCards;
  }

  // Mostrar detalles de una carta
  void _showCardDetail(Map<String, dynamic> cardMap) {
    final card = cardMap['cardDetail'] as model.Card;
    final userCard = cardMap['userCard'] as UserCard;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Barra de control
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 16),
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),

                  // Imagen de la carta
                  SizedBox(
                    height: 250,
                    width: double.infinity,
                    child: _buildCardImage(card.imageUrl),
                  ),

                  // Detalles de la carta
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                card.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getRarityColor(card.rarity),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getRarityText(card.rarity),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Serie y tipo
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Serie',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    card.series,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Tipo',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getCardTypeText(card.type),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Poder y cantidad
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Poder',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.flash_on,
                                        color: Color(0xFFFF5722),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${card.power}',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Cantidad',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'x${userCard.quantity}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Descripción
                        const Text(
                          'Descripción',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          card.description,
                          style: const TextStyle(fontSize: 16),
                        ),

                        const SizedBox(height: 24),

                        // Acciones
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Botón de favorito
                            _buildActionButton(
                              icon: userCard.isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: userCard.isFavorite
                                  ? Colors.red
                                  : Colors.grey,
                              text: userCard.isFavorite
                                  ? 'Quitar favorito'
                                  : 'Añadir a favoritos',
                              onTap: () => _toggleFavorite(card.id),
                            ),

                            // Botón de vender (solo si tiene más de 1)
                            if (userCard.quantity > 1)
                              _buildActionButton(
                                icon: Icons.sell,
                                color: const Color(0xFFFF5722),
                                text: 'Vender',
                                onTap: () => _sellCard(card.id),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(text, style: TextStyle(color: color)),
          ],
        ),
      ),
    );
  }

  String _getCardTypeText(model.CardType type) {
    switch (type) {
      case model.CardType.character:
        return 'Personaje';
      case model.CardType.equipment:
        return 'Equipamiento';
      case model.CardType.event:
        return 'Evento';
      case model.CardType.support:
        return 'Soporte';
    }
  }

  // Marcar/desmarcar carta como favorita
  Future<void> _toggleFavorite(String cardId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final collectionProvider =
        Provider.of<CollectionProvider>(context, listen: false);

    if (authProvider.user == null) return;

    try {
      await _firestoreService.toggleCardFavorite(
          authProvider.user!.uid, cardId);

      // Recargar la colección para reflejar los cambios
      await collectionProvider.loadUserCollection(authProvider.user!.uid);

      if (mounted) {
        Navigator.pop(context); // Cerrar el modal
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Estado de favorito actualizado!'),
            backgroundColor: Colors.green,
          ),
        );
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
    }
  }

  // Vender carta
  Future<void> _sellCard(String cardId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.user == null) return;

    Navigator.pop(context); // Cerrar el modal de detalles

    // Mostrar diálogo de venta directamente
    _showSellDialog(cardId);
  }

  // Mostrar diálogo de venta simple
  Future<void> _showSellDialog(String cardId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final collectionProvider =
        Provider.of<CollectionProvider>(context, listen: false);

    if (authProvider.user == null) return;

    int price = 100; // Precio predeterminado

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Vender carta'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Establece un precio para vender esta carta:'),
                  const SizedBox(height: 16),
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
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
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
      if (confirmed == true) {
        try {
          final success = await _firestoreService.putCardForSale(
            authProvider.user!.uid,
            cardId,
            price,
          );

          if (success) {
            // Recargar la colección para reflejar los cambios
            await collectionProvider.loadUserCollection(authProvider.user!.uid);

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('¡Carta puesta a la venta con éxito!'),
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

// Delegado para la búsqueda de cartas
class CardSearchDelegate extends SearchDelegate<model.Card?> {
  final List<Map<String, dynamic>> cards;
  final Map<String, dynamic> userCardMap;

  CardSearchDelegate(this.cards, this.userCardMap);

  // Método para construir la imagen de la carta (maneja URL y base64)
  Widget _buildCardImage(String imageUrl) {
    // Verificar si la imagen está en formato base64
    final imageBytes = _getImageBytes(imageUrl);

    if (imageBytes != null) {
      // Si es base64, mostrar usando Image.memory
      return Image.memory(
        imageBytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
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
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
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
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Text('Busca por nombre, descripción o serie'),
      );
    }

    final filteredCards = cards.where((card) {
      final cardDetail = card['cardDetail'] as model.Card;
      return cardDetail.name.toLowerCase().contains(query.toLowerCase()) ||
          cardDetail.description.toLowerCase().contains(query.toLowerCase()) ||
          cardDetail.series.toLowerCase().contains(query.toLowerCase());
    }).toList();

    if (filteredCards.isEmpty) {
      return const Center(
        child: Text('No se encontraron cartas que coincidan con la búsqueda'),
      );
    }

    return CardGrid(
      cards: filteredCards,
      onCardTap: (cardDetails) {
        // Cerrar el diálogo de búsqueda con el contexto proporcionado
        close(context, cardDetails['cardDetail'] as model.Card?);

        // Usar el contexto proporcionado para abrir el modal de detalles
        // después de un breve retardo para asegurar que la búsqueda se haya cerrado
        Future.delayed(const Duration(milliseconds: 100), () {
          if (context.mounted) {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (modalContext) {
                // Extraer los datos de la carta
                final card = cardDetails['cardDetail'] as model.Card;
                final userCard = cardDetails['userCard'] as UserCard;

                return DraggableScrollableSheet(
                  initialChildSize: 0.7,
                  maxChildSize: 0.9,
                  minChildSize: 0.5,
                  expand: false,
                  builder: (context, scrollController) {
                    return SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Barra de control
                          Center(
                            child: Container(
                              margin: const EdgeInsets.only(top: 8, bottom: 16),
                              width: 40,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),

                          // Imagen de la carta
                          SizedBox(
                            height: 250,
                            width: double.infinity,
                            child: _buildCardImage(card.imageUrl),
                          ),

                          // Información básica de la carta
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  card.name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  card.description,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color:
                                          _getRarityColor(card.rarity, context),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _getRarityText(card.rarity, context),
                                      style: TextStyle(
                                        color: _getRarityColor(
                                            card.rarity, context),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      'Cantidad: ${userCard.quantity}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          }
        });
      },
    );
  }

  // Funciones auxiliares para usar dentro del SearchDelegate
  Color _getRarityColor(model.CardRarity rarity, BuildContext context) {
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

  String _getRarityText(model.CardRarity rarity, BuildContext context) {
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
