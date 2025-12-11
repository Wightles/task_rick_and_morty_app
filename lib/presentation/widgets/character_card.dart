import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import '/data/models/character_model.dart';
import 'package:cupertino_icons/cupertino_icons.dart';
import '/data/services/image_cache_service.dart';

class CharacterCard extends StatefulWidget {
  final CharacterModel character;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback? onTap;

  const CharacterCard({
    super.key,
    required this.character,
    required this.isFavorite,
    required this.onFavoriteToggle,
    this.onTap,
  });

  @override
  State<CharacterCard> createState() => _CharacterCardState();
}

class _CharacterCardState extends State<CharacterCard> {
  final ImageCacheService _imageCacheService = ImageCacheService();
  late Future<FileImage?> _cachedImage;

  @override
  void initState() {
    super.initState();
    _cachedImage = _loadCachedImage();
  }

  Future<FileImage?> _loadCachedImage() async {
    try {
      final imageFile = await _imageCacheService.getCachedImage(widget.character.image);
      if (imageFile != null && await imageFile.exists()) {
        return FileImage(imageFile);
      }
      return null;
    } catch (e) {
      debugPrint('Error loading cached image: $e');
      return null;
    }
  }

  Future<void> _handleTap() async {
    if (await Vibration.hasVibrator() ?? false) {
      await Vibration.vibrate(duration: 10);
    }
    
    if (widget.onTap != null) {
      widget.onTap!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: _handleTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCharacterInfo(),
              ),
              _buildFavoriteButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return FutureBuilder<FileImage?>(
      future: _cachedImage,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingAvatar();
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          return _buildCachedAvatar(snapshot.data!);
        }
        
        return _buildNetworkAvatar();
      },
    );
  }

  Widget _buildLoadingAvatar() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[300],
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildCachedAvatar(FileImage image) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image(
        image: image,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildNetworkAvatar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        widget.character.image,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingAvatar();
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[300],
            ),
            child: const Icon(
              Icons.person_off,
              size: 40,
              color: Colors.grey,
            ),
          );
        },
      ),
    );
  }

  Widget _buildCharacterInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.character.name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        _buildStatusRow(),
        const SizedBox(height: 4),
        Text(
          '${widget.character.species}${widget.character.type.isNotEmpty ? ' - ${widget.character.type}' : ''}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Последнее известное местоположение:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
            Text(
              widget.character.location.name,
              style: const TextStyle(
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusRow() {
    Color statusColor;
    switch (widget.character.status.toLowerCase()) {
      case 'alive':
        statusColor = Colors.green;
        break;
      case 'dead':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: statusColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${widget.character.status} - ${widget.character.gender}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildFavoriteButton() {
    return IconButton(
      onPressed: widget.onFavoriteToggle,
      icon: Icon(
        widget.isFavorite ? CupertinoIcons.star_fill : CupertinoIcons.star_fill,
        color: widget.isFavorite ? const Color.fromARGB(255, 218, 139, 11) : Colors.grey,
        size: 28,
      ),
    );
  }
}