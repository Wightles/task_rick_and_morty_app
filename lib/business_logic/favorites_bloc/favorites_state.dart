// lib/business_logic/favorites_bloc/favorites_state.dart
import 'package:equatable/equatable.dart';
import '/business_logic/favorites_bloc/favorites_event.dart';
import '/data/models/character_model.dart';

class FavoritesState extends Equatable {
  final List<CharacterModel> characters;
  final List<int> favoriteIds;
  final bool isLoading;
  final String? error;
  final FavoritesSortType sortType;

  const FavoritesState({
    required this.characters,
    required this.favoriteIds,
    this.isLoading = false,
    this.error,
    this.sortType = FavoritesSortType.nameAsc,
  });

  FavoritesState copyWith({
    List<CharacterModel>? characters,
    List<int>? favoriteIds,
    bool? isLoading,
    String? error,
    FavoritesSortType? sortType,
  }) {
    return FavoritesState(
      characters: characters ?? this.characters,
      favoriteIds: favoriteIds ?? this.favoriteIds,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      sortType: sortType ?? this.sortType,
    );
  }

  factory FavoritesState.initial() {
    return const FavoritesState(
      characters: [],
      favoriteIds: [],
      isLoading: false,
      error: null,
      sortType: FavoritesSortType.nameAsc,
    );
  }

  // Получить отсортированный список персонажей
  List<CharacterModel> get sortedCharacters {
    switch (sortType) {
      case FavoritesSortType.nameAsc:
        return List.from(characters)
          ..sort((a, b) => a.name.compareTo(b.name));
      case FavoritesSortType.nameDesc:
        return List.from(characters)
          ..sort((a, b) => b.name.compareTo(a.name));
      case FavoritesSortType.status:
        return List.from(characters)
          ..sort((a, b) => a.status.compareTo(b.status));
      case FavoritesSortType.species:
        return List.from(characters)
          ..sort((a, b) => a.species.compareTo(b.species));
    }
  }

  @override
  List<Object?> get props => [
    characters,
    favoriteIds,
    isLoading,
    error,
    sortType,
  ];
}