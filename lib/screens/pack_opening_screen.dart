import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/card.dart' as card_model; // Importar modelo Card con alias
import '../models/card.dart'
    show CardRarity; // Importar CardRarity directamente
import '../utils/audio_service.dart'; // Importar nuestro servicio de audio

class PackOpeningScreen extends StatefulWidget {
  final List<card_model.Card> cards; // Usar el alias para el modelo Card

  const PackOpeningScreen({
    super.key,
    required this.cards,
  });

  @override
  State<PackOpeningScreen> createState() => _PackOpeningScreenState();
}

class _PackOpeningScreenState extends State<PackOpeningScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _showCards = false;
  int _currentCardIndex = 0;
  final AudioService _audioService =
      AudioService(); // Instancia del servicio de audio

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Evitar interacciones innecesarias con AudioManager
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    // Intentar reactivar el audio para esta pantalla
    _reactivateAudio();

    // Inicializar audio de forma asíncrona y sin bloquear
    _initAudio();

    // Empezar la animación
    _animationController.forward();

    // Mostrar las cartas después de la animación
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _showCards = true;
          // Reproducir sonido solo si el audio está habilitado
          if (_audioService.isAudioEnabled && widget.cards.isNotEmpty) {
            _audioService.playCardRevealSound();
          }
        });
      }
    });
  }

  // Método para inicializar el audio
  Future<void> _initAudio() async {
    try {
      await _audioService.initialize();

      // Solo reproducir sonido si el audio está habilitado y la pantalla está montada
      if (_audioService.isAudioEnabled && mounted) {
        await _audioService.playPackOpenSound();
      }
    } catch (e) {
      // Error silencioso
    }
  }

  // Método para reactivar el audio
  void _reactivateAudio() {
    // Esta función es para reactivar el audio si está desactivado por completo
    try {
      AudioService.enableAudio(); // Nuevo método que añadiremos al AudioService
    } catch (e) {
      print('Error al reactivar audio: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Método para navegar a la siguiente carta con efecto de sonido
  void _nextCard() {
    if (_currentCardIndex < widget.cards.length - 1) {
      setState(() {
        _currentCardIndex++;
        // Reproducir sonido solo si el audio está habilitado
        if (_audioService.isAudioEnabled) {
          _audioService.playCardRevealSound();
        }
      });
    }
  }

  // Método para navegar a la carta anterior con efecto de sonido
  void _previousCard() {
    if (_currentCardIndex > 0) {
      setState(() {
        _currentCardIndex--;
        // Reproducir sonido solo si el audio está habilitado
        if (_audioService.isAudioEnabled) {
          _audioService.playCardRevealSound();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        title: const Text('Cartas Obtenidas'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _showCards
                  ? widget.cards.isEmpty
                      ? _buildNoCardsAvailable()
                      : _buildCardReveal()
                  : _buildOpeningAnimation(),
            ),
          ),
          // Indicador de progreso y botones de navegación
          if (_showCards && widget.cards.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Indicador de progreso
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${_currentCardIndex + 1}/${widget.cards.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Botones de navegación
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(
                        onPressed: _currentCardIndex > 0 ? _previousCard : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5722),
                          foregroundColor: Colors.white,
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.arrow_back),
                            SizedBox(width: 8),
                            Text('Anterior'),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _currentCardIndex < widget.cards.length - 1
                            ? _nextCard
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5722),
                          foregroundColor: Colors.white,
                        ),
                        child: const Row(
                          children: [
                            Text('Siguiente'),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFFF5722),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Volver a Sobres',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Botón simple para volver si no hay cartas
          if (_showCards && widget.cards.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFFF5722),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Volver a Sobres',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Widget para mostrar cuando no hay cartas disponibles
  Widget _buildNoCardsAvailable() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.sentiment_dissatisfied,
          size: 80,
          color: Colors.white54,
        ),
        const SizedBox(height: 24),
        const Text(
          'No hay cartas disponibles',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Text(
            'Se ha descontado el precio del sobre. Las cartas estarán disponibles próximamente.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOpeningAnimation() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Aquí se debería mostrar una animación de apertura de sobre
        // Usamos un placeholder simple en este ejemplo
        const Icon(
          Icons.card_giftcard,
          size: 120,
          color: Color(0xFFFF5722),
        ),
        const SizedBox(height: 32),
        const Text(
          'Abriendo sobre...',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildCardReveal() {
    final card = widget.cards[_currentCardIndex];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Column(
        key: ValueKey(_currentCardIndex),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Carta actual
          Material(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: _getRarityColor(card.rarity),
                width: 3,
              ),
            ),
            child: SizedBox(
              width: 280,
              height: 400,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Imagen de la carta - Modificada para manejar base64
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(13),
                      ),
                      child: _buildCardImage(card.imageUrl),
                    ),
                  ),

                  // Información de la carta
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(13),
                      ),
                    ),
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
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          card.description,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Serie: ${card.series}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.flash_on,
                                  color: Color(0xFFFF5722),
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Poder: ${card.power}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
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
        ],
      ),
    );
  }

  // Nuevo método para construir la imagen de la carta (similar al que se usa en packs_tab.dart)
  Widget _buildCardImage(String imageUrl) {
    // Verificar si la imagen está en formato base64
    final imageBytes = _getImageBytes(imageUrl);

    if (imageBytes != null) {
      // Si es base64, mostrar usando Image.memory
      return Image.memory(
        imageBytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error al cargar imagen base64: $error');
          return _buildErrorImage();
        },
      );
    } else {
      // Si es URL, mostrar usando Image.network
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('Error al cargar imagen URL: $error');
          return _buildErrorImage();
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

  // Método para construir la imagen de error
  Widget _buildErrorImage() {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(
          Icons.broken_image,
          size: 64,
          color: Colors.grey,
        ),
      ),
    );
  }

  Color _getRarityColor(CardRarity rarity) {
    switch (rarity) {
      case CardRarity.common:
        return Colors.grey;
      case CardRarity.uncommon:
        return Colors.green;
      case CardRarity.rare:
        return Colors.blue;
      case CardRarity.superRare:
        return Colors.purple;
      case CardRarity.ultraRare:
        return Colors.orange;
      case CardRarity.legendary:
        return Colors.red;
      default:
        return Colors.grey; // Valor por defecto para evitar null
    }
  }

  String _getRarityText(CardRarity rarity) {
    switch (rarity) {
      case CardRarity.common:
        return 'Común';
      case CardRarity.uncommon:
        return 'Poco común';
      case CardRarity.rare:
        return 'Rara';
      case CardRarity.superRare:
        return 'Super rara';
      case CardRarity.ultraRare:
        return 'Ultra rara';
      case CardRarity.legendary:
        return 'Legendaria';
      default:
        return 'Desconocida'; // Valor por defecto para evitar null
    }
  }
}
