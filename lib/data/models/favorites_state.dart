class FavoritesState {
  final List<int> favoriteIds;
  final bool isLoading;
  final String? error;

  FavoritesState({
    required this.favoriteIds,
    this.isLoading = false,
    this.error,
  });

  FavoritesState copyWith({
    List<int>? favoriteIds,
    bool? isLoading,
    String? error,
  }) {
    return FavoritesState(
      favoriteIds: favoriteIds ?? this.favoriteIds,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  factory FavoritesState.initial() {
    return FavoritesState(
      favoriteIds: [],
      isLoading: false,
      error: null,
    );
  }
}