import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibration/vibration.dart';
import '/business_logic/favorites_bloc/favorites_state.dart';
import '/business_logic/favorites_bloc/favorites_bloc.dart';
import '/business_logic/favorites_bloc/favorites_event.dart';
import '/business_logic/character_bloc/character_bloc.dart';
import '/business_logic/character_bloc/character_event.dart';
import '/presentation/widgets/animated_character_card.dart';
import 'package:cupertino_icons/cupertino_icons.dart';
import 'package:provider/provider.dart';
import '/business_logic/theme_provider.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  FavoritesSortType _currentSortType = FavoritesSortType.nameAsc;
  bool _showEmoji = true;
  Timer? _animationTimer;

  @override
  void initState() {
    super.initState();
    
    _startIconAnimation();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoritesBloc>().add(const FavoritesLoadEvent());
    });
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }

  void _startIconAnimation() {
    _animationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _showEmoji = !_showEmoji;
        });
      } else {
        timer.cancel();
      }
    });
  }

  // Быстрая вибрация без блокировки UI
  void _vibrateQuick({required bool isAdding}) {
    Future.microtask(() async {
      if (await Vibration.hasVibrator() ?? false) {
        if (isAdding) {
          await Vibration.vibrate(duration: 30);
        } else {
          await Vibration.vibrate(duration: 50);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<FavoritesBloc, FavoritesState>(
        builder: (context, state) {
          return _buildBody(context, state);
        },
      ),
      floatingActionButton: BlocBuilder<FavoritesBloc, FavoritesState>(
        builder: (context, state) {
          if (state.favorites.isNotEmpty) {
            return FloatingActionButton(
              onPressed: () => _showSortMenu(context),
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.sort, color: Colors.white),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, FavoritesState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<FavoritesBloc>().add(const FavoritesLoadEvent());
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    final characters = state.sortedCharacters;

    if (characters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 1000),
              child: _showEmoji
                  ? const Text(
                      '😔',
                      key: ValueKey('emoji'),
                      style: TextStyle(
                        fontSize: 80,
                      ),
                    )
                  : const Icon(
                      CupertinoIcons.star_fill,
                      key: ValueKey('icon'),
                      size: 80,
                      color: Color.fromARGB(255, 218, 142, 35),
                    ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Нет фаворитов',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Добавляйте персонажей в избранное, \nнажав на значок сердечка на экране «Персонажи».',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: characters.length,
      itemBuilder: (context, index) {
        final character = characters[index];

        return Dismissible(
          key: Key('Избранный_${character.id}_${DateTime.now().millisecondsSinceEpoch}'),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(
              Icons.delete,
              color: Colors.white,
              size: 30,
            ),
          ),
          onDismissed: (direction) {
            _vibrateQuick(isAdding: false);
            
            context
                .read<FavoritesBloc>()
                .add(FavoritesRemoveEvent(character.id));
            
            context.read<CharacterBloc>().add(
              CharacterToggleFavoriteEvent(
                characterId: character.id,
                isFavorite: true, 
              ),
            );

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${character.name} удален из избранного'),
                action: SnackBarAction(
                  label: 'ОТМЕНИТЬ',
                  onPressed: () {
                    _vibrateQuick(isAdding: true);
                    
                    context.read<CharacterBloc>().add(
                      CharacterToggleFavoriteEvent(
                        characterId: character.id,
                        isFavorite: false, 
                      ),
                    );
                    
                    context.read<FavoritesBloc>().add(const FavoritesLoadEvent());
                  },
                ),
                duration: const Duration(seconds: 3),
              ),
            );
          },
          child: AnimatedCharacterCard(
            character: character,
            isFavorite: true,
            onFavoriteToggle: () {
              _vibrateQuick(isAdding: false);
              
              context
                  .read<FavoritesBloc>()
                  .add(FavoritesRemoveEvent(character.id));
              
              context.read<CharacterBloc>().add(
                CharacterToggleFavoriteEvent(
                  characterId: character.id,
                  isFavorite: true, 
                ),
              );
            },
            onTap: () {
              print('Тап по ${character.name}');
            },
          ),
        );
      },
    );
  }

  void _showSortMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 16, bottom: 8),
                child: Text(
                  'Сортировка',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.sort_by_alpha, size: 24),
                title: const Text('Имя (А-Я)'),
                trailing: _currentSortType == FavoritesSortType.nameAsc
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _currentSortType = FavoritesSortType.nameAsc;
                  });
                  context
                      .read<FavoritesBloc>()
                      .add(FavoritesSortEvent(FavoritesSortType.nameAsc));
                },
              ),
              ListTile(
                leading: const Icon(Icons.sort_by_alpha, size: 24),
                title: const Text('Имя (Я-А)'),
                trailing: _currentSortType == FavoritesSortType.nameDesc
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _currentSortType = FavoritesSortType.nameDesc;
                  });
                  context
                      .read<FavoritesBloc>()
                      .add(FavoritesSortEvent(FavoritesSortType.nameDesc));
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.star_fill, size: 24),
                title: const Text('По статусу'),
                trailing: _currentSortType == FavoritesSortType.status
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _currentSortType = FavoritesSortType.status;
                  });
                  context
                      .read<FavoritesBloc>()
                      .add(FavoritesSortEvent(FavoritesSortType.status));
                },
              ),
              ListTile(
                leading: const Icon(Icons.pets, size: 24),
                title: const Text('По видам'),
                trailing: _currentSortType == FavoritesSortType.species
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _currentSortType = FavoritesSortType.species;
                  });
                  context
                      .read<FavoritesBloc>()
                      .add(FavoritesSortEvent(FavoritesSortType.species));
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}