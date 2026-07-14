import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:igit_connects/core/app_colors.dart';
import 'package:igit_connects/core/models/notification_model.dart';
import 'package:igit_connects/core/notification_provider.dart';
import 'package:igit_connects/screens/post/full_post_screen.dart';
import 'package:igit_connects/features/broadcast/screens/broadcast_tab.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:shimmer/shimmer.dart';
import 'package:igit_connects/shared_components/banner_ad_widget.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  final int initialIndex;
  const NotificationScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(notificationProvider.notifier).loadMore();
      }
    });
  }

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    // Optimistically mark as read in the provider
    if (!notification.isRead) {
      await ref.read(notificationProvider.notifier).markAsRead(notification);
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
    final notificationState = ref.watch(notificationProvider);
    // final isPaginating = notificationState.isLoading && notificationState.hasValue;

    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialIndex,
      child: Scaffold(
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
          bottom: TabBar(
            labelColor: colors.primaryAccent,
            unselectedLabelColor: colors.secondaryText,
            indicatorColor: colors.primaryAccent,
            tabs: const [
              Tab(text: "Notifications"),
              Tab(text: "Broadcasts"),
            ],
          ),
        ),
        body: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: BannerAdWidget(),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  notificationState.when(
                    loading: () => _buildShimmer(colors),
                    error: (error, stack) => Center(
                      child: Text(
                        "Error loading notifications",
                        style: TextStyle(color: colors.secondaryText),
                      ),
                    ),
                    data: (notifications) {
                      if (notifications.isEmpty) {
                        return RefreshIndicator(
                          onRefresh: () async {
                            return ref
                                .read(notificationProvider.notifier)
                                .forceRefresh();
                          },
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height * 0.6,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.notifications_off_outlined,
                                      size: 64,
                                      color: colors.secondaryText.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      "No notifications yet",
                                      style: TextStyle(
                                        color: colors.secondaryText,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          return ref
                              .read(notificationProvider.notifier)
                              .forceRefresh();
                        },
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount:
                              notifications.length +
                              (ref.read(notificationProvider.notifier).hasMore
                                  ? 1
                                  : 0),
                          itemBuilder: (context, index) {
                            if (index == notifications.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            return _buildNotificationItem(
                              notifications[index],
                              colors,
                            );
                          },
                        ),
                      );
                    },
                  ),
                  const BroadcastTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
