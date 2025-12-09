import 'package:equatable/equatable.dart';

// Базовый класс для событий
abstract class CharacterEvent extends Equatable {
  const CharacterEvent();

  @override
  List<Object?> get props => [];
}

// Событие загрузки персонажей
class CharacterFetchEvent extends CharacterEvent {
  final bool isRefresh; // Для pull-to-refresh
  
  const CharacterFetchEvent({this.isRefresh = false});

  @override
  List<Object?> get props => [isRefresh];
}

// Событие загрузки следующей страницы (пагинация)
class CharacterLoadNextPageEvent extends CharacterEvent {
  const CharacterLoadNextPageEvent();

  @override
  List<Object?> get props => [];
}

// Событие добавления/удаления из избранного
class CharacterToggleFavoriteEvent extends CharacterEvent {
  final int characterId;
  final bool isFavorite;
  
  const CharacterToggleFavoriteEvent({
    required this.characterId,
    required this.isFavorite,
  });

  @override
  List<Object?> get props => [characterId, isFavorite];
}