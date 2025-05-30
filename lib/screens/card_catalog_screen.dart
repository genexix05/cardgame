import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../models/card.dart' as model;
import '../services/firestore_service.dart';
import '../providers/collection_provider.dart';
import '../providers/auth_provider.dart';
import 'card_detail_screen.dart';
// import '../widgets/card_widget.dart'; // Eliminado ya que no se usa por ahora

class CardCatalogScreen extends StatefulWidget {
  const CardCatalogScreen({super.key});

  @override
  State<CardCatalogScreen> createState() => _CardCatalogScreenState();
}

class _CardCatalogScreenState extends State<CardCatalogScreen> {
  late Future<List<model.Card>> _allCardsFuture;

  @override
  void initState() {
    super.initState();
    // Obtener la instancia de FirestoreService vía Provider
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    _allCardsFuture = firestoreService.getAllCards();

    // Cargar la colección del usuario si está autenticado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserCollection();
    });
  }

  void _loadUserCollection() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final collectionProvider =
        Provider.of<CollectionProvider>(context, listen: false);

    if (authProvider.user != null) {
      collectionProvider.loadUserCollection(authProvider.user!.uid);
    }
  }

  // Método para construir la imagen de la carta (maneja URL y base64)
  Widget _buildCardImage(String imageUrl, bool userOwnsCard) {
    // Verificar si la imagen está en formato base64
    final imageBytes = _getImageBytes(imageUrl);

    Widget imageWidget;

    if (imageBytes != null) {
      // Si es base64, mostrar usando Image.memory
      imageWidget = Image.memory(
        imageBytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Icon(
              Icons.image_not_supported,
              color: Colors.grey,
              size: 50,
            ),
          );
        },
      );
    } else {
      // Si es URL, mostrar usando Image.network
      imageWidget = Image.network(
        imageUrl,
        fit: BoxFit.cover,
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
              size: 50,
            ),
          );
        },
      );
    }

    // Aplicar filtro en blanco y negro si el usuario no posee la carta
    return ColorFiltered(
      colorFilter: userOwnsCard
          ? const ColorFilter.mode(
              Colors.transparent,
              BlendMode.multiply,
            )
          : const ColorFilter.matrix(<double>[
              0.2126, 0.7152, 0.0722, 0, 0, // Red channel
              0.2126, 0.7152, 0.0722, 0, 0, // Green channel
              0.2126, 0.7152, 0.0722, 0, 0, // Blue channel
              0, 0, 0, 1, 0, // Alpha channel
            ]),
      child: imageWidget,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Catálogo de Cartas',
          style: TextStyle(
            fontFamily: 'CCSoothsayer',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/home_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Consumer<CollectionProvider>(
          builder: (context, collectionProvider, child) {
            return FutureBuilder<List<model.Card>>(
              future: _allCardsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  print(
                      'Error en FutureBuilder CardCatalogScreen: ${snapshot.error}');
                  return Center(
                    child: Text(
                      'Error al cargar el catálogo de cartas. Inténtalo de nuevo más tarde.\nDetalle: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text('No hay cartas disponibles en el catálogo.'));
                }

                final cards = snapshot.data!;

                // Opcional: Ordenar las cartas por algún criterio, ej. nombre, rareza, serie
                // cards.sort((a, b) => a.name.compareTo(b.name));

                return GridView.builder(
                  padding: const EdgeInsets.all(10.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // Número de columnas
                    childAspectRatio:
                        0.7, // Relación de aspecto de cada celda (ancho / alto)
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: cards.length,
                  itemBuilder: (context, index) {
                    final card = cards[index];

                    // Verificar si el usuario posee esta carta
                    final userCollection = collectionProvider.userCollection;
                    final bool userOwnsCard =
                        userCollection?.cards.containsKey(card.id) ?? false;

                    return InkWell(
                      onTap: () {
                        // Navegar a la pantalla de detalle de la carta
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => CardDetailScreen(
                              cards: cards,
                              initialIndex: index,
                            ),
                          ),
                        );
                      },
                      child: GridTile(
                        footer: userOwnsCard
                            ? Container(
                                padding: const EdgeInsets.all(4.0),
                                color: Colors.black54,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'x${userCollection!.cards[card.id]!.quantity}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                            : null,
                        child: Hero(
                          tag: 'catalog_card_${card.id}',
                          child: _buildCardImage(card.imageUrl, userOwnsCard),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
