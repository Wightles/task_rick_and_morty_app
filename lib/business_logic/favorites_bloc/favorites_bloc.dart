// lib/business_logic/favorites_bloc/favorites_bloc.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '/data/models/character_model.dart';
import '/data/repositories/character_repository.dart';
import '/data/services/favorites_service.dart';
import 'favorites_event.dart';
import 'favorites_state.dart';

class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  final CharacterRepository _characterRepository;
  final FavoritesService _favoritesService;

  FavoritesBloc({
    required CharacterRepository characterRepository,
    required FavoritesService favoritesService,
  })  : _characterRepository = characterRepository,
        _favoritesService = favoritesService,
        super(FavoritesState.initial()) {
    // Регистрируем обработчики событий
    on<FavoritesLoadEvent>(_onLoad);
    on<FavoritesRemoveEvent>(_onRemove);
    on<FavoritesSortEvent>(_onSort);
  }

  // Обновленный метод _onLoad в FavoritesBloc
Future<void> _onLoad(
  FavoritesLoadEvent event,
  Emitter<FavoritesState> emit,
) async {
  emit(state.copyWith(isLoading: true, error: null));
  
  try {
    // 1. Получаем список ID избранных
    final favoriteIds = await _favoritesService.getFavorites();
    
    if (favoriteIds.isEmpty) {
      emit(state.copyWith(
        favoriteIds: favoriteIds,
        characters: [],
        isLoading: false,
      ));
      return;
    }
    
    // 2. Загружаем всех избранных персонажей одним запросом
    final favoriteCharacters = await _characterRepository.getMultipleCharacters(favoriteIds);
    
    emit(state.copyWith(
      favoriteIds: favoriteIds,
      characters: favoriteCharacters,
      isLoading: false,
    ));
  } catch (e) {
    emit(state.copyWith(
      isLoading: false,
      error: 'Ошибка при загрузке избранного: $e',
    ));
  }
}

  // Удаление из избранного
  Future<void> _onRemove(
    FavoritesRemoveEvent event,
    Emitter<FavoritesState> emit,
  ) async {
    try {
      // Удаляем из SharedPreferences
      await _favoritesService.removeFromFavorites(event.characterId);
      
      // Обновляем список ID
      final updatedIds = await _favoritesService.getFavorites();
      
      // Удаляем персонажа из списка
      final updatedCharacters = state.characters
          .where((char) => char.id != event.characterId)
          .toList();
      
      emit(state.copyWith(
        favoriteIds: updatedIds,
        characters: updatedCharacters,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: 'Ошибка при удалении из избранного: $e',
      ));
    }
  }

  // Сортировка
  Future<void> _onSort(
    FavoritesSortEvent event,
    Emitter<FavoritesState> emit,
  ) async {
    emit(state.copyWith(sortType: event.sortType));
  }
}