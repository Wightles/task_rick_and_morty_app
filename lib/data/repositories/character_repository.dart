import '/data/models/character_model.dart';
import '/data/api_client.dart';
import '/data/services/cache_service.dart';
import '/data/models/character_response_model.dart';

class CharacterRepository {
  final ApiClient _apiClient = ApiClient();
  final CacheService _cacheService = CacheService();

  Future<CharacterResponseModel> getCharacters({int page = 1, bool forceRefresh = false}) async {
    // Если не первая страница или принудительное обновление - всегда грузим из сети
    if (page > 1 || forceRefresh) {
      final response = await _apiClient.getCharacters(page: page);
      
      // Кэшируем первую страницу
      if (page == 1) {
        await _cacheService.cacheCharacters(response.results);
      }
      
      return response;
    }
    
    // Пытаемся получить из кэша
    final cachedCharacters = await _cacheService.getCachedCharacters();
    if (cachedCharacters != null) {
      // Возвращаем закешированные данные для первой страницы
      return CharacterResponseModel(
        info: Info(
          count: cachedCharacters.length,
          pages: 1,
          next: 'https://rickandmortyapi.com/api/character?page=2',
          prev: null,
        ),
        results: cachedCharacters,
      );
    }
    
    // Если кэша нет - грузим из сети
    final response = await _apiClient.getCharacters(page: page);
    await _cacheService.cacheCharacters(response.results);
    return response;
  }

  Future<CharacterModel> getCharacter(int id) async {
    return await _apiClient.getCharacter(id);
  }

  Future<List<CharacterModel>> getMultipleCharacters(List<int> ids) async {
    return await _apiClient.getMultipleCharacters(ids);
  }

  Future<CharacterResponseModel> searchCharacters(String query, {int page = 1}) async {
    return await _apiClient.searchCharacters(query, page: page);
  }
}