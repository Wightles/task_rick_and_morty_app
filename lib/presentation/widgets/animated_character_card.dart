import 'package:flutter/material.dart';
import '/presentation/widgets/character_card.dart';
import '/data/models/character_model.dart';

class AnimatedCharacterCard extends StatefulWidget {
  final CharacterModel character;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback? onTap;

  const AnimatedCharacterCard({
    super.key,
    required this.character,
    required this.isFavorite,
    required this.onFavoriteToggle,
    this.onTap,
  });

  @override
  State<AnimatedCharacterCard> createState() => _AnimatedCharacterCardState();
}

class _AnimatedCharacterCardState extends State<AnimatedCharacterCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onFavoritePressed() {
    if (!widget.isFavorite) {
      _controller.forward().then((_) {
        _controller.reverse();
      });
    }
    widget.onFavoriteToggle();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: CharacterCard(
        character: widget.character,
        isFavorite: widget.isFavorite,
        onFavoriteToggle: _onFavoritePressed,
        onTap: widget.onTap,
      ),
    );
  }
}