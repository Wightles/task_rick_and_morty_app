// lib/business_logic/favorites_bloc/favorites_event.dart
import 'package:equatable/equatable.dart';

// Базовый класс для событий
abstract class FavoritesEvent extends Equatable {
  const FavoritesEvent();

  @override
  List<Object?> get props => [];
}

// Событие загрузки избранного
class FavoritesLoadEvent extends FavoritesEvent {
  const FavoritesLoadEvent();
}

// Событие удаления из избранного
class FavoritesRemoveEvent extends FavoritesEvent {
  final int characterId;
  
  const FavoritesRemoveEvent(this.characterId);

  @override
  List<Object?> get props => [characterId];
}

// Событие сортировки
class FavoritesSortEvent extends FavoritesEvent {
  final FavoritesSortType sortType;
  
  const FavoritesSortEvent(this.sortType);

  @override
  List<Object?> get props => [sortType];
}

// Типы сортировки
enum FavoritesSortType {
  nameAsc,    // По имени (А-Я)
  nameDesc,   // По имени (Я-А)
  status,     // По статусу
  species,    // По виду
}