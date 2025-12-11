import 'package:equatable/equatable.dart';
import '/data/models/character_model.dart';

enum FavoritesSortType {
  nameAsc,
  nameDesc,
  status,
  species,
}

class FavoritesState extends Equatable {
  final List<CharacterModel> favorites;
  final List<int> favoriteIds;
  final bool isLoading;
  final String? error;
  final FavoritesSortType sortType;

  const FavoritesState({
    required this.favorites,
    required this.favoriteIds,
    this.isLoading = false,
    this.error,
    this.sortType = FavoritesSortType.nameAsc,
  });

  FavoritesState copyWith({
    List<CharacterModel>? favorites,
    List<int>? favoriteIds,
    bool? isLoading,
    String? error,
    FavoritesSortType? sortType,
  }) {
    return FavoritesState(
      favorites: favorites ?? this.favorites,
      favoriteIds: favoriteIds ?? this.favoriteIds,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      sortType: sortType ?? this.sortType,
    );
  }

  factory FavoritesState.initial() {
    return const FavoritesState(
      favorites: [],
      favoriteIds: [],
      isLoading: false,
      error: null,
      sortType: FavoritesSortType.nameAsc,
    );
  }

  List<CharacterModel> get sortedCharacters {
    switch (sortType) {
      case FavoritesSortType.nameAsc:
        return List<CharacterModel>.from(favorites)
          ..sort((a, b) => a.name.compareTo(b.name));
      case FavoritesSortType.nameDesc:
        return List<CharacterModel>.from(favorites)
          ..sort((a, b) => b.name.compareTo(a.name));
      case FavoritesSortType.status:
        return List<CharacterModel>.from(favorites)
          ..sort((a, b) => a.status.compareTo(b.status));
      case FavoritesSortType.species:
        return List<CharacterModel>.from(favorites)
          ..sort((a, b) => a.species.compareTo(b.species));
    }
  }

  @override
  List<Object?> get props => [
    favorites,
    favoriteIds,
    isLoading,
    error,
    sortType,
  ];
}