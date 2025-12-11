import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  static const String _cacheFolder = 'image_cache';
  static const Duration _cacheDuration = Duration(days: 30);
  final Map<String, File> _memoryCache = {};

  // Получение кэшированного изображения
  Future<File?> getCachedImage(String imageUrl) async {
    if (_memoryCache.containsKey(imageUrl)) {
      return _memoryCache[imageUrl];
    }

    final fileName = _getFileName(imageUrl);
    final cacheFile = await _getCacheFile(fileName);

    if (await cacheFile.exists()) {
      final lastModified = await cacheFile.lastModified();
      if (DateTime.now().difference(lastModified) < _cacheDuration) {
        _memoryCache[imageUrl] = cacheFile;
        return cacheFile;
      } else {
        await cacheFile.delete();
      }
    }

    return null;
  }

  // Загрузка и кэширование изображения
  Future<File> cacheImage(String imageUrl) async {
    try {
      final cachedFile = await getCachedImage(imageUrl);
      if (cachedFile != null) {
        return cachedFile;
      }

      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to load image: ${response.statusCode}');
      }

      final fileName = _getFileName(imageUrl);
      final cacheFile = await _getCacheFile(fileName);
      await cacheFile.writeAsBytes(response.bodyBytes);

      _memoryCache[imageUrl] = cacheFile;

      return cacheFile;
    } catch (e) {
      print('Error caching image: $e');
      rethrow;
    }
  }

  // Получение изображения с кэшированием
  Future<Uint8List> getImageBytes(String imageUrl) async {
    try {
      final cachedFile = await getCachedImage(imageUrl);
      if (cachedFile != null) {
        return await cachedFile.readAsBytes();
      }

      final file = await cacheImage(imageUrl);
      return await file.readAsBytes();
    } catch (e) {
      print('Error getting image bytes: $e');
      rethrow;
    }
  }

  // Получение FileImage для отображения
  Future<FileImage> getCachedFileImage(String imageUrl) async {
    final file = await getCachedImage(imageUrl) ?? await cacheImage(imageUrl);
    return FileImage(file);
  }

  // Очистка кэша изображений
  Future<void> clearImageCache() async {
    try {
      _memoryCache.clear();

      final cacheDir = await _getCacheDirectory();
      if (await cacheDir.exists()) {
        final files = cacheDir.listSync();
        for (final file in files) {
          if (file is File) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      print('Error clearing image cache: $e');
    }
  }

  // Получение размера кэша изображений
  Future<int> getImageCacheSize() async {
    try {
      final cacheDir = await _getCacheDirectory();
      if (!await cacheDir.exists()) {
        return 0;
      }

      int totalSize = 0;
      final files = cacheDir.listSync();
      for (final file in files) {
        if (file is File) {
          totalSize += await file.length();
        }
      }

      return totalSize;
    } catch (e) {
      print('Error getting image cache size: $e');
      return 0;
    }
  }

  // Получение имени файла из URL
  String _getFileName(String imageUrl) {
    final uri = Uri.parse(imageUrl);
    final pathSegments = uri.pathSegments;
    return pathSegments.isNotEmpty ? pathSegments.last : 'image_${imageUrl.hashCode}';
  }

  // Получение файла в кэше
  Future<File> _getCacheFile(String fileName) async {
    final cacheDir = await _getCacheDirectory();
    return File('${cacheDir.path}/$fileName');
  }

  // Получение директории кэша
  Future<Directory> _getCacheDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDocDir.path}/$_cacheFolder');
    
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }

    return cacheDir;
  }
}