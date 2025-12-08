import 'package:dio/dio.dart';
import '/data/models/character_response_model.dart';

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