import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/card.dart' as model;
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import 'dart:convert';
import 'dart:typed_data';

class UserSalesScreen extends StatefulWidget {
  static const routeName = '/user-sales';

  const UserSalesScreen({Key? key}) : super(key: key);

  @override
  _UserSalesScreenState createState() => _UserSalesScreenState();
}

class _UserSalesScreenState extends State<UserSalesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _userSales = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserSales();
  }

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
          print('Error al cargar imagen base64: $error');
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
          print('Error al cargar imagen URL: $error');
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
          print('Error al decodificar imagen base64: $e');
        }
      }
    }
    return null;
  }

  Future<void> _loadUserSales() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId == null) {
      setState(() {
        _errorMessage = "No has iniciado sesión";
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Obtenemos todas las cartas en venta
      final cardsForSale = await _firestoreService.getCardsForSale();

      // Filtramos para obtener solo las del usuario actual
      final userSales =
          cardsForSale.where((item) => item['sellerId'] == userId).toList();

      setState(() {
        _userSales = userSales;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Error al cargar tus ventas: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelSale(Map<String, dynamic> saleItem) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success =
          await _firestoreService.cancelCardSale(userId, saleItem['cardId']);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Venta cancelada correctamente')));
        await _loadUserSales();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No se pudo cancelar la venta'),
          backgroundColor: Colors.red,
        ));
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: ${e.toString()}'),
        backgroundColor: Colors.red,
      ));
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Ventas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserSales,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _userSales.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.sell,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No tienes cartas a la venta',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('Ir al mercado'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _userSales.length,
                      itemBuilder: (context, index) {
                        final saleItem = _userSales[index];
                        final card = model.Card.fromMap(saleItem['card']);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16.0),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color:
                                  _getRarityColor(card.rarity).withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Imagen de la carta
                                  ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      bottomLeft: Radius.circular(12),
                                    ),
                                    child: _buildCardImage(card.imageUrl),
                                  ),

                                  // Información de la carta
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  card.name,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: _getRarityColor(
                                                      card.rarity),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  _getRarityText(card.rarity),
                                                  style: const TextStyle(
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
                                            'Serie: ${card.series}',
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.flash_on,
                                                color: Color(0xFFFF5722),
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Poder: ${card.power}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFFD700)
                                                      .withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.monetization_on,
                                                      color: Color(0xFFFFD700),
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${saleItem['price']}',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Text(
                                                'Publicada: ${_formatDate(saleItem['listedDate'])}',
                                                style: const TextStyle(
                                                  fontStyle: FontStyle.italic,
                                                  fontSize: 12,
                                                  color: Colors.grey,
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

                              // Botón para cancelar la venta
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12.0),
                                child: OutlinedButton(
                                  onPressed: () => _cancelSale(saleItem),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                  ),
                                  child: const Text('Cancelar venta'),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Desconocido';

    final DateTime date = timestamp.toDate();
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(date);

    if (difference.inDays > 0) {
      return 'Hace ${difference.inDays} días';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours} horas';
    } else if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes} minutos';
    } else {
      return 'Hace un momento';
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
}
