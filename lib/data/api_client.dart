import 'package:dio/dio.dart';
import '/data/models/character_response_model.dart';
import '/data/models/character_model.dart';

class ApiClient {
  final Dio _dio = Dio();
  static const String _baseUrl = 'https://rickandmortyapi.com/api/';

  ApiClient() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  Future<CharacterResponseModel> getCharacters({int page = 1}) async {
    try {
      final response = await _dio.get('character', queryParameters: {'page': page});
      return CharacterResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Server error: ${e.response?.statusCode}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
  }

  // Новый метод: загрузка одного персонажа по ID
  Future<CharacterModel> getCharacter(int id) async {
    try {
      final response = await _dio.get('character/$id');
      return CharacterModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Server error: ${e.response?.statusCode}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
  }

  // В классе ApiClient
Future<List<CharacterModel>> getMultipleCharacters(List<int> ids) async {
  final List<CharacterModel> characters = [];
  
  // Загружаем каждого персонажа отдельно
  for (final id in ids) {
    try {
      final character = await getCharacter(id);
      characters.add(character);
    } on DioException catch (e) {
      // Логируем ошибку, но продолжаем загрузку остальных
      print('Ошибка при загрузке персонажа $id: ${e.message}');
      // Можно также удалить некорректный ID из избранного
      // await _favoritesService.removeFromFavorites(id);
    } catch (e) {
      print('Неизвестная ошибка при загрузке персонажа $id: $e');
    }
  }
  
  return characters;
}

  Future<CharacterResponseModel> searchCharacters(String query, {int page = 1}) async {
    try {
      final response = await _dio.get(
        'character',
        queryParameters: {'name': query, 'page': page},
      );
      return CharacterResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return CharacterResponseModel(
          info: Info(count: 0, pages: 0, next: null, prev: null),
          results: [],
        );
      }
      rethrow;
    }
  }
}