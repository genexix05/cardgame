import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/card.dart' as model;
import '../services/firestore_service.dart';
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
    // Asegúrate de que FirestoreService esté disponible en el árbol de widgets
    // Esto usualmente se hace en main.dart o en un widget ancestro.
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    _allCardsFuture = firestoreService.getAllCards();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // El AppBar ya está siendo manejado por TeamTabsScreen, así que no es necesario aquí
      // si esta pantalla siempre se muestra dentro de TeamTabsScreen.
      // Si se puede navegar a ella directamente, considera añadir un AppBar:
      // appBar: AppBar(title: const Text('Catálogo de Cartas')),
      body: FutureBuilder<List<model.Card>>(
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
              // Aquí usamos un CardWidget genérico. Necesitarás crear o adaptar uno.
              // Si no tienes CardWidget, puedes reemplazarlo con un diseño simple:
              return InkWell(
                onTap: () {
                  // Acción al pulsar una carta (ej. mostrar detalles)
                  // Navigator.of(context).push(MaterialPageRoute(builder: (_) => CardDetailScreen(card: card)));
                  print('Carta pulsada: ${card.name}');
                },
                child: GridTile(
                  footer: Container(
                    padding: const EdgeInsets.all(4.0),
                    color: Colors.black54,
                    child: Text(
                      card.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  child: Hero(
                    tag:
                        'catalog_card_${card.id}', // Tag único para la animación Hero
                    child: FadeInImage.assetNetwork(
                      placeholder:
                          'assets/images/card_placeholder.png', // Imagen placeholder local
                      image: card.imageUrl,
                      fit: BoxFit.cover,
                      imageErrorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/images/card_placeholder_error.png', // Placeholder si la imagen de red falla
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// NOTA: Para que este widget funcione correctamente:
// 1. Asegúrate de que FirestoreService esté proveído en un ancestro.
//    Ejemplo en main.dart:
//    Provider<FirestoreService>(create: (_) => FirestoreService()),
//
// 2. Necesitarás imágenes placeholder en tu carpeta assets/images/:
//    - card_placeholder.png
//    - card_placeholder_error.png
//    Si no las tienes, puedes usar Iconos o contenedores de color como placeholder.
//
// 3. El CardWidget es un widget que tendrías que haber creado o que necesitarás crear
//    para mostrar una carta de forma más elaborada. El código actual usa un diseño simple
//    con GridTile y FadeInImage.assetNetwork.
