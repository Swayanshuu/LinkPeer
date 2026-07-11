import 'package:flutter/material.dart';
import 'package:igit_connects/core/app_colors.dart';
import 'package:igit_connects/core/models/notification_model.dart';
import 'package:igit_connects/core/services/notification_service.dart';
import 'package:igit_connects/screens/post/full_post_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:shimmer/shimmer.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  final ScrollController _scrollController = ScrollController();
  final List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 20;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
        _fetchNotifications();
      }
    });
  }

  Future<void> _fetchNotifications() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final newNotifications = await _notificationService.getNotifications(
        offset: _offset,
        limit: _limit,
      );

      setState(() {
        _offset += newNotifications.length;
        _notifications.addAll(newNotifications);
        debugPrint("State update count (Total UI Notifications): ${_notifications.length}");
        if (newNotifications.length < _limit) {
          _hasMore = false;
        }
      });
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    // Mark as read
    if (!notification.isRead) {
      await _notificationService.markAsRead(notification.id);
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = NotificationModel(
            id: notification.id,
            userId: notification.userId,
            type: notification.type,
            title: notification.title,
            body: notification.body,
            isRead: true,
            createdAt: notification.createdAt,
            actorUserId: notification.actorUserId,
            postId: notification.postId,
            commentId: notification.commentId,
            actorName: notification.actorName,
            actorPhotoUrl: notification.actorPhotoUrl,
          );
        }
      });
    }

    // Navigate to post if it exists
    if (notification.postId != null) {
      try {
        final post = await Supabase.instance.client
            .from('posts')
            .select(
              '*, post_likes(user_id), saved_posts(user_id), post_comments(count), users!posts_user_id_fkey(is_verified, subscription_plan, role, faculty_verified, branch, designation, user_type)',
            )
            .eq('id', notification.postId!)
            .single();

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FullPostScreen(post: post)),
          );
        }
      } catch (e) {
        debugPrint("Error fetching post: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post may have been deleted')),
          );
        }
      }
    }
  }

  Widget _buildNotificationItem(
    NotificationModel notification,
    AppColors colors,
  ) {
    IconData iconData;
    Color iconColor;

    switch (notification.type) {
      case 'COMMENT':
        iconData = Icons.comment;
        iconColor = Colors.blue;
        break;
      case 'LIKE_MILESTONE':
        iconData = Icons.favorite;
        iconColor = Colors.red;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = colors.primaryAccent;
    }

    return InkWell(
      onTap: () => _handleNotificationTap(notification),
      child: Container(
        color: notification.isRead
            ? Colors.transparent
            : colors.primaryAccent.withValues(alpha: 0.05),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: colors.borderColor,
              backgroundImage:
                  notification.actorPhotoUrl != null &&
                      notification.actorPhotoUrl!.isNotEmpty
                  ? NetworkImage(notification.actorPhotoUrl!)
                  : null,
              child:
                  notification.actorPhotoUrl == null ||
                      notification.actorPhotoUrl!.isEmpty
                  ? Icon(iconData, color: iconColor)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(color: colors.primaryText, fontSize: 14),
                      children: [
                        if (notification.actorName != null)
                          TextSpan(
                            text: "${notification.actorName} ",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        TextSpan(text: notification.title),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: TextStyle(color: colors.secondaryText, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    timeago.format(notification.createdAt),
                    style: TextStyle(
                      color: colors.secondaryText.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 8),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer(AppColors colors) {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Shimmer.fromColors(
                baseColor: colors.borderColor,
                highlightColor: colors.cardColor,
                child: const CircleAvatar(radius: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Shimmer.fromColors(
                      baseColor: colors.borderColor,
                      highlightColor: colors.cardColor,
                      child: Container(
                        height: 14,
                        width: double.infinity,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Shimmer.fromColors(
                      baseColor: colors.borderColor,
                      highlightColor: colors.cardColor,
                      child: Container(
                        height: 12,
                        width: 150,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.bgColor,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(
            color: colors.primaryText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colors.bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.primaryText),
      ),
      body: _notifications.isEmpty && _isLoading
          ? _buildShimmer(colors)
          : _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: colors.secondaryText.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No notifications yet",
                    style: TextStyle(color: colors.secondaryText, fontSize: 16),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _offset = 0;
                  _notifications.clear();
                  _hasMore = true;
                });
                await _fetchNotifications();
              },
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _notifications.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  debugPrint("Building ListView item index: $index");
                  if (index == _notifications.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return _buildNotificationItem(_notifications[index], colors);
                },
              ),
            ),
    );
  }
}
