import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/card.dart' as model;
import '../models/user_collection.dart';
import 'dart:convert';
import 'dart:typed_data';

class CardGrid extends StatelessWidget {
  final List<Map<String, dynamic>> cards;
  final Function(Map<String, dynamic>) onCardTap;

  const CardGrid({
    super.key,
    required this.cards,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final cardMap = cards[index];
        final card = cardMap['cardDetail'] as model.Card;
        final userCard = cardMap['userCard'] as UserCard;

        return GestureDetector(
          onTap: () => onCardTap(cardMap),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _buildCardImage(card.imageUrl),
          ),
        );
      },
    );
  }

  // Método para construir la imagen de la carta (maneja URL y base64)
  Widget _buildCardImage(String imageUrl) {
    // Verificar si la imagen está en formato base64
    final imageBytes = _getImageBytes(imageUrl);

    if (imageBytes != null) {
      // Si es base64, mostrar usando Image.memory
      return Image.memory(
        imageBytes,
        fit: BoxFit.cover,
        width: double.infinity,
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
      // Si es URL, mostrar usando CachedNetworkImage
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder: (context, url) => Container(
          color: Colors.grey.shade300,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorWidget: (context, url, error) {
          return Container(
            color: Colors.grey.shade300,
            child: const Icon(
              Icons.broken_image,
              color: Colors.red,
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
