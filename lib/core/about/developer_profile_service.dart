import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:igit_connects/core/about/developer_profile_model.dart';

class DeveloperProfileService {
  // TODO: Replace with your actual GitHub Raw JSON URL
  static const String developerProfileUrl =
      'https://raw.githubusercontent.com/Swayanshuu/SWYNX-Hepler/main/social-helper.json';
  static const String _cacheKey = 'cached_developer_profile';

  Future<DeveloperProfileModel?> fetchProfile() async {
    try {
      final response = await http.get(Uri.parse(developerProfileUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final profile = DeveloperProfileModel.fromJson(data);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cacheKey, jsonEncode(data));

        return profile;
      } else {
        return await _getCachedProfile();
      }
    } catch (e) {
      return await _getCachedProfile();
    }
  }

  Future<DeveloperProfileModel?> _getCachedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedStr = prefs.getString(_cacheKey);
    if (cachedStr != null) {
      try {
        final data = jsonDecode(cachedStr);
        return DeveloperProfileModel.fromJson(data);
      } catch (_) {}
    }
    return null;
  }
}
