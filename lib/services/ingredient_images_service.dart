import 'dart:convert';
import 'package:http/http.dart' as http;

class IngredientImageService {
  final Map<String, String> _cache = {};

  static const _unsplashKey = 'BG_jaAJgeU7OwfFcInZyX0bO5OEov_kzVJfZYpHbqdE';
  static const _pexelsKey =
      'TQTYIy9DOfDqnuPd5x4s8iB0X5lAAttHIsHzWBGCO93Txud97Jd10zQH';

  Future<String?> getImageUrl(String ingredient) async {
    final key = ingredient.toLowerCase().trim();
    if (_cache.containsKey(key)) {
      return _cache[key];
    }

    // Try Unsplash first
    final url = await _fetchUnsplash(key) ?? await _fetchPexels(key);
    if (url != null) {
      _cache[key] = url;
    }
    return url;
  }

  Future<String?> _fetchUnsplash(String q) async {
    final uri = Uri.https('api.unsplash.com', '/search/photos', {
      'query': q,
      'per_page': '1',
      'client_id': _unsplashKey,
    });
    final r = await http.get(uri);
    if (r.statusCode != 200) return null;
    final data = json.decode(r.body);
    final results = (data['results'] as List).cast<Map<String, dynamic>>();
    if (results.isEmpty) return null;
    return results.first['urls']['small'] as String;
  }

  Future<String?> _fetchPexels(String q) async {
    final uri = Uri.https('api.pexels.com', '/v1/search', {
      'query': q,
      'per_page': '1',
    });
    final r = await http.get(uri, headers: {'Authorization': _pexelsKey});
    if (r.statusCode != 200) return null;
    final data = json.decode(r.body);
    final photos = (data['photos'] as List).cast<Map<String, dynamic>>();
    if (photos.isEmpty) return null;
    return photos.first['src']['medium'] as String;
  }
}
