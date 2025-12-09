import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '/data/models/character_model.dart';

class CacheService {
  static const String _charactersCacheKey = 'characters_cache';
  static const Duration _cacheDuration = Duration(hours: 24); // Кэш на 24 часа

  // Сохранить персонажей в кэш
  Future<void> cacheCharacters(List<CharacterModel> characters) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheData = {
      'timestamp': DateTime.now().toIso8601String(),
      'characters': characters.map((c) => c.toJson()).toList(),
    };
    await prefs.setString(_charactersCacheKey, jsonEncode(cacheData));
  }

  // Получить персонажей из кэша
  Future<List<CharacterModel>?> getCachedCharacters() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheString = prefs.getString(_charactersCacheKey);
    
    if (cacheString == null) return null;
    
    try {
      final cacheData = jsonDecode(cacheString) as Map<String, dynamic>;
      final timestamp = DateTime.parse(cacheData['timestamp'] as String);
      
      // Проверяем, не устарел ли кэш
      if (DateTime.now().difference(timestamp) > _cacheDuration) {
        await prefs.remove(_charactersCacheKey); // Удаляем устаревший кэш
        return null;
      }
      
      // Преобразуем JSON обратно в модели
      final charactersJson = cacheData['characters'] as List<dynamic>;
      final characters = charactersJson
          .map((json) => CharacterModel.fromJson(json as Map<String, dynamic>))
          .toList();
      
      return characters;
    } catch (e) {
      print('Ошибка при чтении кэша: $e');
      await prefs.remove(_charactersCacheKey); // Удаляем поврежденный кэш
      return null;
    }
  }

  // Очистить кэш
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_charactersCacheKey);
  }
}