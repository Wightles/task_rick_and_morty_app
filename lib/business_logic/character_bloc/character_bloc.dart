import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibration/vibration.dart';
import '/data/repositories/character_repository.dart';
import '/data/services/favorites_service.dart';
import 'character_event.dart';
import 'character_state.dart';

class CharacterBloc extends Bloc<CharacterEvent, CharacterState> {
  final CharacterRepository _characterRepository;
  final FavoritesService _favoritesService;
  bool _isLoadingNextPage = false;

  CharacterBloc({
    required CharacterRepository characterRepository,
    required FavoritesService favoritesService,
  })  : _characterRepository = characterRepository,
        _favoritesService = favoritesService,
        super(CharacterState.initial()) {
    on<CharacterFetchEvent>(_onCharacterFetch);
    on<CharacterLoadNextPageEvent>(_onLoadNextPage);
    on<CharacterToggleFavoriteEvent>(_onToggleFavorite);
    
    _loadFavorites();
  }

  // Загрузка избранных ID
  Future<void> _loadFavorites() async {
    try {
      final favoriteIds = await _favoritesService.getFavorites();
      emit(state.copyWith(favoriteIds: favoriteIds));
    } catch (e) {
      debugPrint('Ошибка при загрузке избранного: $e');
    }
  }

  Future<void> _onCharacterFetch(
    CharacterFetchEvent event,
    Emitter<CharacterState> emit,
  ) async {
    if (event.isRefresh) {
      emit(CharacterState.initial());
      await _loadFavorites();
      emit(state.copyWith(isLoading: true, error: null));
      
      try {
        final response = await _characterRepository.getCharacters(
          page: 1,
          forceRefresh: true,
          autoLoadMore: true,
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
      final response = await _characterRepository.getCharacters(
        page: 1,
        autoLoadMore: true,
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
  }

  // Обработчик события загрузки следующей страницы
  Future<void> _onLoadNextPage(
    CharacterLoadNextPageEvent event,
    Emitter<CharacterState> emit,
  ) async {
    if (_isLoadingNextPage || state.hasReachedMax) {
      return;
    }
    
    _isLoadingNextPage = true;
    emit(state.copyWith(isLoadingNextPage: true));
    
    try {
      final nextPage = state.currentPage + 1;
      final response = await _characterRepository.getCharacters(
        page: nextPage,
        autoLoadMore: true,
      );
      
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
    } finally {
      _isLoadingNextPage = false;
    }
  }

  // Обработчик события добавления/удаления из избранного
  Future<void> _onToggleFavorite(
    CharacterToggleFavoriteEvent event,
    Emitter<CharacterState> emit,
  ) async {
    try {
      if (event.isFavorite) {
        await _favoritesService.removeFromFavorites(event.characterId);
      } else {
        await _favoritesService.addToFavorites(event.characterId);
      }
      
      final updatedFavorites = await _favoritesService.getFavorites();
      emit(state.copyWith(favoriteIds: updatedFavorites));
      
      _vibrateForFavorite(isFavorite: !event.isFavorite);
      
      debugPrint('CharacterBloc: обновлены фавориты. Теперь: ${updatedFavorites.length} шт');
    } catch (e) {
      debugPrint('Ошибка при обновлении избранного: $e');
    }
  }

  void _vibrateForFavorite({required bool isFavorite}) {
    Future.microtask(() async {
      if (await Vibration.hasVibrator() ?? false) {
        if (isFavorite) {
          await Vibration.vibrate(duration: 30);
        } else {
          await Vibration.vibrate(duration: 50);
        }
      }
    });
  }

  Future<void> refreshFavorites() async {
    try {
      final favoriteIds = await _favoritesService.getFavorites();
      emit(state.copyWith(favoriteIds: favoriteIds));
      debugPrint('CharacterBloc: фавориты обновлены через refreshFavorites()');
    } catch (e) {
      debugPrint('Ошибка при обновлении фаворитов: $e');
    }
  }
}