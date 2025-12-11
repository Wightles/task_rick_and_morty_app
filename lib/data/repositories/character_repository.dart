import 'dart:io';
import 'package:flutter/material.dart';

import '/data/api_client.dart';
import '/data/services/cache_service.dart';
import '/data/models/character_response_model.dart';
import '../models/character_model.dart';

class CharacterRepository {
  final ApiClient _apiClient = ApiClient();
  final CacheService _cacheService = CacheService();

  Future<CharacterResponseModel> getCharacters({
    int page = 1,
    bool forceRefresh = false,
    bool allowCache = true,
    bool autoLoadMore = false, 
  }) async {
    try {
      if (!allowCache || forceRefresh) {
        final response = await _apiClient.getCharacters(page: page);
        
        if (allowCache) {
          await _cacheService.cacheCharacters(response.results, page: page);
        }
        
        if (autoLoadMore && response.info.next != null) {
          _preloadNextPage(page + 1);
        }
        
        return response;
      }
      
      // Пытаемся получить из кэша
      final cachedCharacters = await _cacheService.getCachedCharacters(page: page);
      if (cachedCharacters != null) {
        return CharacterResponseModel(
          info: Info(
            count: await _cacheService.getCachedCharactersCount(),
            pages: await _cacheService.getMaxCachedPage(),
            next: page < await _cacheService.getMaxCachedPage() 
                ? 'https://rickandmortyapi.com/api/character?page=${page + 1}' 
                : 'https://rickandmortyapi.com/api/character?page=${page + 1}',
            prev: page > 1 ? 'https://rickandmortyapi.com/api/character?page=${page - 1}' : null,
          ),
          results: cachedCharacters,
        );
      }
      
      final response = await _apiClient.getCharacters(page: page);
      await _cacheService.cacheCharacters(response.results, page: page);
      
      if (autoLoadMore && response.info.next != null) {
        _preloadNextPage(page + 1);
      }
      
      return response;
      
    } on SocketException catch (_) {
      debugPrint('Офлайн режим: загружаем из кэша страницу $page');
      
      // Пробуем получить конкретную страницу из кэша
      final cachedCharacters = await _cacheService.getCachedCharacters(page: page);
      if (cachedCharacters != null && cachedCharacters.isNotEmpty) {
        return CharacterResponseModel(
          info: Info(
            count: await _cacheService.getCachedCharactersCount(),
            pages: await _cacheService.getMaxCachedPage(),
            next: page < await _cacheService.getMaxCachedPage() 
                ? 'https://rickandmortyapi.com/api/character?page=${page + 1}' 
                : null,
            prev: page > 1 ? 'https://rickandmortyapi.com/api/character?page=${page - 1}' : null,
          ),
          results: cachedCharacters,
        );
      }
      
      // Если конкретной страницы нет, пробуем получить всех персонажей и сэмулировать пагинацию
      final allCachedCharacters = await _cacheService.getAllCachedCharacters();
      if (allCachedCharacters.isNotEmpty) {
        allCachedCharacters.sort((a, b) => a.id.compareTo(b.id));
        
        const charactersPerPage = 20;
        final startIndex = (page - 1) * charactersPerPage;
        final endIndex = startIndex + charactersPerPage;
        
        if (startIndex < allCachedCharacters.length) {
          final paginatedCharacters = allCachedCharacters.sublist(
            startIndex,
            endIndex < allCachedCharacters.length ? endIndex : allCachedCharacters.length,
          );
          
          final totalPages = (allCachedCharacters.length / charactersPerPage).ceil();
          
          return CharacterResponseModel(
            info: Info(
              count: allCachedCharacters.length,
              pages: totalPages,
              next: page < totalPages 
                  ? 'https://rickandmortyapi.com/api/character?page=${page + 1}' 
                  : null,
              prev: page > 1 ? 'https://rickandmortyapi.com/api/character?page=${page - 1}' : null,
            ),
            results: paginatedCharacters,
          );
        }
      }
      
      // Если вообще нет данных
      throw Exception('Нет подключения к интернету и данных в кэше.');
    } catch (e) {
      rethrow;
    }
  }

  // Асинхронная предзагрузка следующей страницы (не блокирует UI)
  Future<void> _preloadNextPage(int nextPage) async {
    try {
      debugPrint('Автопредзагрузка страницы $nextPage...');
      final response = await _apiClient.getCharacters(page: nextPage);
      await _cacheService.cacheCharacters(response.results, page: nextPage);
      debugPrint('Страница $nextPage автозагружена в кэш');
    } catch (e) {
      debugPrint('Ошибка при автопредзагрузке страницы $nextPage: $e');
    }
  }

  Future<CharacterModel> getCharacter(int id, {bool allowCache = true}) async {
    try {
      if (allowCache) {
        final cachedCharacter = await _cacheService.getCachedCharacterDetail(id);
        if (cachedCharacter != null) {
          return cachedCharacter;
        }
      }
      
      // Если нет в кэше или не используем кэш - грузим из сети
      final character = await _apiClient.getCharacter(id);
      
      // Кэшируем
      if (allowCache) {
        await _cacheService.cacheCharacterDetail(character);
      }
      
      return character;
      
    } on SocketException catch (_) {
      // Офлайн режим
      final cachedCharacter = await _cacheService.getCachedCharacterDetail(id);
      if (cachedCharacter != null) {
        return cachedCharacter;
      }
      
      // Пробуем найти в общем кэше
      final allCharacters = await _cacheService.getAllCachedCharacters();
      final character = allCharacters.firstWhere(
        (char) => char.id == id,
        orElse: () => throw Exception('Персонаж не найден в кэше'),
      );
      
      return character;
    }
  }

  Future<List<CharacterModel>> getMultipleCharacters(List<int> ids, {bool allowCache = true}) async {
    final List<CharacterModel> characters = [];
    
    if (allowCache) {
      for (final id in ids) {
        try {
          final cached = await _cacheService.getCachedCharacterDetail(id);
          if (cached != null) {
            characters.add(cached);
            continue;
          }
        } catch (e) {
        }
      }
      
      if (characters.length == ids.length) {
        return characters;
      }
    }
    
    // Загружаем недостающих из сети
    try {
      final networkCharacters = await _apiClient.getMultipleCharacters(
        ids.where((id) => !characters.any((c) => c.id == id)).toList(),
      );
      
      characters.addAll(networkCharacters);
      
      // Кэшируем новых персонажей
      if (allowCache) {
        for (final character in networkCharacters) {
          await _cacheService.cacheCharacterDetail(character);
        }
      }
    } on SocketException catch (_) {
      if (characters.isEmpty) {
        throw Exception('Нет подключения к интернету и персонажи не найдены в кэше');
      }
    }
    
    return characters;
  }

  Future<CharacterResponseModel> searchCharacters(String query, {int page = 1}) async {
    try {
      return await _apiClient.searchCharacters(query, page: page);
    } on SocketException catch (_) {
      final allCharacters = await _cacheService.getAllCachedCharacters();
      final filteredCharacters = allCharacters
          .where((character) => character.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
      
      const charactersPerPage = 20;
      final startIndex = (page - 1) * charactersPerPage;
      final endIndex = startIndex + charactersPerPage;
      
      final paginatedCharacters = filteredCharacters.length > endIndex
          ? filteredCharacters.sublist(startIndex, endIndex)
          : filteredCharacters.sublist(startIndex);
      
      final totalPages = (filteredCharacters.length / charactersPerPage).ceil();
      
      return CharacterResponseModel(
        info: Info(
          count: filteredCharacters.length,
          pages: totalPages,
          next: page < totalPages ? 'search?query=$query&page=${page + 1}' : null,
          prev: page > 1 ? 'search?query=$query&page=${page - 1}' : null,
        ),
        results: paginatedCharacters,
      );
    }
  }

  // Получение данных о кэше
  Future<int> getCacheSize() async {
    return await _cacheService.getCacheSize();
  }

  // Очистка кэша
  Future<void> clearCache() async {
    await _cacheService.clearCache();
  }

  // Проверка наличия кэшированных данных
  Future<bool> hasCachedData() async {
    return await _cacheService.hasCachedData();
  }

  // Получение количества закэшированных страниц
  Future<int> getMaxCachedPage() async {
    return await _cacheService.getMaxCachedPage();
  }

  // Получение количества закэшированных персонажей
  Future<int> getCachedCharactersCount() async {
    return await _cacheService.getCachedCharactersCount();
  }

  // Автоматическая предзагрузка нескольких страниц
  Future<void> autoPreloadPages(int currentPage, {int pagesAhead = 2}) async {
    for (int page = currentPage + 1; page <= currentPage + pagesAhead; page++) {
      try {
        final response = await _apiClient.getCharacters(page: page);
        await _cacheService.cacheCharacters(response.results, page: page);
        debugPrint('Автопредзагрузка: страница $page закэширована');
      } catch (e) {
        debugPrint('Ошибка при автопредзагрузке страницы $page: $e');
        break;
      }
    }
  }
}