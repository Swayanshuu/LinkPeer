import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:igit_connects/core/app_colors.dart';
import 'package:igit_connects/core/user_provider.dart';
import 'package:igit_connects/features/notices/models/notice_publisher_model.dart';
import 'package:igit_connects/features/notices/repository/notice_publisher_repository.dart';

class AdminNoticePublishersScreen extends ConsumerStatefulWidget {
  const AdminNoticePublishersScreen({super.key});

  @override
  ConsumerState<AdminNoticePublishersScreen> createState() =>
      _AdminNoticePublishersScreenState();
}

class _AdminNoticePublishersScreenState
    extends ConsumerState<AdminNoticePublishersScreen> {
  final NoticePublisherRepository _publisherRepository =
      NoticePublisherRepository();
  final TextEditingController _searchController = TextEditingController();

  List<NoticePublisherModel> _publishers = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPublishers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPublishers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _publisherRepository.getAllNoticePublishers();
      if (mounted) {
        setState(() {
          _publishers = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load notice publishers: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _performUserSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final results = await _publisherRepository.searchUsers(query);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  Future<void> _grantPermission(Map<String, dynamic> user) async {
    final adminUser = ref.read(userProvider).asData?.value;
    final adminId = adminUser?['id']?.toString() ?? 'admin';
    final userId = user['id'].toString();

    try {
      await _publisherRepository.grantPublishPermission(
        targetUserId: userId,
        createdBy: adminId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Notice publisher permission granted to ${user['name']}',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _searchController.clear();
        setState(() {
          _searchResults = [];
        });
        _loadPublishers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to grant permission: $e')),
        );
      }
    }
  }

  Future<void> _toggleStatus(NoticePublisherModel publisher) async {
    try {
      if (publisher.isActive) {
        await _publisherRepository.revokePublishPermission(publisher.userId);
      } else {
        final adminUser = ref.read(userProvider).asData?.value;
        final adminId = adminUser?['id']?.toString() ?? 'admin';
        await _publisherRepository.grantPublishPermission(
          targetUserId: publisher.userId,
          createdBy: adminId,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              publisher.isActive
                  ? 'Permission revoked for ${publisher.userName ?? 'User'}'
                  : 'Permission re-enabled for ${publisher.userName ?? 'User'}',
            ),
          ),
        );
        _loadPublishers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Action failed: $e')));
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
          'Notice Publisher Management',
          style: TextStyle(
            color: colors.primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: colors.primaryText),
      ),
      body: Column(
        children: [
          // User Search Section
          Container(
            padding: const EdgeInsets.all(16),
            color: colors.cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Search LinkPeer User by Email or Name',
                  style: TextStyle(
                    color: colors.primaryText,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchController,
                  onChanged: (val) => _performUserSearch(val),
                  style: TextStyle(color: colors.primaryText),
                  decoration: InputDecoration(
                    hintText: 'Enter user email (e.g. swayanshu19@gmail.com)',
                    hintStyle: TextStyle(
                      color: colors.secondaryText,
                      fontSize: 13,
                    ),
                    prefixIcon: Icon(Icons.search, color: colors.secondaryText),
                    suffixIcon: _isSearching
                        ? Transform.scale(
                            scale: 0.5,
                            child: CircularProgressIndicator(
                              color: colors.primaryAccent,
                            ),
                          )
                        : _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: colors.secondaryText,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchResults = [];
                              });
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

                // Search Results Dropdown List
                if (_searchResults.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 220),
                    decoration: BoxDecoration(
                      color: colors.bgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.borderColor),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final user = _searchResults[index];
                        final userEmail = user['email'] ?? 'No email';
                        final userName = user['name'] ?? 'User';
                        final photoUrl = user['photo_url'];

                        final isAlreadyPublisher = _publishers.any(
                          (p) =>
                              p.userId == user['id'].toString() && p.isActive,
                        );

                        return ListTile(
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: colors.borderColor,
                            backgroundImage:
                                photoUrl != null && photoUrl.isNotEmpty
                                ? NetworkImage(photoUrl)
                                : null,
                            child: photoUrl == null || photoUrl.isEmpty
                                ? Icon(
                                    Icons.person,
                                    size: 16,
                                    color: colors.primaryAccent,
                                  )
                                : null,
                          ),
                          title: Text(
                            userName,
                            style: TextStyle(
                              color: colors.primaryText,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text(
                            userEmail,
                            style: TextStyle(
                              color: colors.secondaryText,
                              fontSize: 11,
                            ),
                          ),
                          trailing: isAlreadyPublisher
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Authorized',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : ElevatedButton(
                                  onPressed: () => _grantPermission(user),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colors.primaryAccent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Grant Permission',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),

          // Title for Publishers List
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Authorized Notice Publishers',
                  style: TextStyle(
                    color: colors.primaryText,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.borderColor),
                  ),
                  child: Text(
                    'Total: ${_publishers.length}',
                    style: TextStyle(
                      color: colors.secondaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Active Publishers List
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: colors.primaryAccent,
                    ),
                  )
                : _errorMessage != null
                ? Center(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: colors.primaryText),
                    ),
                  )
                : _publishers.isEmpty
                ? Center(
                    child: Text(
                      'No notice publishers found.\nSearch above to grant permissions.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.secondaryText),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadPublishers,
                    color: colors.primaryAccent,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: _publishers.length,
                      itemBuilder: (context, index) {
                        final pub = _publishers[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colors.cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: colors.borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: colors.borderColor,
                                    backgroundImage:
                                        pub.userPhotoUrl != null &&
                                            pub.userPhotoUrl!.isNotEmpty
                                        ? NetworkImage(pub.userPhotoUrl!)
                                        : null,
                                    child:
                                        pub.userPhotoUrl == null ||
                                            pub.userPhotoUrl!.isEmpty
                                        ? Icon(
                                            Icons.person,
                                            color: colors.primaryAccent,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          pub.userName ??
                                              'User (${pub.userId.substring(0, 8)})',
                                          style: TextStyle(
                                            color: colors.primaryText,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        if (pub.userEmail != null)
                                          Text(
                                            pub.userEmail!,
                                            style: TextStyle(
                                              color: colors.secondaryText,
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: pub.isActive
                                          ? Colors.green.withValues(alpha: 0.1)
                                          : Colors.grey.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      pub.isActive ? 'Active' : 'Disabled',
                                      style: TextStyle(
                                        color: pub.isActive
                                            ? Colors.green
                                            : Colors.grey,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Granted: ${pub.createdAt.toString().split(' ').first}',
                                    style: TextStyle(
                                      color: colors.secondaryText,
                                      fontSize: 11,
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => _toggleStatus(pub),
                                    icon: Icon(
                                      pub.isActive
                                          ? Icons.block
                                          : Icons.check_circle,
                                      size: 16,
                                      color: pub.isActive
                                          ? Colors.redAccent
                                          : Colors.green,
                                    ),
                                    label: Text(
                                      pub.isActive ? 'Revoke' : 'Enable',
                                      style: TextStyle(
                                        color: pub.isActive
                                            ? Colors.redAccent
                                            : Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
