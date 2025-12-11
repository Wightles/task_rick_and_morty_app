import '/data/repositories/character_repository.dart';

class OfflineDataLoader {
  final CharacterRepository _repository = CharacterRepository();

  // Загрузка и кэширование множества страниц для офлайн работы
  Future<void> loadMultiplePagesForOffline({
    int startPage = 1,
    int numberOfPages = 10,
    Function(int page, int loadedCharacters)? onProgress,
  }) async {
    int totalLoaded = 0;
    
    for (int page = startPage; page < startPage + numberOfPages; page++) {
      try {
        final response = await _repository.getCharacters(
          page: page,
          forceRefresh: true, 
        );
        
        totalLoaded += response.results.length;
        
        onProgress?.call(page, totalLoaded);
        
        print('Загружена страница $page с ${response.results.length} персонажами');
        
        await Future.delayed(const Duration(milliseconds: 500));
        
      } catch (e) {
        print('Ошибка при загрузке страницы $page: $e');
        break;
      }
    }
    
    print('Всего загружено $totalLoaded персонажей для офлайн работы');
  }

  // Проверка, сколько страниц уже закэшировано
  Future<int> getCachedPagesCount() async {
    return await _repository.getMaxCachedPage();
  }

  // Получение статистики по кэшу
  Future<Map<String, dynamic>> getCacheStats() async {
    final cachedCount = await _repository.getCachedCharactersCount();
    final cachedPages = await _repository.getMaxCachedPage();
    final cacheSize = await _repository.getCacheSize();
    
    return {
      'cachedCharacters': cachedCount,
      'cachedPages': cachedPages,
      'cacheSizeBytes': cacheSize,
      'cacheSizeMB': (cacheSize / (1024 * 1024)).toStringAsFixed(2),
    };
  }
}