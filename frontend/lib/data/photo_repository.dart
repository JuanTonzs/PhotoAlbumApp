import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:frontend/config.dart';
import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';

class AlbumPhoto {
  const AlbumPhoto({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.date,
  });

  final String id;
  final String imageUrl;
  final String title;
  final String description;
  final DateTime date;
}

abstract class PhotoRepository {
  Future<List<AlbumPhoto>> getPhotos();

  Future<void> addPhoto({
    required String imagePath,
    required String title,
    required String description,
    required DateTime date,
  });
}

class CloudPhotoRepository implements PhotoRepository {
  static const _timeout = Duration(seconds: 30);

  Map<String, String> get _auth =>
      {'Authorization': 'Bearer ${Config.apiToken}'};

  @override
  Future<List<AlbumPhoto>> getPhotos() async {
    final res = await http
        .get(Uri.parse('${Config.apiBase}/photos'), headers: _auth)
        .timeout(_timeout);

    if (res.statusCode != 200) {
      throw Exception('Could not load photos (${res.statusCode})');
    }

    final list = jsonDecode(res.body) as List;
    return list
        .map((j) => AlbumPhoto(
              id: j['id'] as String,
              imageUrl: '${Config.apiBase}/photos/${j['id']}/image',
              title: (j['title'] as String?) ?? '',
              description: (j['description'] as String?) ?? '',
              date: DateTime.parse(j['date'] as String),
            ))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  @override
  Future<void> addPhoto({
    required String imagePath,
    required String title,
    required String description,
    required DateTime date,
  }) async {
    final bytes = await File(imagePath).readAsBytes();
    final isPng = imagePath.toLowerCase().endsWith('.png');

    final res = await http
        .post(
          Uri.parse('${Config.apiBase}/photos'),
          headers: {
            ..._auth,
            'Content-Type': isPng ? 'image/png' : 'image/jpeg',
            'X-Title': Uri.encodeComponent(title),
            'X-Description': Uri.encodeComponent(description),
            'X-Date': date.toIso8601String(),
          },
          body: bytes,
        )
        .timeout(_timeout);

    if (res.statusCode != 201) {
      throw Exception('Upload failed (${res.statusCode})');
    }
  }
}

// One shared instance for the whole app.
final PhotoRepository photoRepository = CloudPhotoRepository();

// Cloud photos send the token and are cached on disk; local files still work.
ImageProvider imageProviderFor(String source) {
  if (source.startsWith(Config.apiBase)) {
    return CachedNetworkImageProvider(
      source,
      headers: {'Authorization': 'Bearer ${Config.apiToken}'},
    );
  }
  return source.startsWith('http') ? NetworkImage(source) : FileImage(File(source));
}