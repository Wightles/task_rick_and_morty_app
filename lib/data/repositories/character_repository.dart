import '/data/api_client.dart';
import '/data/models/character_response_model.dart';

class CharacterRepository {
  final ApiClient _apiClient = ApiClient();

  Future<CharacterResponseModel> getCharacters({int page = 1}) async {
    return await _apiClient.getCharacters(page: page);
  }

  Future<CharacterResponseModel> searchCharacters(String query, {int page = 1}) async {
    return await _apiClient.searchCharacters(query, page: page);
  }
}