import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibration/vibration.dart';
import '/business_logic/character_bloc/character_state.dart';
import '/business_logic/character_bloc/character_event.dart';
import '/business_logic/character_bloc/character_bloc.dart';
import '/presentation/widgets/animated_character_card.dart';

class CharactersScreen extends StatefulWidget {
  const CharactersScreen({super.key});

  @override
  State<CharactersScreen> createState() => _CharactersScreenState();
}

class _CharactersScreenState extends State<CharactersScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingNextPage = false;

  // Быстрая вибрация без блокировки UI
  void _vibrateForFavorite({bool isFavorite = false}) {
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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<CharacterBloc>().add(const CharacterFetchEvent());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingNextPage) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    if (currentScroll > (maxScroll * 0.7)) {
      _loadNextPage();
    }
  }

  void _loadNextPage() {
    if (!_isLoadingNextPage) {
      _isLoadingNextPage = true;
      context.read<CharacterBloc>().add(const CharacterLoadNextPageEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<CharacterBloc, CharacterState>(
        listener: (context, state) {
          if (!state.isLoadingNextPage) {
            _isLoadingNextPage = false;
          }
        },
        builder: (context, state) {
          return _buildBody(context, state);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, CharacterState state) {
    if (state.isLoading && state.characters.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.characters.isEmpty) {
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
                context.read<CharacterBloc>().add(const CharacterFetchEvent());
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<CharacterBloc>().add(const CharacterFetchEvent(isRefresh: true));
      },
      child: ListView.builder(
        controller: _scrollController,
        itemCount: state.characters.length + 
                   (state.isLoadingNextPage ? 1 : 0) + 
                   (state.hasReachedMax ? 0 : 1),
        itemBuilder: (context, index) {
          if (index < state.characters.length) {
            final character = state.characters[index];
            final isFavorite = state.isCharacterFavorite(character.id);
            
            return AnimatedCharacterCard(
              character: character,
              isFavorite: isFavorite,
              onFavoriteToggle: () {
                _vibrateForFavorite(isFavorite: isFavorite);
                
                context.read<CharacterBloc>().add(
                  CharacterToggleFavoriteEvent(
                    characterId: character.id,
                    isFavorite: isFavorite,
                  ),
                );
              },
              onTap: () {
                debugPrint('Тап по ${character.name}');
              },
            );
          } else if (state.isLoadingNextPage) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          } else {
            return Container(
              height: 100,
              alignment: Alignment.center,
              child: const Text(
                'Это все персонажи',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }
        },
      ),
    );
  }
}