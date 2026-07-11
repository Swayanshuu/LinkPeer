import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:igit_connects/core/about/support_links_model.dart';

class SupportLinksService {
  // TODO: Replace with your actual GitHub Raw JSON URL
  static const String supportLinksUrl =
      'https://raw.githubusercontent.com/Swayanshuu/SWYNX-Hepler/main/linkpeer-support.json';
  static const String _cacheKey = 'cached_support_links';

  Future<SupportLinksModel?> fetchLinks() async {
    try {
      final response = await http.get(Uri.parse(supportLinksUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final links = SupportLinksModel.fromJson(data);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cacheKey, jsonEncode(data));

        return links;
      } else {
        return await _getCachedLinks();
      }
    } catch (e) {
      return await _getCachedLinks();
    }
  }

  Future<SupportLinksModel?> _getCachedLinks() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedStr = prefs.getString(_cacheKey);
    if (cachedStr != null) {
      try {
        final data = jsonDecode(cachedStr);
        return SupportLinksModel.fromJson(data);
      } catch (_) {}
    }
    return null;
  }
}
