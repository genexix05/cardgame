import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/card.dart' as card_model; // Importar modelo Card con alias
import '../utils/audio_service.dart'; // Importar nuestro servicio de audio

class PackOpeningScreen extends StatefulWidget {
  final List<card_model.Card> cards; // Usar el modelo Card con alias
  final String packImageUrl; // URL de la imagen del sobre seleccionado

  const PackOpeningScreen({
    super.key,
    required this.cards,
    required this.packImageUrl,
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
    try {
      _audioService.toggleAudio(); // Cambiamos enableAudio por toggleAudio
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
      backgroundColor: Colors.black,
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
    // Usar la animación para controlar la rotación de las dos mitades del sobre
    final Animation<double> rotationAnimation = Tween<double>(
      begin: 0.0,
      end: -90.0, // Rotación para la mitad superior
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    final Animation<double> rotationAnimation2 = Tween<double>(
      begin: 0.0,
      end: 90.0, // Rotación para la mitad inferior
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    // Animación para el brillo/destello cuando se abre el sobre
    final Animation<double> glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 0.8, curve: Curves.easeOut),
      ),
    );

    // Animación para la escala durante la apertura
    final Animation<double> scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1, // Ligero efecto de escala
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 0.6, curve: Curves.easeInOut),
      ),
    );

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Efecto de brillo/destello
            Container(
              height: 300,
              width: 220,
              decoration: BoxDecoration(
                boxShadow: glowAnimation.value > 0.5
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFF5722).withOpacity(glowAnimation.value * 0.3),
                          blurRadius: 30.0 * glowAnimation.value,
                          spreadRadius: 10.0 * glowAnimation.value,
                        )
                      ]
                    : [],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Efecto de escala durante la apertura
                  Transform.scale(
                    scale: scaleAnimation.value,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Fondo del sobre (visible cuando se abre)
                        Container(
                          height: 260,
                          width: 200,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF1A1A2E),
                                const Color(0xFF16213E),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(color: const Color(0xFFFF5722), width: 2),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.auto_awesome,
                              color: Color.lerp(
                                Colors.transparent, 
                                const Color(0xFFFF5722), 
                                glowAnimation.value,
                              ),
                              size: 80 * glowAnimation.value,
                            ),
                          ),
                        ),
                        
                        // Mitad superior del sobre (se abre hacia arriba)
                        Positioned(
                          top: 0,
                          child: Transform(
                            alignment: Alignment.bottomCenter,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001) // Añade perspectiva
                              ..rotateX(rotationAnimation.value * 0.0174533), // Convertir grados a radianes
                            child: ClipRRect(
                              // Corta la imagen por la mitad (parte superior)
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12.0),
                                topRight: Radius.circular(12.0),
                              ),
                              child: SizedBox(
                                height: 130, // Mitad de la altura del sobre
                                width: 200,
                                child: _buildPackHalfImage(
                                  widget.packImageUrl, 
                                  true, // Parte superior
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        // Mitad inferior del sobre (se abre hacia abajo)
                        Positioned(
                          bottom: 0,
                          child: Transform(
                            alignment: Alignment.topCenter,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001) // Añade perspectiva
                              ..rotateX(rotationAnimation2.value * 0.0174533), // Convertir grados a radianes
                            child: ClipRRect(
                              // Corta la imagen por la mitad (parte inferior)
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(12.0),
                                bottomRight: Radius.circular(12.0),
                              ),
                              child: SizedBox(
                                height: 130, // Mitad de la altura del sobre
                                width: 200,
                                child: _buildPackHalfImage(
                                  widget.packImageUrl, 
                                  false, // Parte inferior
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Abriendo sobre...',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(
                  _animationController.value < 0.3 ? 1.0 : 1.0 - ((_animationController.value - 0.3) / 0.7),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  // Nuevo método para construir la mitad de la imagen del sobre
  Widget _buildPackHalfImage(String imageUrl, bool isTopHalf) {
    // Verificar si la imagen está en formato base64
    final imageBytes = _getImageBytes(imageUrl);
    
    Widget imageWidget;
    if (imageBytes != null) {
      // Si es base64, mostrar usando Image.memory
      imageWidget = Image.memory(
        imageBytes,
        fit: BoxFit.cover,
        height: 260, // Altura total del sobre antes de partirlo
        width: 200,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorImage();
        },
      );
    } else {
      // Si es URL, mostrar usando Image.network
      imageWidget = Image.network(
        imageUrl,
        fit: BoxFit.cover,
        height: 260, // Altura total del sobre antes de partirlo
        width: 200,
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
          return _buildErrorImage();
        },
      );
    }
    
    // Posicionamos la imagen para mostrar solo la parte superior o inferior
    return ClipRect(
      child: Align(
        alignment: isTopHalf ? Alignment.topCenter : Alignment.bottomCenter,
        heightFactor: 0.5, // Solo mostrar la mitad de la imagen
        child: imageWidget,
      ),
    );
  }

  Widget _buildCardReveal() {
    final card = widget.cards[_currentCardIndex];
    return Stack(
      children: [
        // Fondo de batalla
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/battle_background.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        
        // Contenido principal
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculamos el espacio disponible y ajustamos proporciones
                final double availableHeight = constraints.maxHeight;
                final double cardHeight = availableHeight * 0.6; // 60% del espacio para la carta
                final double cardWidth = cardHeight / 1.4; // Mantener proporción
                
                return Column(
                  key: ValueKey(_currentCardIndex),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Navegación de cartas (índice)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _currentCardIndex > 0 ? _previousCard : null,
                            icon: Icon(
                              Icons.arrow_back_ios_rounded,
                              color: _currentCardIndex > 0 ? Colors.white : Colors.white.withOpacity(0.3),
                              size: 28,
                            ),
                          ),
                          Text(
                            '${_currentCardIndex + 1}/${widget.cards.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              shadows: [
                                Shadow(offset: Offset(1, 1), blurRadius: 3, color: Colors.black)
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _currentCardIndex < widget.cards.length - 1 ? _nextCard : null,
                            icon: Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: _currentCardIndex < widget.cards.length - 1 ? Colors.white : Colors.white.withOpacity(0.3),
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Nombre de la carta
                    Container(
                      margin: const EdgeInsets.fromLTRB(30, 5, 30, 5),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getRarityColor(card.rarity).withOpacity(0.7),
                            _getRarityColor(card.rarity).withOpacity(0.5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Text(
                        card.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(offset: Offset(1, 1), blurRadius: 2, color: Colors.black)
                          ],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    // Imagen de la carta en grande (centro)
                    Expanded(
                      child: Center(
                        child: Container(
                          width: cardWidth,
                          height: cardHeight,
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: _getRarityColor(card.rarity).withOpacity(0.7),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                              const BoxShadow(
                                color: Colors.black54,
                                blurRadius: 15,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: _buildCardImage(card.imageUrl),
                          ),
                        ),
                      ),
                    ),
                    
                    // Atributos de la carta (pie)
                    Container(
                      margin: const EdgeInsets.fromLTRB(20, 5, 20, 10),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: _getRarityColor(card.rarity), width: 2),
                      ),
                      child:
                        card.type == card_model.CardType.character ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Vida
                           _buildStatItem(
                             Icons.favorite, 
                             'HP', 
                             // Mostrar siempre el valor directamente
                             card.maxHealth.toString(),
                             Colors.red.shade300
                           ),
                           // Ataque
                           _buildStatItem(
                             Icons.flash_on, 
                             'ATK', 
                             // Mostrar siempre el valor directamente
                             card.attack.toString(),
                             Colors.amber
                           ),
                           // Defensa
                           _buildStatItem(
                             Icons.shield, 
                             'DEF', 
                             // Mostrar siempre el valor directamente
                             card.defense.toString(),
                             Colors.blue.shade300
                           ),
                        ],
                      ) : Row(
                        // Para cartas que no son de personaje, mostrar poder y tipo
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem(
                            Icons.style, 
                            'Tipo', 
                            _getCardTypeText(card.type),
                            Colors.purple.shade300
                          ),
                          _buildStatItem(
                            Icons.flash_on, 
                            'Poder', 
                            // Mostrar '?' en lugar de 0 para el poder
                            card.power > 0 ? card.power.toString() : 'N/A',
                            const Color(0xFFFF5722)
                          ),
                          _buildStatItem(
                            Icons.auto_awesome, 
                            'Rareza', 
                            _getRarityText(card.rarity),
                            _getRarityColor(card.rarity)
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
  
  // Widget para mostrar un atributo de la carta
  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color,
          size: 22,
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(offset: Offset(1, 1), blurRadius: 2, color: Colors.black)
            ],
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }
  
  // Método para obtener el texto del tipo de carta
  String _getCardTypeText(card_model.CardType type) {
    return switch (type) {
      card_model.CardType.character => 'Personaje',
      card_model.CardType.support => 'Soporte',
      card_model.CardType.event => 'Evento',
      card_model.CardType.equipment => 'Equipo',
    };
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
          return null;
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

  Color _getRarityColor(card_model.CardRarity rarity) {
    return switch (rarity) {
      card_model.CardRarity.common => const Color(0xFF78909C), // Gris azulado
      card_model.CardRarity.uncommon => const Color(0xFF4CAF50), // Verde
      card_model.CardRarity.rare => const Color(0xFF2196F3), // Azul
      card_model.CardRarity.superRare => const Color(0xFF9C27B0), // Morado
      card_model.CardRarity.ultraRare => const Color(0xFFFF9800), // Naranja
      card_model.CardRarity.legendary => const Color(0xFFFFD700), // Dorado
    };
  }

  String _getRarityText(card_model.CardRarity rarity) {
    return switch (rarity) {
      card_model.CardRarity.common => 'Común',
      card_model.CardRarity.uncommon => 'Poco Común',
      card_model.CardRarity.rare => 'Raro',
      card_model.CardRarity.superRare => 'Super Raro',
      card_model.CardRarity.ultraRare => 'Ultra Raro',
      card_model.CardRarity.legendary => 'Legendaria',
    };
  }
}
