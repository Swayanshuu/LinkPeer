import 'package:flutter/material.dart';
import 'package:igit_connects/core/app_colors.dart';
import 'package:igit_connects/features/notices/config/notice_config.dart';
import 'package:igit_connects/features/notices/models/notice_model.dart';
import 'package:igit_connects/features/notices/screens/notice_details_screen.dart';
import 'package:igit_connects/features/notices/services/notice_service.dart';

class AdminNoticeManagementScreen extends StatefulWidget {
  const AdminNoticeManagementScreen({super.key});

  @override
  State<AdminNoticeManagementScreen> createState() =>
      _AdminNoticeManagementScreenState();
}

class _AdminNoticeManagementScreenState
    extends State<AdminNoticeManagementScreen> {
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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _noticeService.getNotices(
        category: _selectedCategory,
        searchQuery: _searchController.text.trim(),
        limit: 50,
      );
      if (mounted) {
        setState(() {
          _notices = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load notices: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleImportant(NoticeModel notice) async {
    try {
      await _noticeService.updateNotice(
        noticeId: notice.id,
        title: notice.title,
        content: notice.content,
        category: notice.category,
        isImportant: !notice.isImportant,
        externalUrl: notice.externalUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              notice.isImportant
                  ? 'Marked notice as normal'
                  : 'Marked notice as IMPORTANT',
            ),
          ),
        );
        _fetchNotices();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update notice: $e')),
        );
      }
    }
  }

  Future<void> _deleteNotice(NoticeModel notice) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final colors = AppColors.of(ctx);
        return AlertDialog(
          backgroundColor: colors.cardColor,
          title: Text('Delete Notice', style: TextStyle(color: colors.primaryText)),
          content: Text(
            'Are you sure you want to delete notice "${notice.title}" and its attachments?',
            style: TextStyle(color: colors.secondaryText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: TextStyle(color: colors.secondaryText)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _noticeService.deleteNotice(notice.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notice deleted successfully.')),
          );
          _fetchNotices();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete notice: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.bgColor,
      appBar: AppBar(
        backgroundColor: colors.cardColor,
        elevation: 0.5,
        title: Text(
          'Notice Management',
          style: TextStyle(
            color: colors.primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: colors.primaryText),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: colors.primaryText),
            onPressed: _fetchNotices,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter & Search Header
          Container(
            padding: const EdgeInsets.all(12),
            color: colors.cardColor,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _fetchNotices(),
                  style: TextStyle(color: colors.primaryText),
                  decoration: InputDecoration(
                    hintText: 'Search all notices...',
                    hintStyle: TextStyle(color: colors.secondaryText, fontSize: 13),
                    prefixIcon: Icon(Icons.search, color: colors.secondaryText),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: colors.secondaryText),
                            onPressed: () {
                              _searchController.clear();
                              _fetchNotices();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: colors.bgColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.borderColor),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: NoticeConfig.categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final category = NoticeConfig.categories[index];
                      final isSelected = _selectedCategory == category;
                      return ChoiceChip(
                        label: Text(
                          category,
                          style: TextStyle(
                            color: isSelected ? Colors.white : colors.primaryText,
                            fontSize: 12,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: colors.primaryAccent,
                        backgroundColor: colors.bgColor,
                        onSelected: (_) {
                          if (_selectedCategory == category) return;
                          setState(() {
                            _selectedCategory = category;
                          });
                          _fetchNotices();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Notices List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: colors.primaryAccent))
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!, style: TextStyle(color: colors.primaryText)))
                    : _notices.isEmpty
                        ? Center(
                            child: Text(
                              'No notices found',
                              style: TextStyle(color: colors.secondaryText),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchNotices,
                            color: colors.primaryAccent,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _notices.length,
                              itemBuilder: (context, index) {
                                final notice = _notices[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: colors.cardColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: notice.isImportant
                                          ? Colors.redAccent
                                          : colors.borderColor,
                                    ),
                                  ),
                                  child: ListTile(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              NoticeDetailsScreen(noticeId: notice.id),
                                        ),
                                      );
                                    },
                                    title: Text(
                                      notice.title,
                                      style: TextStyle(
                                        color: colors.primaryText,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          'Category: ${notice.category} • ${notice.publisherName}',
                                          style: TextStyle(
                                            color: colors.secondaryText,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          '${notice.formattedDateTime} • ${notice.attachments.length} attachments',
                                          style: TextStyle(
                                            color: colors.secondaryText,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            notice.isImportant
                                                ? Icons.priority_high
                                                : Icons.low_priority,
                                            color: notice.isImportant
                                                ? Colors.redAccent
                                                : colors.secondaryText,
                                          ),
                                          onPressed: () => _toggleImportant(notice),
                                          tooltip: notice.isImportant
                                              ? 'Unmark Important'
                                              : 'Mark Important',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline,
                                              color: Colors.redAccent),
                                          onPressed: () => _deleteNotice(notice),
                                          tooltip: 'Delete Notice',
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
