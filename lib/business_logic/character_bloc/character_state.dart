import 'package:equatable/equatable.dart';
import '/data/models/character_model.dart';

class CharacterState extends Equatable {
  final List<CharacterModel> characters;
  final List<int> favoriteIds; 
  final bool isLoading;
  final bool isLoadingNextPage;
  final String? error;
  final int currentPage;
  final bool hasReachedMax;

  const CharacterState({
    required this.characters,
    required this.favoriteIds,
    this.isLoading = false,
    this.isLoadingNextPage = false,
    this.error,
    this.currentPage = 1,
    this.hasReachedMax = false,
  });

  CharacterState copyWith({
    List<CharacterModel>? characters,
    List<int>? favoriteIds,
    bool? isLoading,
    bool? isLoadingNextPage,
    String? error,
    int? currentPage,
    bool? hasReachedMax,
  }) {
    return CharacterState(
      characters: characters ?? this.characters,
      favoriteIds: favoriteIds ?? this.favoriteIds,
      isLoading: isLoading ?? this.isLoading,
      isLoadingNextPage: isLoadingNextPage ?? this.isLoadingNextPage,
      error: error ?? this.error,
      currentPage: currentPage ?? this.currentPage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  factory CharacterState.initial() {
    return const CharacterState(
      characters: [],
      favoriteIds: [],
      isLoading: false,
      isLoadingNextPage: false,
      error: null,
      currentPage: 1,
      hasReachedMax: false,
    );
  }

  // Проверяем, находится ли персонаж в избранном
  bool isCharacterFavorite(int characterId) {
    return favoriteIds.contains(characterId);
  }

  @override
  List<Object?> get props => [
    characters,
    favoriteIds,
    isLoading,
    isLoadingNextPage,
    error,
    currentPage,
    hasReachedMax,
  ];
}