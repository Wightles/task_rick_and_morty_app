import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '/data/models/character_model.dart';
import '/data/services/cache_service.dart';

class FavoritesService {
  static const String _favoritesKey = 'favorites';
  static const String _favoritesDataKey = 'favorites_data';
  static const Duration _favoritesSyncInterval = Duration(minutes: 30);

  final CacheService _cacheService = CacheService();

  // Получение ID фаворитов
  Future<List<int>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesString = prefs.getString(_favoritesKey);
    
    if (favoritesString == null || favoritesString.isEmpty) {
      return [];
    }
    
    try {
      return favoritesString.split(',').map(int.parse).toList();
    } catch (e) {
      print('Ошибка при чтении фаворитов: $e');
      return [];
    }
  }

  // Получение полных данных фаворитов
  Future<List<CharacterModel>> getFavoritesWithData() async {
    final favoriteIds = await getFavorites();
    
    if (favoriteIds.isEmpty) {
      return [];
    }

    final cachedFavorites = await _cacheService.getCachedFavorites(favoriteIds);
    
    if (cachedFavorites.length == favoriteIds.length) {
      return cachedFavorites;
    }

    final prefs = await SharedPreferences.getInstance();
    final favoritesDataString = prefs.getString(_favoritesDataKey);
    
    if (favoritesDataString != null) {
      try {
        final data = jsonDecode(favoritesDataString) as Map<String, dynamic>;
        final timestamp = DateTime.parse(data['timestamp'] as String);
        
        if (DateTime.now().difference(timestamp) < _favoritesSyncInterval) {
          final favoritesJson = data['characters'] as List<dynamic>;
          final favorites = favoritesJson
              .map((json) => CharacterModel.fromJson(json as Map<String, dynamic>))
              .toList();
          
          for (final favorite in favorites) {
            await _cacheService.cacheCharacterDetail(favorite);
          }
          
          return favorites;
        }
      } catch (e) {
        print('Ошибка при чтении данных фаворитов: $e');
      }
    }
    
    return cachedFavorites;
  }

  // Добавление в фавориты
  Future<void> addToFavorites(int characterId, [CharacterModel? character]) async {
    final favorites = await getFavorites();
    
    if (!favorites.contains(characterId)) {
      favorites.add(characterId);
      await _saveFavorites(favorites);
      
      if (character != null) {
        await _cacheService.cacheCharacterDetail(character);
        await _updateFavoritesData();
      }
    }
  }

  // Удаление из фаворитов
  Future<void> removeFromFavorites(int characterId) async {
    final favorites = await getFavorites();
    favorites.remove(characterId);
    await _saveFavorites(favorites);
    await _updateFavoritesData();
  }

  // Проверка, является ли фаворитом
  Future<bool> isFavorite(int characterId) async {
    final favorites = await getFavorites();
    return favorites.contains(characterId);
  }

  // Сохранение ID фаворитов
  Future<void> _saveFavorites(List<int> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesString = favorites.join(',');
    await prefs.setString(_favoritesKey, favoritesString);
  }

  // Обновление данных фаворитов
  Future<void> _updateFavoritesData() async {
    final favorites = await getFavoritesWithData();
    final prefs = await SharedPreferences.getInstance();
    
    final data = {
      'timestamp': DateTime.now().toIso8601String(),
      'characters': favorites.map((c) => c.toJson()).toList(),
    };
    
    await prefs.setString(_favoritesDataKey, jsonEncode(data));
  }

  // Очистка фаворитов
  Future<void> clearFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_favoritesKey);
    await prefs.remove(_favoritesDataKey);
  }

  // Получение количества фаворитов
  Future<int> getFavoritesCount() async {
    final favorites = await getFavorites();
    return favorites.length;
  }
}