import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pack_provider.dart';
import '../../providers/collection_provider.dart';
import '../../models/card_pack.dart';
import '../pack_opening_screen.dart';
import 'dart:convert';
import 'dart:typed_data';

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

  @override
  void initState() {
    super.initState();

    // Utilizar addPostFrameCallback para cargar los paquetes después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPacks();
    });
  }

  Future<void> _loadPacks() async {
    final packProvider = Provider.of<PackProvider>(context, listen: false);
    await packProvider.loadAvailablePacks();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final packProvider = Provider.of<PackProvider>(context);
    final collectionProvider = Provider.of<CollectionProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sobres de Cartas'),
      ),
      body: packProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPacks,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información del usuario
                    _buildUserInfo(collectionProvider),

                    // Sobres limitados
                    if (packProvider.limitedPacks.isNotEmpty) ...[
                      _buildSectionHeader('Sobres Especiales Limitados'),
                      _buildPackList(
                        packProvider.limitedPacks,
                        packProvider,
                        authProvider,
                      ),
                    ],

                    // Sobres estándar
                    _buildSectionHeader('Sobres Estándar'),
                    packProvider.availablePacks.isEmpty
                        ? _buildEmptyState()
                        : _buildPackList(
                            packProvider.availablePacks
                                .where((pack) => !pack.isLimited)
                                .toList(),
                            packProvider,
                            authProvider,
                          ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildUserInfo(CollectionProvider collectionProvider) {
    return Card(
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
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(
          left: 16.0, right: 16.0, top: 24.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
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

  Widget _buildPackList(
    List<CardPack> packs,
    PackProvider packProvider,
    AuthProvider authProvider,
  ) {
    // Función para obtener los bytes de la imagen a partir de una Data URI.
    Uint8List? getImageBytes(String url) {
      if (url.startsWith('data:')) {
        final parts = url.split(',');
        if (parts.length > 1) {
          return base64Decode(parts[1]);
        }
      }
      return null;
    }

    // Función para construir el widget de la imagen.
    Widget buildPackImage(String imageUrl) {
      final imageBytes = getImageBytes(imageUrl);
      if (imageBytes != null) {
        return Image.memory(
          imageBytes,
          height: 150,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      } else {
        return Image.network(
          imageUrl,
          height: 150,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 150,
              color: Colors.grey.shade300,
              child: const Center(
                child: Icon(
                  Icons.card_giftcard,
                  size: 50,
                  color: Colors.grey,
                ),
              ),
            );
          },
        );
      }
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: packs.length,
      itemBuilder: (context, index) {
        final pack = packs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen del sobre
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: buildPackImage(pack.imageUrl),
              ),
              // Información del sobre
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
                            pack.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (pack.isLimited)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 4.0,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
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
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      pack.description,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text(
                          'Cartas por sobre: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('${pack.cardsPerPack}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          'Precio: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${pack.price} ${pack.currency == CardPackCurrency.coins ? 'monedas' : 'gemas'}',
                          style: TextStyle(
                            color: pack.currency == CardPackCurrency.coins
                                ? const Color(0xFFFFD700)
                                : const Color(0xFF1E88E5),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: packProvider.isOpeningPack
                            ? null
                            : () => _openPack(pack, packProvider, authProvider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5722),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          packProvider.isOpeningPack
                              ? 'Abriendo...'
                              : 'Abrir Sobre',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
          MaterialPageRoute(
            builder: (_) => PackOpeningScreen(
              cards: packProvider.lastOpenedCards,
            ),
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
}
