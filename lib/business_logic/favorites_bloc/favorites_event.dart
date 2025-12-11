import 'package:equatable/equatable.dart';

import 'favorites_state.dart';

abstract class FavoritesEvent extends Equatable {
  const FavoritesEvent();

  @override
  List<Object?> get props => [];
}

// Событие загрузки фаворитов
class FavoritesLoadEvent extends FavoritesEvent {
  const FavoritesLoadEvent();

  @override
  List<Object?> get props => [];
}

// Событие удаления из фаворитов
class FavoritesRemoveEvent extends FavoritesEvent {
  final int characterId;

  const FavoritesRemoveEvent(this.characterId);

  @override
  List<Object?> get props => [characterId];
}

// Событие очистки всех фаворитов
class FavoritesClearEvent extends FavoritesEvent {
  const FavoritesClearEvent();

  @override
  List<Object?> get props => [];
}

// Событие сортировки фаворитов
class FavoritesSortEvent extends FavoritesEvent {
  final FavoritesSortType sortType;

  const FavoritesSortEvent(this.sortType);

  @override
  List<Object?> get props => [sortType];
}