import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/data/models/character_model.dart';
import '/data/services/image_cache_service.dart';

class CacheService {
  static const String _charactersCacheKey = 'characters_cache_';
  static const String _characterDetailsCacheKey = 'character_details_cache_';
  static const String _allCharactersKey = 'all_characters_cache';
  static const String _maxPageKey = 'max_cached_page';
  static const Duration _cacheDuration = Duration(hours: 24);
  
  final ImageCacheService _imageCacheService = ImageCacheService();

  // Кэширование списка персонажей для конкретной страницы
  Future<void> cacheCharacters(List<CharacterModel> characters, {int page = 1}) async {
    final prefs = await SharedPreferences.getInstance();
    
    final pageKey = '$_charactersCacheKey$page';
    final pageCacheData = {
      'timestamp': DateTime.now().toIso8601String(),
      'page': page,
      'characters': characters.map((c) => c.toJson()).toList(),
    };
    await prefs.setString(pageKey, jsonEncode(pageCacheData));
    
    final currentMaxPage = prefs.getInt(_maxPageKey) ?? 0;
    if (page > currentMaxPage) {
      await prefs.setInt(_maxPageKey, page);
    }
    
    await _addToGlobalCache(characters);
    
    await _cacheImages(characters);
  }

  // Добавление персонажей в общий кэш
  Future<void> _addToGlobalCache(List<CharacterModel> characters) async {
    final prefs = await SharedPreferences.getInstance();
    
    final allCharactersCache = await _getAllCachedCharacters();
    final allCharactersMap = {for (var char in allCharactersCache) char.id: char};
    
    for (final character in characters) {
      allCharactersMap[character.id] = character;
    }
    
    final allCharactersList = allCharactersMap.values.toList();
    final allCacheData = {
      'timestamp': DateTime.now().toIso8601String(),
      'characters': allCharactersList.map((c) => c.toJson()).toList(),
    };
    await prefs.setString(_allCharactersKey, jsonEncode(allCacheData));
  }

  // Получение всех закэшированных персонажей
  Future<List<CharacterModel>> _getAllCachedCharacters() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheString = prefs.getString(_allCharactersKey);
    
    if (cacheString == null) return [];
    
    try {
      final cacheData = jsonDecode(cacheString) as Map<String, dynamic>;
      final timestamp = DateTime.parse(cacheData['timestamp'] as String);
      
      if (DateTime.now().difference(timestamp) > _cacheDuration) {
        await prefs.remove(_allCharactersKey);
        await prefs.remove(_maxPageKey);
        await _clearAllPages();
        return [];
      }
      
      final charactersJson = cacheData['characters'] as List<dynamic>;
      final characters = charactersJson
          .map((json) => CharacterModel.fromJson(json as Map<String, dynamic>))
          .toList();
      
      return characters;
    } catch (e) {
      debugPrint('Ошибка при чтении общего кэша: $e');
      await prefs.remove(_allCharactersKey);
      await prefs.remove(_maxPageKey);
      return [];
    }
  }

  // Получение кэшированных персонажей для конкретной страницы
  Future<List<CharacterModel>?> getCachedCharacters({int page = 1}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_charactersCacheKey$page';
    final cacheString = prefs.getString(key);
    
    if (cacheString == null) return null;
    
    try {
      final cacheData = jsonDecode(cacheString) as Map<String, dynamic>;
      final timestamp = DateTime.parse(cacheData['timestamp'] as String);
      
      // Проверка актуальности кэша
      if (DateTime.now().difference(timestamp) > _cacheDuration) {
        await prefs.remove(key);
        return null;
      }
      
      final charactersJson = cacheData['characters'] as List<dynamic>;
      final characters = charactersJson
          .map((json) => CharacterModel.fromJson(json as Map<String, dynamic>))
          .toList();
      
      return characters;
    } catch (e) {
      debugPrint('Ошибка при чтении кэша страницы $page: $e');
      await prefs.remove(key);
      return null;
    }
  }

  // Получение ВСЕХ закэшированных персонажей (для офлайн режима)
  Future<List<CharacterModel>> getAllCachedCharacters() async {
    return await _getAllCachedCharacters();
  }

  // Получение максимальной закэшированной страницы
  Future<int> getMaxCachedPage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_maxPageKey) ?? 0;
  }

  // Получение персонажей для офлайн режима (все, что есть)
  Future<List<CharacterModel>> getCharactersForOffline({int limit = 20}) async {
    final allCharacters = await _getAllCachedCharacters();
    
    allCharacters.sort((a, b) => a.id.compareTo(b.id));
    
    return allCharacters.length > limit 
        ? allCharacters.sublist(0, limit)
        : allCharacters;
  }

  // Кэширование изображений персонажей
  Future<void> _cacheImages(List<CharacterModel> characters) async {
    for (final character in characters) {
      try {
        await _imageCacheService.cacheImage(character.image);
      } catch (e) {
        debugPrint('Error caching image for ${character.name}: $e');
      }
    }
  }

  // Кэширование деталей персонажа
  Future<void> cacheCharacterDetail(CharacterModel character) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_characterDetailsCacheKey${character.id}';
    final cacheData = {
      'timestamp': DateTime.now().toIso8601String(),
      'character': character.toJson(),
    };
    await prefs.setString(key, jsonEncode(cacheData));
    
    try {
      await _imageCacheService.cacheImage(character.image);
    } catch (e) {
      debugPrint('Error caching image for ${character.name}: $e');
    }
  }

  // Получение кэшированных деталей персонажа
  Future<CharacterModel?> getCachedCharacterDetail(int characterId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_characterDetailsCacheKey$characterId';
    final cacheString = prefs.getString(key);
    
    if (cacheString == null) return null;
    
    try {
      final cacheData = jsonDecode(cacheString) as Map<String, dynamic>;
      final timestamp = DateTime.parse(cacheData['timestamp'] as String);
      
      if (DateTime.now().difference(timestamp) > _cacheDuration) {
        await prefs.remove(key);
        return null;
      }
      
      final characterJson = cacheData['character'] as Map<String, dynamic>;
      return CharacterModel.fromJson(characterJson);
    } catch (e) {
      debugPrint('Ошибка при чтении кэша персонажа: $e');
      await prefs.remove(key);
      return null;
    }
  }

  // Получение кэшированных фаворитов (персонажей)
  Future<List<CharacterModel>> getCachedFavorites(List<int> favoriteIds) async {
    final List<CharacterModel> favorites = [];
    
    for (final id in favoriteIds) {
      final cached = await getCachedCharacterDetail(id);
      if (cached != null) {
        favorites.add(cached);
      }
    }
    
    return favorites;
  }

  // Очистка кэша
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    // Удаляем все ключи кэша
    for (final key in keys) {
      if (key.startsWith(_charactersCacheKey) || 
          key.startsWith(_characterDetailsCacheKey) ||
          key == _allCharactersKey ||
          key == _maxPageKey) {
        await prefs.remove(key);
      }
    }
    
    // Очищаем кэш изображений
    await _imageCacheService.clearImageCache();
  }

  // Очистка всех страниц
  Future<void> _clearAllPages() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    for (final key in keys) {
      if (key.startsWith(_charactersCacheKey)) {
        await prefs.remove(key);
      }
    }
  }

  // Получение информации о размере кэша
  Future<int> getCacheSize() async {
    final prefs = await SharedPreferences.getInstance();
    int totalSize = 0;
    
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_charactersCacheKey) || 
          key.startsWith(_characterDetailsCacheKey) ||
          key == _allCharactersKey) {
        final value = prefs.getString(key);
        if (value != null) {
          totalSize += utf8.encode(value).length;
        }
      }
    }
    
    // Добавляем размер кэша изображений
    final imageCacheSize = await _imageCacheService.getImageCacheSize();
    totalSize += imageCacheSize;
    
    return totalSize;
  }

  // Проверка, есть ли кэшированные данные
  Future<bool> hasCachedData() async {
    final allCharacters = await _getAllCachedCharacters();
    return allCharacters.isNotEmpty;
  }

  // Получение количества закэшированных персонажей
  Future<int> getCachedCharactersCount() async {
    final allCharacters = await _getAllCachedCharacters();
    return allCharacters.length;
  }
}