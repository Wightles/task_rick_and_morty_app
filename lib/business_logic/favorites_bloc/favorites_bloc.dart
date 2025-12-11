import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/character_model.dart';
import '/data/repositories/character_repository.dart';
import '/data/services/favorites_service.dart';
import 'favorites_event.dart';
import 'favorites_state.dart';

class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  final CharacterRepository _characterRepository;
  final FavoritesService _favoritesService;
  StreamSubscription? _favoritesSubscription;

  FavoritesBloc({
    required CharacterRepository characterRepository,
    required FavoritesService favoritesService,
  })  : _characterRepository = characterRepository,
        _favoritesService = favoritesService,
        super(FavoritesState.initial()) {
    on<FavoritesLoadEvent>(_onLoadFavorites);
    on<FavoritesRemoveEvent>(_onRemoveFavorite);
    on<FavoritesClearEvent>(_onClearFavorites);
    on<FavoritesSortEvent>(_onSortFavorites);
    
    add(const FavoritesLoadEvent());
  }

  @override
  Future<void> close() {
    _favoritesSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadFavorites(
    FavoritesLoadEvent event,
    Emitter<FavoritesState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    
    try {
      final favoriteIds = await _favoritesService.getFavorites();
      
      if (favoriteIds.isEmpty) {
        emit(state.copyWith(
          isLoading: false,
          favoriteIds: [],
          favorites: [],
        ));
        return;
      }
      
      List<CharacterModel> favorites;
      
      try {
        favorites = await _favoritesService.getFavoritesWithData();
        
        if (favorites.length < favoriteIds.length) {
          try {
            final missingIds = favoriteIds.where(
              (id) => !favorites.any((char) => char.id == id)
            ).toList();
            
            if (missingIds.isNotEmpty) {
              final missingCharacters = await _characterRepository.getMultipleCharacters(
                missingIds,
                allowCache: true,
              );
              favorites.addAll(missingCharacters);
              
              for (final character in missingCharacters) {
                await _favoritesService.addToFavorites(character.id, character);
              }
            }
          } catch (e) {
            print('Ошибка при загрузке недостающих фаворитов: $e');
          }
        }
      } catch (e) {
        favorites = await _characterRepository.getMultipleCharacters(
          favoriteIds,
          allowCache: true,
        );
      }
      
      emit(state.copyWith(
        isLoading: false,
        favoriteIds: favoriteIds,
        favorites: favorites,
      ));
      
    } catch (e) {
      final cachedFavorites = await _favoritesService.getFavoritesWithData();
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
        favorites: cachedFavorites,
        favoriteIds: cachedFavorites.map((c) => c.id).toList(),
      ));
    }
  }

  Future<void> _onRemoveFavorite(
    FavoritesRemoveEvent event,
    Emitter<FavoritesState> emit,
  ) async {
    try {
      await _favoritesService.removeFromFavorites(event.characterId);
      
      final updatedFavorites = state.favorites
          .where((character) => character.id != event.characterId)
          .toList();
      
      final updatedIds = updatedFavorites.map((c) => c.id).toList();
      
      emit(state.copyWith(
        favorites: updatedFavorites,
        favoriteIds: updatedIds,
      ));
      
    } catch (e) {
      emit(state.copyWith(error: 'Ошибка при удалении: $e'));
    }
  }

  Future<void> _onClearFavorites(
    FavoritesClearEvent event,
    Emitter<FavoritesState> emit,
  ) async {
    try {
      await _favoritesService.clearFavorites();
      emit(FavoritesState.initial());
    } catch (e) {
      emit(state.copyWith(error: 'Ошибка при очистке: $e'));
    }
  }

  void _onSortFavorites(
    FavoritesSortEvent event,
    Emitter<FavoritesState> emit,
  ) {
    final sortedFavorites = List<CharacterModel>.from(state.favorites);
    
    switch (event.sortType) {
      case FavoritesSortType.nameAsc:
        sortedFavorites.sort((a, b) => a.name.compareTo(b.name));
        break;
      case FavoritesSortType.nameDesc:
        sortedFavorites.sort((a, b) => b.name.compareTo(a.name));
        break;
      case FavoritesSortType.status:
        sortedFavorites.sort((a, b) => a.status.compareTo(b.status));
        break;
      case FavoritesSortType.species:
        sortedFavorites.sort((a, b) => a.species.compareTo(b.species));
        break;
    }
    
    emit(state.copyWith(
      favorites: sortedFavorites,
      sortType: event.sortType,
    ));
  }

  // Метод для обновления состояния при изменении из другого места
  Future<void> refreshFavorites() async {
    add(const FavoritesLoadEvent());
  }
}