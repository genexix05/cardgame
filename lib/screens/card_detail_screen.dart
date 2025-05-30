import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../models/card.dart' as model;
import '../models/card_pack.dart';
import '../services/firestore_service.dart';
import '../providers/collection_provider.dart';

class CardDetailScreen extends StatefulWidget {
  final List<model.Card> cards;
  final int initialIndex;

  const CardDetailScreen({
    super.key,
    required this.cards,
    required this.initialIndex,
  });

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen>
    with TickerProviderStateMixin {
  List<CardPack> _availablePacks = [];
  bool _isLoadingPacks = true;
  late PageController _pageController;
  late int _currentIndex;
  AnimationController? _lightSweepController;
  Animation<double>? _lightSweepAnimation;

  model.Card get currentCard => widget.cards[_currentIndex];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);

    // Inicializar el controlador de animación para el light sweep
    _lightSweepController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _lightSweepAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _lightSweepController!,
      curve: Curves.easeInOut,
    ));

    // Iniciar la animación y repetirla
    _startLightSweepAnimation();

    _loadAvailablePacks();
  }

  void _startLightSweepAnimation() {
    _lightSweepController?.repeat(
      period: const Duration(seconds: 4),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _lightSweepController?.dispose();
    super.dispose();
  }

  Future<void> _loadAvailablePacks() async {
    try {
      final firestoreService =
          Provider.of<FirestoreService>(context, listen: false);

      // Obtener solo los sobres que contienen esta carta específica
      final packsWithCard =
          await firestoreService.getPacksContainingCard(currentCard.id);

      setState(() {
        _availablePacks = packsWithCard;
        _isLoadingPacks = false;
      });
    } catch (e) {
      print('Error cargando sobres: $e');
      setState(() {
        _isLoadingPacks = false;
      });
    }
  }

  // Método para construir la imagen de la carta con efecto light sweep
  Widget _buildCardImage(String imageUrl) {
    final imageBytes = _getImageBytes(imageUrl);

    Widget cardImage;
    if (imageBytes != null) {
      cardImage = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          imageBytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: const Icon(
                Icons.image_not_supported,
                color: Colors.grey,
                size: 100,
              ),
            );
          },
        ),
      );
    } else {
      cardImage = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey[300],
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: const Icon(
                Icons.image_not_supported,
                color: Colors.grey,
                size: 100,
              ),
            );
          },
        ),
      );
    }

    // Verificar si la animación está inicializada antes de usarla
    if (_lightSweepController == null || _lightSweepAnimation == null) {
      return cardImage;
    }

    // Envolver la imagen con el efecto light sweep
    return AnimatedBuilder(
      animation: _lightSweepAnimation!,
      builder: (context, child) {
        return Stack(
          children: [
            // Imagen de la carta
            cardImage,
            // Efecto light sweep
            Positioned.fill(
              child: ClipRect(
                child: Transform.translate(
                  offset: Offset(
                    _lightSweepAnimation!.value *
                        MediaQuery.of(context).size.width,
                    0,
                  ),
                  child: Container(
                    width: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.3),
                          Colors.white.withValues(alpha: 0.6),
                          Colors.white.withValues(alpha: 0.3),
                          Colors.white.withValues(alpha: 0.0),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.2, 0.4, 0.5, 0.6, 0.8, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
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

  // Método para construir la imagen del sobre
  Widget _buildPackImage(String imageUrl) {
    final imageBytes = _getImageBytes(imageUrl);

    if (imageBytes != null) {
      return Image.memory(
        imageBytes,
        width: 60,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 60,
            height: 80,
            color: Colors.grey[300],
            child: const Icon(Icons.card_giftcard, color: Colors.grey),
          );
        },
      );
    } else {
      return Image.network(
        imageUrl,
        width: 60,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 60,
            height: 80,
            color: Colors.grey[300],
            child: const Icon(Icons.card_giftcard, color: Colors.grey),
          );
        },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(currentCard.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.cards.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
          // Recargar sobres para la nueva carta
          _loadAvailablePacks();
        },
        itemBuilder: (context, index) {
          final card = widget.cards[index];
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen de la carta en grande
                Container(
                  height: MediaQuery.of(context).size.height * 0.65,
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 2.5 / 3.5, // Proporción típica de cartas
                      child: Hero(
                        tag: 'catalog_card_${card.id}',
                        child: _buildCardImage(card.imageUrl),
                      ),
                    ),
                  ),
                ),

                // Información de la carta
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nombre y rareza
                        Row(
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
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getRarityColor(card.rarity),
                                borderRadius: BorderRadius.circular(20),
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

                        // Tipo y Serie
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoCard(
                                'Tipo',
                                _getTypeText(card.type),
                                Icons.category,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInfoCard(
                                'Serie',
                                card.series,
                                Icons.movie,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Estadísticas de combate (si es personaje)
                        if (card.type == model.CardType.character) ...[
                          const Text(
                            'Estadísticas de Combate',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Vida',
                                  card.maxHealth.toString(),
                                  Icons.favorite,
                                  Colors.red,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildStatCard(
                                  'Ataque',
                                  card.attack.toString(),
                                  Icons.flash_on,
                                  Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildStatCard(
                                  'Defensa',
                                  card.defense.toString(),
                                  Icons.shield,
                                  Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildStatCard(
                                  'Poder',
                                  card.power.toString(),
                                  Icons.star,
                                  Colors.purple,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Habilidades
                        if (card.abilities.isNotEmpty) ...[
                          const Text(
                            'Habilidades',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...card.abilities.map((ability) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('• ',
                                        style: TextStyle(fontSize: 16)),
                                    Expanded(
                                      child: Text(
                                        ability,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                          const SizedBox(height: 16),
                        ],

                        // Tags
                        if (card.tags.isNotEmpty) ...[
                          const Text(
                            'Etiquetas',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: card.tags
                                .map((tag) => Chip(
                                      label: Text(tag),
                                      backgroundColor: Colors.grey[200],
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Estado de posesión
                        Consumer<CollectionProvider>(
                          builder: (context, collectionProvider, child) {
                            final userCollection =
                                collectionProvider.userCollection;
                            final userOwnsCard =
                                userCollection?.cards.containsKey(card.id) ??
                                    false;
                            final quantity = userOwnsCard
                                ? userCollection!.cards[card.id]!.quantity
                                : 0;

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: userOwnsCard
                                    ? Colors.green[50]
                                    : Colors.red[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      userOwnsCard ? Colors.green : Colors.red,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    userOwnsCard
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: userOwnsCard
                                        ? Colors.green
                                        : Colors.red,
                                    size: 32,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          userOwnsCard
                                              ? 'Tienes esta carta'
                                              : 'No tienes esta carta',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: userOwnsCard
                                                ? Colors.green[800]
                                                : Colors.red[800],
                                          ),
                                        ),
                                        if (userOwnsCard)
                                          Text(
                                            'Cantidad: $quantity',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.green[600],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        // Sobres disponibles
                        const Text(
                          'Disponible en estos sobres',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        if (_isLoadingPacks)
                          const Center(child: CircularProgressIndicator())
                        else if (_availablePacks.isEmpty)
                          const Text(
                            'Esta carta no está disponible en ningún sobre actualmente',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          )
                        else
                          SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _availablePacks.length,
                              itemBuilder: (context, index) {
                                final pack = _availablePacks[index];
                                return Container(
                                  width: 100,
                                  margin: const EdgeInsets.only(right: 12),
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: _buildPackImage(pack.imageUrl),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        pack.name,
                                        style: const TextStyle(fontSize: 12),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: pack.currency ==
                                                  CardPackCurrency.coins
                                              ? Colors.amber[100]
                                              : Colors.purple[100],
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '${pack.price} ${pack.currency == CardPackCurrency.coins ? '🪙' : '💎'}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: pack.currency ==
                                                    CardPackCurrency.coins
                                                ? Colors.amber[800]
                                                : Colors.purple[800],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.grey[600]),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
