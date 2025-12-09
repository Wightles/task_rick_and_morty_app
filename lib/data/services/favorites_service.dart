import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const String _favoritesKey = 'favorites';

  Future<List<int>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesString = prefs.getString(_favoritesKey);
    
    if (favoritesString == null || favoritesString.isEmpty) {
      return [];
    }
    return favoritesString.split(',').map(int.parse).toList();
  }

  Future<void> addToFavorites(int characterId) async {
    final favorites = await getFavorites();
    if (!favorites.contains(characterId)) {
      favorites.add(characterId);
      await _saveFavorites(favorites);
    }
  }

  Future<void> removeFromFavorites(int characterId) async {
    final favorites = await getFavorites();
    favorites.remove(characterId);
    await _saveFavorites(favorites);
  }

  Future<bool> isFavorite(int characterId) async {
    final favorites = await getFavorites();
    return favorites.contains(characterId);
  }

  Future<void> _saveFavorites(List<int> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesString = favorites.join(',');
    await prefs.setString(_favoritesKey, favoritesString);
  }

  Future<void> clearFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_favoritesKey);
  }
}