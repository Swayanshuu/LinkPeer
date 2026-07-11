import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:igit_connects/core/update/update_model.dart';

class UpdateService {
  // TODO: Replace with your actual GitHub Raw JSON URL
  static const String updateConfigUrl =
      'https://raw.githubusercontent.com/Swayanshuu/SWYNX-Hepler/main/linkpeer-update.json';
  static const String _cacheKey = 'cached_update_info';

  Future<UpdateModel?> fetchUpdateInfo() async {
    try {
      final response = await http.get(Uri.parse(updateConfigUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final updateInfo = UpdateModel.fromJson(data);

        // Cache the response
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cacheKey, jsonEncode(data));

        return updateInfo;
      } else {
        // Fallback to cache if server returns non-200
        return await _getCachedUpdateInfo();
      }
    } catch (e) {
      // In case of network error, try to load from cache
      return await _getCachedUpdateInfo();
    }
  }

  Future<UpdateModel?> _getCachedUpdateInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedStr = prefs.getString(_cacheKey);
    if (cachedStr != null) {
      try {
        final data = jsonDecode(cachedStr);
        return UpdateModel.fromJson(data);
      } catch (_) {}
    }
    return null;
  }

  Future<bool> hasUpdate() async {
    final updateInfo = await fetchUpdateInfo();
    if (updateInfo == null) {
      return false;
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;
      return updateInfo.latestVersionCode > currentBuildNumber;
    } catch (e) {
      return false;
    }
  }

  Future<void> refresh() async {
    await fetchUpdateInfo();
  }
}
