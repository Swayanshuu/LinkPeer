import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:igit_connects/core/models/notification_model.dart';
import 'package:igit_connects/core/services/notification_service.dart';

class NotificationNotifier extends AsyncNotifier<List<NotificationModel>> {
  final NotificationService _notificationService = NotificationService();
  int _offset = 0;
  final int _limit = 20;
  bool hasMore = true;

  @override
  Future<List<NotificationModel>> build() async {
    return _loadCacheAndFetch();
  }

  Future<List<NotificationModel>> _loadCacheAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    const cacheKey = 'cached_notifications';
    final cachedStr = prefs.getString(cacheKey);

    if (cachedStr != null) {
      try {
        final decoded = jsonDecode(cachedStr) as List<dynamic>;
        final cachedList = decoded
            .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
            .toList();
        
        // Trigger background fetch to update the state silently
        _fetchNetworkAndUpdate();
        
        return cachedList;
      } catch (_) {}
    }

    // No cache available, fetch from network and wait
    return await _fetchNetwork();
  }

  Future<void> _fetchNetworkAndUpdate() async {
    try {
      final freshData = await _fetchNetwork();
      state = AsyncData(freshData);
    } catch (e) {
      // Background fetch failed, silently ignore to keep cache shown
    }
  }

  Future<List<NotificationModel>> _fetchNetwork() async {
    _offset = 0;
    final newNotifications = await _notificationService.getNotifications(
      offset: _offset,
      limit: _limit,
    );

    _offset += newNotifications.length;
    hasMore = newNotifications.length == _limit;

    // Cache the latest notifications
    final prefs = await SharedPreferences.getInstance();
    const cacheKey = 'cached_notifications';
    final mapList = newNotifications.map((n) => n.toJson()).toList();
    await prefs.setString(cacheKey, jsonEncode(mapList));

    return newNotifications;
  }

  Future<void> loadMore() async {
    if (!hasMore || state.isLoading || !state.hasValue) return;

    try {
      final moreNotifications = await _notificationService.getNotifications(
        offset: _offset,
        limit: _limit,
      );

      _offset += moreNotifications.length;
      hasMore = moreNotifications.length == _limit;

      state = AsyncData([...state.value!, ...moreNotifications]);
    } catch (e) {
      // Handle error gracefully
    }
  }

  Future<void> forceRefresh() async {
    state = const AsyncLoading();
    try {
      final freshData = await _fetchNetwork();
      state = AsyncData(freshData);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> markAsRead(NotificationModel notification) async {
    if (!state.hasValue) return;
    
    // Optimistic update locally
    final currentList = state.value!;
    final index = currentList.indexWhere((n) => n.id == notification.id);
    if (index != -1) {
      final newList = List<NotificationModel>.from(currentList);
      newList[index] = NotificationModel(
        id: notification.id,
        userId: notification.userId,
        type: notification.type,
        title: notification.title,
        body: notification.body,
        isRead: true, // Marked as read
        createdAt: notification.createdAt,
        actorUserId: notification.actorUserId,
        postId: notification.postId,
        commentId: notification.commentId,
        actorName: notification.actorName,
        actorPhotoUrl: notification.actorPhotoUrl,
      );
      state = AsyncData(newList);
    }

    // Call service to update backend
    await _notificationService.markAsRead(notification.id);
  }
}

final notificationProvider = AsyncNotifierProvider<NotificationNotifier, List<NotificationModel>>(
  () => NotificationNotifier(),
);
