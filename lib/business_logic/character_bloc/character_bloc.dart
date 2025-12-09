// lib/business_logic/character_bloc/character_bloc.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '/data/repositories/character_repository.dart';
import '/data/services/favorites_service.dart';
import 'character_event.dart';
import 'character_state.dart';

class CharacterBloc extends Bloc<CharacterEvent, CharacterState> {
  final CharacterRepository _characterRepository;
  final FavoritesService _favoritesService;

  CharacterBloc({
    required CharacterRepository characterRepository,
    required FavoritesService favoritesService,
  })  : _characterRepository = characterRepository,
        _favoritesService = favoritesService,
        super(CharacterState.initial()) {
    // Регистрируем обработчики событий
    on<CharacterFetchEvent>(_onCharacterFetch);
    on<CharacterLoadNextPageEvent>(_onLoadNextPage);
    on<CharacterToggleFavoriteEvent>(_onToggleFavorite);
    
    // Загружаем избранное при инициализации
    _loadFavorites();
  }

  // Загрузка избранных ID
  Future<void> _loadFavorites() async {
    try {
      final favoriteIds = await _favoritesService.getFavorites();
      emit(state.copyWith(favoriteIds: favoriteIds));
    } catch (e) {
      // Ошибка при загрузке избранного, но не прерываем работу
      print('Ошибка при загрузке избранного: $e');
    }
  }

  Future<void> _onCharacterFetch(
  CharacterFetchEvent event,
  Emitter<CharacterState> emit,
) async {
  // Если это refresh, сбрасываем состояние и грузим из сети
  if (event.isRefresh) {
    emit(CharacterState.initial());
    await _loadFavorites();
    emit(state.copyWith(isLoading: true, error: null));
    
    try {
      final response = await _characterRepository.getCharacters(
        page: 1,
        forceRefresh: true, // Принудительно из сети
      );
      
      emit(state.copyWith(
        characters: response.results,
        isLoading: false,
        currentPage: 1,
        hasReachedMax: response.info.next == null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
    return;
  }
  
  // Обычная загрузка (может быть из кэша)
  emit(state.copyWith(isLoading: true, error: null));
  
  try {
    final response = await _characterRepository.getCharacters(page: 1);
    
    emit(state.copyWith(
      characters: response.results,
      isLoading: false,
      currentPage: 1,
      hasReachedMax: response.info.next == null,
    ));
  } catch (e) {
    emit(state.copyWith(
      isLoading: false,
      error: e.toString(),
    ));
  }
}

  // Обработчик события загрузки следующей страницы
  Future<void> _onLoadNextPage(
    CharacterLoadNextPageEvent event,
    Emitter<CharacterState> emit,
  ) async {
    // Проверяем, нужно ли загружать следующую страницу
    if (state.isLoadingNextPage || state.hasReachedMax) {
      return;
    }
    
    emit(state.copyWith(isLoadingNextPage: true));
    
    try {
      final nextPage = state.currentPage + 1;
      final response = await _characterRepository.getCharacters(page: nextPage);
      
      final allCharacters = [...state.characters, ...response.results];
      
      emit(state.copyWith(
        characters: allCharacters,
        isLoadingNextPage: false,
        currentPage: nextPage,
        hasReachedMax: response.info.next == null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingNextPage: false,
        error: e.toString(),
      ));
    }
  }

  // Обработчик события добавления/удаления из избранного
  Future<void> _onToggleFavorite(
    CharacterToggleFavoriteEvent event,
    Emitter<CharacterState> emit,
  ) async {
    try {
      if (event.isFavorite) {
        // Удаляем из избранного
        await _favoritesService.removeFromFavorites(event.characterId);
      } else {
        // Добавляем в избранное
        await _favoritesService.addToFavorites(event.characterId);
      }
      
      // Обновляем список избранных ID
      final updatedFavorites = await _favoritesService.getFavorites();
      emit(state.copyWith(favoriteIds: updatedFavorites));
    } catch (e) {
      // Обработка ошибки (можно показать SnackBar)
      print('Ошибка при обновлении избранного: $e');
      // Можно добавить состояние с ошибкой
    }
  }
}