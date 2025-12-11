import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '/data/repositories/character_repository.dart';
import '/data/services/image_cache_service.dart';
import '/business_logic/character_bloc/character_bloc.dart';
import '/business_logic/character_bloc/character_event.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final CharacterRepository _characterRepository = CharacterRepository();
  final ImageCacheService _imageCacheService = ImageCacheService();
  
  bool _isClearingCache = false;
  bool _isRefreshingData = false;
  int _cacheSize = 0;
  int _imageCacheSize = 0;
  int _cachedPages = 0;
  int _cachedCharacters = 0;

  @override
  void initState() {
    super.initState();
    _loadCacheStats();
  }

  Future<void> _loadCacheStats() async {
    final size = await _characterRepository.getCacheSize();
    final imageSize = await _imageCacheService.getImageCacheSize();
    final pages = await _characterRepository.getMaxCachedPage();
    final characters = await _characterRepository.getCachedCharactersCount();
    
    setState(() {
      _cacheSize = size;
      _imageCacheSize = imageSize;
      _cachedPages = pages;
      _cachedCharacters = characters;
    });
  }

  Future<void> _clearCache() async {
    setState(() {
      _isClearingCache = true;
    });

    try {
      await _characterRepository.clearCache();
      await _loadCacheStats();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Кэш успешно очищен'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при очистке кэша: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      setState(() {
        _isClearingCache = false;
      });
    }
  }

  Future<void> _refreshAllData() async {
    setState(() {
      _isRefreshingData = true;
    });

    try {
      final characterBloc = BlocProvider.of<CharacterBloc>(context, listen: false);
      
      characterBloc.add(const CharacterFetchEvent(isRefresh: true));
      
      await _loadCacheStats();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Данные успешно обновлены'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при обновлении данных: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      setState(() {
        _isRefreshingData = false;
      });
    }
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить кэш?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Текущий кэш: $_cachedPages страниц, $_cachedCharacters персонажей'),
            const SizedBox(height: 16),
            const Text('Все загруженные данные будут удалены. При следующем открытии приложения данные будут загружены заново.'),
            const SizedBox(height: 8),
            const Text(
              'Это не удалит ваши избранные персонажи.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ОТМЕНА'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearCache();
            },
            child: const Text(
              'ОЧИСТИТЬ',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showRefreshDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Обновить данные?'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Загрузить свежие данные с сервера.'),
            SizedBox(height: 8),
            Text(
              'Это обновит кэш новыми данными и может занять некоторое время.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ОТМЕНА'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _refreshAllData();
            },
            child: const Text(
              'ОБНОВИТЬ',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes Б';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} КБ';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} МБ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          _buildCacheSection(),
          
          _buildRefreshSection(),
          
          _buildAboutSection(),
        ],
      ),
    );
  }

  Widget _buildCacheSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Данные и кэш',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.list, color: Colors.blue),
              title: const Text('Закэшированные данные'),
              subtitle: Text('$_cachedPages страниц, $_cachedCharacters персонажей'),
            ),
            ListTile(
              leading: const Icon(Icons.data_object, color: Colors.blue),
              title: const Text('Данные персонажей'),
              subtitle: Text(_formatBytes(_cacheSize - _imageCacheSize)),
            ),
            ListTile(
              leading: const Icon(Icons.image, color: Colors.green),
              title: const Text('Изображения'),
              subtitle: Text(_formatBytes(_imageCacheSize)),
            ),
            ListTile(
              leading: const Icon(Icons.storage, color: Colors.orange),
              title: const Text('Общий размер кэша'),
              subtitle: Text(_formatBytes(_cacheSize)),
              trailing: _isClearingCache
                  ? const CircularProgressIndicator()
                  : IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: _cacheSize > 0 ? _showClearCacheDialog : null,
                    ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Приложение автоматически сохраняет просмотренные страницы для работы без интернета.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefreshSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Обновление данных',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isRefreshingData ? null : _showRefreshDialog,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: _isRefreshingData
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(width: 16),
                        Text('Обновление...'),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.refresh),
                        SizedBox(width: 8),
                        Text('ОБНОВИТЬ ВСЕ ДАННЫЕ'),
                      ],
                    ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Загрузит свежие данные с сервера и обновит локальный кэш.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const ListTile(
              leading: Icon(Icons.info_outline, color: Colors.blue),
              title: Text('Что обновляется?'),
              subtitle: Text(
                'Все закэшированные страницы персонажей, изображения и данные.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return const Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'О приложении',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.info, color: Colors.purple),
              title: Text('Версия приложения'),
              subtitle: Text('1.0.0'),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.storage, color: Colors.blue),
              title: Text('Хранилище данных'),
              subtitle: Text('Автоматическое кэширование'),
            ),
            Divider(),
            ListTile(
              leading: Icon(CupertinoIcons.star_fill, color: Color.fromARGB(255, 218, 142, 35)),
              title: Text('Фавориты'),
              subtitle: Text('Сохраняются локально'),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.image, color: Colors.green),
              title: Text('Изображения'),
              subtitle: Text('Кэшируются автоматически'),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.api, color: Colors.blue),
              title: Text('Источник данных'),
              subtitle: Text('Rick and Morty API'),
            ),
          ],
        ),
      ),
    );
  }
}