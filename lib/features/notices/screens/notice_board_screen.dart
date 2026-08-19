import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:igit_connects/core/app_colors.dart';
import 'package:igit_connects/core/user_provider.dart';
import 'package:igit_connects/features/notices/config/notice_config.dart';
import 'package:igit_connects/features/notices/models/notice_model.dart';
import 'package:igit_connects/features/notices/repository/notice_publisher_repository.dart';
import 'package:igit_connects/features/notices/screens/create_notice_screen.dart';
import 'package:igit_connects/features/notices/screens/edit_notice_screen.dart';
import 'package:igit_connects/features/notices/screens/notice_details_screen.dart';
import 'package:igit_connects/features/notices/services/notice_service.dart';
import 'package:igit_connects/shared_components/custom_app_bar.dart';
import 'package:igit_connects/shared_components/custom_snackbar.dart';
import 'package:igit_connects/shared_components/custom_state_widgets.dart';
import 'package:igit_connects/shared_components/hashtag_text.dart';

class NoticeBoardScreen extends ConsumerStatefulWidget {
  const NoticeBoardScreen({super.key});

  @override
  ConsumerState<NoticeBoardScreen> createState() => _NoticeBoardScreenState();
}

class _NoticeBoardScreenState extends ConsumerState<NoticeBoardScreen> {
  final NoticeService _noticeService = NoticeService();
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'All';
  List<NoticeModel> _notices = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchNotices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchNotices() async {
    ref.invalidate(isNoticePublisherProvider);

    final category = _selectedCategory;
    final searchQuery = _searchController.text.trim();
    final isDefault = searchQuery.isEmpty;

    // 1. Step 1: Instant Local Cache Load (0ms wait UI display)
    if (isDefault) {
      final cachedList = await _noticeService.getCachedNotices(category: category);
      if (cachedList.isNotEmpty && mounted && _selectedCategory == category) {
        setState(() {
          _notices = cachedList;
          _isLoading = false;
          _errorMessage = null;
        });
      } else if (_notices.isEmpty) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }
    } else {
      if (_notices.isEmpty) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }
    }

    // 2. Step 2: Background Network Sync (Supabase Revalidation)
    try {
      final freshList = await _noticeService.getNotices(
        category: category,
        searchQuery: searchQuery,
      );
      if (mounted && _selectedCategory == category) {
        setState(() {
          _notices = freshList;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted && _selectedCategory == category) {
        // If we already rendered cached data, maintain cache instead of throwing full-screen error
        if (_notices.isEmpty) {
          setState(() {
            _errorMessage = 'Failed to load notices: $e';
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _onCategorySelected(String category) {
    if (_selectedCategory == category) return;
    setState(() {
      _selectedCategory = category;
    });
    _fetchNotices();
  }

  Future<void> _deleteNoticeCard(NoticeModel notice) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final colors = AppColors.of(ctx);
        return AlertDialog(
          backgroundColor: colors.cardColor,
          title: Text(
            'Delete Notice',
            style: TextStyle(color: colors.primaryText),
          ),
          content: Text(
            'Are you sure you want to delete "${notice.title}" and its storage attachments?',
            style: TextStyle(color: colors.secondaryText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Cancel',
                style: TextStyle(color: colors.secondaryText),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

      if (confirm == true) {
        try {
          await _noticeService.deleteNotice(notice.id);
          if (mounted) {
            // Remove the deleted notice locally for instant UI update
            setState(() {
              _notices.removeWhere((n) => n.id == notice.id);
            });
            CustomSnackBar.show(context, message: 'Notice deleted successfully.');
          }
        } catch (e) {
          if (mounted) {
            CustomSnackBar.show(
              context,
              message: 'Failed to delete notice: $e',
              isError: true,
            );
          }
        }
      }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isPublisherAsync = ref.watch(isNoticePublisherProvider);
    final canPublish =
        isPublisherAsync.value ?? (FirebaseAuth.instance.currentUser != null);

    return Scaffold(
      backgroundColor: colors.bgColor,
      appBar: CustomAppBar(
        title: 'Notice Board',
        // titleWidget: Column(
        //   crossAxisAlignment: CrossAxisAlignment.start,
        //   mainAxisSize: MainAxisSize.min,
        //   children: [
        //     Text(
        //       'College Notice Board',
        //       style: TextStyle(
        //         color: colors.primaryText,
        //         fontSize: 18,
        //         fontWeight: FontWeight.bold,
        //       ),
        //     ),
        //     Text(
        //       'Official Campus Announcements',
        //       style: TextStyle(color: colors.secondaryText, fontSize: 11),
        //     ),
        //   ],
        // ),
        actions: [
          if (canPublish)
            Padding(
              padding: const EdgeInsets.only(right: 4.0),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primaryAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () async {
                  final created = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateNoticeScreen(),
                    ),
                  );
                  if (created == true) {
                    _fetchNotices();
                  }
                },
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                label: const Text(
                  'Notice',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          IconButton(
            icon: Icon(Icons.refresh, color: colors.primaryText),
            onPressed: _fetchNotices,
            tooltip: 'Refresh Notices',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            color: colors.cardColor,
            child: Column(
              children: [
                // Search Bar Input
                TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _fetchNotices(),
                  style: TextStyle(color: colors.primaryText),
                  decoration: InputDecoration(
                    hintText: 'Search notices by title or keyword...',
                    hintStyle: TextStyle(
                      color: colors.secondaryText,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(Icons.search, color: colors.secondaryText),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: colors.secondaryText,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _fetchNotices();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: colors.bgColor,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.primaryAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Category Filter Chips Horizontal List
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: NoticeConfig.categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final category = NoticeConfig.categories[index];
                      final isSelected = _selectedCategory == category;

                      return ChoiceChip(
                        label: Text(
                          category,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : colors.primaryText,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: colors.primaryAccent,
                        backgroundColor: colors.bgColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? colors.primaryAccent
                                : colors.borderColor,
                          ),
                        ),
                        onSelected: (_) => _onCategorySelected(category),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Notices Feed List
          Expanded(
            child: _isLoading
                ? const CustomLoadingWidget(
                    message: 'Fetching official notices...',
                  )
                : _errorMessage != null
                ? CustomErrorState(
                    message: _errorMessage!,
                    onRetry: _fetchNotices,
                  )
                : _notices.isEmpty
                ? CustomEmptyState(
                    icon: Icons.assignment_outlined,
                    title: 'No Notices Found',
                    subtitle:
                        'Check back later for official college announcements.',
                    actionLabel: 'Refresh Feed',
                    onActionPressed: _fetchNotices,
                  )
                : RefreshIndicator(
                    onRefresh: _fetchNotices,
                    color: colors.primaryAccent,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      itemCount: _notices.length,
                      itemBuilder: (context, index) {
                        return _buildNoticeCard(_notices[index], colors);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeCard(NoticeModel notice, AppColors colors) {
    final authUid = FirebaseAuth.instance.currentUser?.uid.trim().toLowerCase();
    final userAsync = ref.watch(userProvider);
    final currentUser = userAsync.value;
    final userId = currentUser?['id']?.toString().trim().toLowerCase();
    final pubId = notice.publisherId.trim().toLowerCase();

    final isAuthor =
        (authUid != null && authUid == pubId) ||
        (userId != null && userId == pubId);

    final isAdmin =
        currentUser != null &&
        (currentUser['role']?.toString().toLowerCase() == 'admin' ||
            currentUser['user_type']?.toString().toLowerCase() == 'admin');

    final isAuthorOrAdmin = isAuthor || isAdmin;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: colors.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: notice.isImportant
              ? Colors.redAccent.withValues(alpha: 0.6)
              : colors.borderColor,
          width: notice.isImportant ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            final updated = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => NoticeDetailsScreen(noticeId: notice.id),
              ),
            );
            if (updated == true) {
              _fetchNotices();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Category Pill, Urgent Badge & Edit/Delete Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primaryAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            notice.category.toUpperCase(),
                            style: TextStyle(
                              color: colors.primaryAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        if (notice.isImportant) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.priority_high,
                                  size: 13,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 2),
                                Text(
                                  'IMPORTANT',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),

                    if (isAuthorOrAdmin)
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: colors.secondaryText,
                          size: 20,
                        ),
                        color: colors.cardColor,
                        onSelected: (val) async {
                          if (val == 'edit') {
                            final updated = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    EditNoticeScreen(notice: notice),
                              ),
                            );
                            if (updated == true) {
                              _fetchNotices();
                            }
                          } else if (val == 'delete') {
                            _deleteNoticeCard(notice);
                          }
                        },
                        itemBuilder: (ctx) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit_outlined,
                                  color: colors.primaryAccent,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Edit Notice',
                                  style: TextStyle(color: colors.primaryText),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Delete Notice',
                                  style: TextStyle(color: Colors.redAccent),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Title
                Text(
                  notice.title,
                  style: TextStyle(
                    color: colors.primaryText,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Description Preview
                HashtagText(
                  text: notice.content,
                  fontSize: 14,
                  style: TextStyle(
                    color: colors.secondaryText,
                    fontSize: 14,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),

                const Divider(height: 1),
                const SizedBox(height: 10),

                // Bottom Metadata Row: Publisher & Date
                Row(
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: colors.borderColor,
                      backgroundImage:
                          notice.publisherPhotoUrl != null &&
                              notice.publisherPhotoUrl!.isNotEmpty
                          ? NetworkImage(notice.publisherPhotoUrl!)
                          : null,
                      child:
                          notice.publisherPhotoUrl == null ||
                              notice.publisherPhotoUrl!.isEmpty
                          ? Icon(
                              Icons.school,
                              size: 15,
                              color: colors.primaryAccent,
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notice.publisherName ?? 'College Administration',
                            style: TextStyle(
                              color: colors.primaryText,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            [
                                  if (notice.publisherDesignation != null &&
                                      notice.publisherDesignation!.isNotEmpty)
                                    notice.publisherDesignation,
                                  if (notice.publisherBranch != null &&
                                      notice.publisherBranch!.isNotEmpty)
                                    notice.publisherBranch
                                  else if (notice.publisherDepartment != null &&
                                      notice.publisherDepartment!.isNotEmpty)
                                    notice.publisherDepartment,
                                  if (notice.publisherUserType != null &&
                                      notice.publisherUserType!.isNotEmpty)
                                    notice.publisherUserType!.toUpperCase(),
                                ]
                                .where(
                                  (e) => e != null && e.toString().isNotEmpty,
                                )
                                .join(' • '),
                            style: TextStyle(
                              color: colors.secondaryText,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      notice.formattedDate,
                      style: TextStyle(
                        color: colors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                    if (notice.attachments.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.bgColor,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: colors.borderColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.attach_file,
                              size: 14,
                              color: colors.secondaryText,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${notice.attachments.length}',
                              style: TextStyle(
                                color: colors.secondaryText,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
