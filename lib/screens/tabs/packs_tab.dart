import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pack_provider.dart';
import '../../providers/collection_provider.dart';
import '../../models/card_pack.dart';
import '../../models/card.dart' as card_model;
import '../../services/firestore_service.dart';
import '../pack_opening_screen.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../../utils/transitions.dart';

class PacksTab extends StatefulWidget {
  const PacksTab({super.key});

  @override
  State<PacksTab> createState() => _PacksTabState();
}

Uint8List? _getImageBytes(String url) {
  if (url.startsWith('data:')) {
    final parts = url.split(',');
    if (parts.length > 1) {
      return base64Decode(parts[1]);
    }
  }
  return null;
}

class _PacksTabState extends State<PacksTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  int _currentPackIndex = 0;
  PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPackIndex);

    // Utilizar addPostFrameCallback para cargar los paquetes después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPacks();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadPacks() async {
    final packProvider = Provider.of<PackProvider>(context, listen: false);
    await packProvider.loadAvailablePacks();
  }

  List<CardPack> _getAllPacks(PackProvider packProvider) {
    List<CardPack> allPacks = [];
    allPacks.addAll(packProvider.limitedPacks);
    allPacks
        .addAll(packProvider.availablePacks.where((pack) => !pack.isLimited));
    return allPacks;
  }

  void _previousPack() {
    if (_currentPackIndex > 0) {
      setState(() {
        _currentPackIndex--;
      });
      _pageController.animateToPage(
        _currentPackIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextPack(int totalPacks) {
    if (_currentPackIndex < totalPacks - 1) {
      setState(() {
        _currentPackIndex++;
      });
      _pageController.animateToPage(
        _currentPackIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showPackInfo(CardPack pack) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
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
                // Header con imagen del sobre
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
                      // Imagen de fondo del sobre
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20)),
                          child: Opacity(
                            opacity: 0.3,
                            child: _buildPackImage(pack.imageUrl),
                          ),
                        ),
                      ),
                      // Contenido del header
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          children: [
                            // Imagen pequeña del sobre
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _buildPackImage(pack.imageUrl),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Información básica
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    pack.name,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontFamily: 'PrimalScream',
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Información del precio y cartas - usando Wrap para evitar overflow
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 4,
                                    children: [
                                      // Precio
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            pack.currency ==
                                                    CardPackCurrency.coins
                                                ? Icons.monetization_on
                                                : Icons.diamond,
                                            color: pack.currency ==
                                                    CardPackCurrency.coins
                                                ? const Color(0xFFFFD700)
                                                : const Color(0xFF1E88E5),
                                            size: 18,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${pack.price}',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: pack.currency ==
                                                      CardPackCurrency.coins
                                                  ? const Color(0xFFFFD700)
                                                  : const Color(0xFF1E88E5),
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Cartas por sobre
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.style,
                                            color: Colors.white70,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${pack.cardsPerPack} cartas',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.white70,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (pack.isLimited) ...[
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'LIMITADO',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
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
                          onPressed: () => Navigator.of(context).pop(),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Información del sobre
                        _buildInfoSection(
                          'Información del Sobre',
                          [
                            _buildInfoRow(Icons.style, 'Cartas por sobre',
                                '${pack.cardsPerPack}'),
                            _buildInfoRow(
                              pack.currency == CardPackCurrency.coins
                                  ? Icons.monetization_on
                                  : Icons.diamond,
                              'Precio',
                              '${pack.price} ${pack.currency == CardPackCurrency.coins ? 'monedas' : 'gemas'}',
                            ),
                            _buildInfoRow(Icons.category, 'Tipo de sobre',
                                _getPackTypeName(pack.type)),
                            if (pack.seriesFilter != null &&
                                pack.seriesFilter!.isNotEmpty)
                              _buildInfoRow(
                                  Icons.collections,
                                  'Series incluidas',
                                  pack.seriesFilter!.join(', ')),
                            if (pack.isLimited)
                              _buildInfoRow(Icons.access_time, 'Disponibilidad',
                                  'Edición limitada'),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Probabilidades de rareza
                        _buildRaritySection(pack),

                        const SizedBox(height: 24),

                        // Cartas que contiene el sobre
                        _buildPackCardsSection(pack),
                      ],
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

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'PrimalScream',
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFFFF5722),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRaritySection(CardPack pack) {
    // Usar las probabilidades reales del sobre si están disponibles
    Map<String, double> rarityOdds = {};

    if (pack.rarityDistribution != null) {
      rarityOdds = {
        'Común': pack.rarityDistribution!.common * 100,
        'Poco común': pack.rarityDistribution!.uncommon * 100,
        'Raro': pack.rarityDistribution!.rare * 100,
        'Super raro': pack.rarityDistribution!.superRare * 100,
        'Ultra raro': pack.rarityDistribution!.ultraRare * 100,
        'Legendario': pack.rarityDistribution!.legendary * 100,
      };
    } else {
      // Probabilidades por defecto basadas en el tipo de sobre
      switch (pack.type) {
        case CardPackType.basic:
          rarityOdds = {
            'Común': 60.0,
            'Poco común': 25.0,
            'Raro': 12.0,
            'Super raro': 2.5,
            'Ultra raro': 0.4,
            'Legendario': 0.1,
          };
          break;
        case CardPackType.premium:
          rarityOdds = {
            'Común': 45.0,
            'Poco común': 30.0,
            'Raro': 18.0,
            'Super raro': 5.0,
            'Ultra raro': 1.5,
            'Legendario': 0.5,
          };
          break;
        case CardPackType.ultra:
          rarityOdds = {
            'Común': 30.0,
            'Poco común': 35.0,
            'Raro': 25.0,
            'Super raro': 7.0,
            'Ultra raro': 2.5,
            'Legendario': 0.5,
          };
          break;
        case CardPackType.ultimate:
          rarityOdds = {
            'Común': 20.0,
            'Poco común': 30.0,
            'Raro': 30.0,
            'Super raro': 15.0,
            'Ultra raro': 4.0,
            'Legendario': 1.0,
          };
          break;
        case CardPackType.legendary:
          rarityOdds = {
            'Común': 10.0,
            'Poco común': 20.0,
            'Raro': 35.0,
            'Super raro': 25.0,
            'Ultra raro': 8.0,
            'Legendario': 2.0,
          };
          break;
        default:
          rarityOdds = {
            'Común': 50.0,
            'Poco común': 30.0,
            'Raro': 15.0,
            'Super raro': 4.0,
            'Ultra raro': 0.9,
            'Legendario': 0.1,
          };
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Probabilidades de Rareza',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'PrimalScream',
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: rarityOdds.entries
                .where((entry) => entry.value > 0)
                .map((entry) {
              return _buildRarityRow(entry.key, entry.value);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRarityRow(String rarity, double percentage) {
    Color rarityColor = _getRarityColor(rarity);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: rarityColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: rarityColor.withOpacity(0.5),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              rarity,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: rarityColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: rarityColor.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                color: rarityColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'común':
        return Colors.grey;
      case 'poco común':
        return Colors.green;
      case 'raro':
        return Colors.blue;
      case 'super raro':
        return Colors.purple;
      case 'ultra raro':
        return Colors.orange;
      case 'legendario':
        return Colors.amber;
      default:
        return Colors.white;
    }
  }

  String _getPackTypeName(CardPackType type) {
    switch (type) {
      case CardPackType.basic:
        return 'Básico';
      case CardPackType.premium:
        return 'Premium';
      case CardPackType.ultra:
        return 'Ultra';
      case CardPackType.ultimate:
        return 'Ultimate';
      case CardPackType.legendary:
        return 'Legendario';
      case CardPackType.special:
        return 'Especial';
      default:
        return 'Desconocido';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final packProvider = Provider.of<PackProvider>(context);
    final collectionProvider = Provider.of<CollectionProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    final allPacks = _getAllPacks(packProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sobres de Cartas',
          style: TextStyle(
            fontFamily: 'CCSoothsayer',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/home_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: packProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadPacks,
                child: allPacks.isEmpty
                    ? _buildEmptyState()
                    : Column(
                        children: [
                          // Indicador de página
                          _buildPageIndicator(allPacks.length),

                          // Sobre principal
                          Expanded(
                            child: _buildPackCarousel(
                                allPacks, packProvider, authProvider),
                          ),
                        ],
                      ),
              ),
      ),
    );
  }

  Widget _buildPageIndicator(int totalPacks) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          totalPacks,
          (index) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            width: 8.0,
            height: 8.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index == _currentPackIndex
                  ? const Color(0xFFFF5722)
                  : Colors.grey.shade400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPackCarousel(
    List<CardPack> packs,
    PackProvider packProvider,
    AuthProvider authProvider,
  ) {
    return Stack(
      children: [
        // PageView para los sobres
        PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentPackIndex = index;
            });
          },
          itemCount: packs.length,
          itemBuilder: (context, index) {
            final pack = packs[index];
            return _buildPackCard(pack, packProvider, authProvider);
          },
        ),

        // Flecha izquierda
        if (_currentPackIndex > 0)
          Positioned(
            left: 16,
            top: 0,
            bottom: 100,
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: _previousPack,
                ),
              ),
            ),
          ),

        // Flecha derecha
        if (_currentPackIndex < packs.length - 1)
          Positioned(
            right: 16,
            top: 0,
            bottom: 100,
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: () => _nextPack(packs.length),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPackCard(
    CardPack pack,
    PackProvider packProvider,
    AuthProvider authProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20.0),
      child: Column(
        children: [
          // Contenedor del sobre con botón de información
          Expanded(
            flex: 8, // Sobre más pequeño
            child: Stack(
              children: [
                // Imagen del sobre
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: _buildPackImage(pack.imageUrl),
                  ),
                ),

                // Botón de información (esquina superior izquierda)
                Positioned(
                  top: 2,
                  left: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color.fromARGB(228, 255, 86, 34),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.info,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () => _showPackInfo(pack),
                    ),
                  ),
                ),

                // Badge de limitado (si aplica)
                if (pack.isLimited)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 6.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Limitado',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Botón de abrir sobre
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              height: 90,
              child: ElevatedButton(
                onPressed: packProvider.isOpeningPack
                    ? null
                    : () => _openPack(pack, packProvider, authProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5722),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 6,
                ),
                child: packProvider.isOpeningPack
                    ? const Text(
                        'Abriendo...',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'PrimalScream',
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Abrir ',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'PrimalScream',
                            ),
                          ),
                          Text(
                            '${pack.price}',
                            style: const TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'PrimalScream',
                            ),
                          ),
                          Icon(
                            pack.currency == CardPackCurrency.coins
                                ? Icons.monetization_on
                                : Icons.diamond,
                            color: pack.currency == CardPackCurrency.coins
                                ? const Color(0xFFFFD700)
                                : const Color(0xFF1E88E5),
                            size: 32,
                          ),
                        ],
                      ),
              ),
            ),
          ),

          // Espacio inferior
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildPackImage(String imageUrl) {
    final imageBytes = _getImageBytes(imageUrl);
    if (imageBytes != null) {
      return Image.memory(
        imageBytes,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain,
      );
    } else {
      return Image.network(
        imageUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade300,
            child: const Center(
              child: Icon(
                Icons.card_giftcard,
                size: 100,
                color: Colors.grey,
              ),
            ),
          );
        },
      );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.card_giftcard,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No hay sobres disponibles',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vuelve más tarde para ver nuevos sobres',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPack(
    CardPack pack,
    PackProvider packProvider,
    AuthProvider authProvider,
  ) async {
    if (authProvider.user == null) return;

    // Primero seleccionamos el sobre antes de intentar abrirlo
    packProvider.selectPack(pack);

    final success = await packProvider.openPack(authProvider.user!.uid);

    if (success == true && mounted == true) {
      // Actualizar colección después de abrir el sobre
      final collectionProvider =
          Provider.of<CollectionProvider>(context, listen: false);
      await collectionProvider.loadUserCollection(authProvider.user!.uid);

      // Navegar a la pantalla de apertura de sobres
      if (mounted) {
        Navigator.of(context).push(
          CustomPageRoute(
            child: PackOpeningScreen(
              cards: packProvider.lastOpenedCards.take(5).toList(), // Limitado a 5 cartas
              packImageUrl: pack.imageUrl, // Pasar la URL de la imagen del sobre
            ),
            settings: const RouteSettings(name: '/pack-opening'),
          ),
        );
      }
    } else if (!success) {
      // Mostrar mensaje de error al usuario
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(packProvider.error ?? 'Error al abrir el sobre'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildPackCardsSection(CardPack pack) {
    return FutureBuilder<List<card_model.Card>>(
      future: _getPackSpecificCards(pack.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFF5722),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.red.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Text(
              'Error al cargar las cartas del sobre',
              style: TextStyle(
                color: Colors.red,
                fontSize: 14,
              ),
            ),
          );
        }

        final cards = snapshot.data ?? [];

        if (cards.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Text(
              'Este sobre contiene cartas aleatorias basadas en las probabilidades de rareza',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cartas que Contiene',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'PrimalScream',
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // Encabezado
                  Row(
                    children: [
                      const Icon(
                        Icons.style,
                        color: Color(0xFFFF5722),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${cards.length} cartas específicas',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Lista de cartas
                  ...cards.map((card) => _buildCardListItem(card)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCardListItem(card_model.Card card) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Imagen pequeña de la carta
          Container(
            width: 40,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: _getCardRarityColor(card.rarity).withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: _buildCardImage(card.imageUrl),
            ),
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
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color:
                            _getCardRarityColor(card.rarity).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color:
                              _getCardRarityColor(card.rarity).withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _getCardRarityText(card.rarity),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getCardRarityColor(card.rarity),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getCardTypeText(card.type),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
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
  }

  Future<List<card_model.Card>> _getPackSpecificCards(String packId) async {
    try {
      final firestoreService =
          Provider.of<FirestoreService>(context, listen: false);

      // Obtener los IDs de las cartas específicas del sobre
      final cardIds = await firestoreService.getPackCards(packId);

      if (cardIds.isEmpty) {
        return [];
      }

      // Obtener todas las cartas disponibles
      final allCards = await firestoreService.getAllCards();

      // Filtrar solo las cartas que están en este sobre
      final packCards =
          allCards.where((card) => cardIds.contains(card.id)).toList();

      // Ordenar las cartas por rareza (de más rara a más común)
      packCards.sort((a, b) {
        final rarityOrder = {
          card_model.CardRarity.legendary: 0,
          card_model.CardRarity.ultraRare: 1,
          card_model.CardRarity.superRare: 2,
          card_model.CardRarity.rare: 3,
          card_model.CardRarity.uncommon: 4,
          card_model.CardRarity.common: 5,
        };

        final aOrder = rarityOrder[a.rarity] ?? 6;
        final bOrder = rarityOrder[b.rarity] ?? 6;

        // Si tienen la misma rareza, ordenar alfabéticamente por nombre
        if (aOrder == bOrder) {
          return a.name.compareTo(b.name);
        }

        return aOrder.compareTo(bOrder);
      });

      return packCards;
    } catch (e) {
      print('Error al obtener cartas específicas del sobre: $e');
      return [];
    }
  }

  Color _getCardRarityColor(card_model.CardRarity rarity) {
    switch (rarity) {
      case card_model.CardRarity.common:
        return Colors.grey;
      case card_model.CardRarity.uncommon:
        return Colors.green;
      case card_model.CardRarity.rare:
        return Colors.blue;
      case card_model.CardRarity.superRare:
        return Colors.purple;
      case card_model.CardRarity.ultraRare:
        return Colors.orange;
      case card_model.CardRarity.legendary:
        return Colors.amber;
    }
  }

  String _getCardRarityText(card_model.CardRarity rarity) {
    switch (rarity) {
      case card_model.CardRarity.common:
        return 'Común';
      case card_model.CardRarity.uncommon:
        return 'Poco común';
      case card_model.CardRarity.rare:
        return 'Raro';
      case card_model.CardRarity.superRare:
        return 'Super raro';
      case card_model.CardRarity.ultraRare:
        return 'Ultra raro';
      case card_model.CardRarity.legendary:
        return 'Legendario';
    }
  }

  String _getCardTypeText(card_model.CardType type) {
    switch (type) {
      case card_model.CardType.character:
        return 'Personaje';
      case card_model.CardType.support:
        return 'Soporte';
      case card_model.CardType.event:
        return 'Evento';
      case card_model.CardType.equipment:
        return 'Equipamiento';
    }
  }

  Widget _buildCardImage(String imageUrl) {
    final imageBytes = _getImageBytes(imageUrl);
    if (imageBytes != null) {
      return Image.memory(
        imageBytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade300,
            child: const Icon(
              Icons.image_not_supported,
              color: Colors.grey,
              size: 20,
            ),
          );
        },
      );
    } else {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade300,
            child: const Icon(
              Icons.image_not_supported,
              color: Colors.grey,
              size: 20,
            ),
          );
        },
      );
    }
  }
}
