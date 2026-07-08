import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:igit_connects/core/app_colors.dart';
import 'package:igit_connects/screens/profile/components/profile_header_sliver.dart';
import 'package:igit_connects/screens/profile/components/profile_post_section.dart';
import 'package:igit_connects/core/post_provider.dart';

class OtherUserProfileScreen extends ConsumerStatefulWidget {
  final String userId;

  const OtherUserProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<OtherUserProfileScreen> createState() =>
      _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState
    extends ConsumerState<OtherUserProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final response = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', widget.userId)
          .single();
      setState(() {
        _userData = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final posts = ref.watch(postsProvider);

    return Scaffold(
      backgroundColor: colors.bgColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null || _userData == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Failed to load user profile.",
                    style: TextStyle(color: colors.primaryText),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Go Back"),
                  ),
                ],
              ),
            )
          : DefaultTabController(
              length: 2,
              child: RefreshIndicator(
                onRefresh: () async {
                  await _fetchUserData();
                  ref.invalidate(postsProvider);
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                color: colors.primaryText,
                backgroundColor: colors.cardColor,
                child: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      ProfileHeaderSliver(
                        data: _userData!,
                        posts: posts,
                        ref: ref,
                        isOtherUser: true,
                        bottom: _SolidTabBar(
                          TabBar(
                            indicatorColor: colors.primaryAccent,
                            labelColor: colors.primaryAccent,
                            unselectedLabelColor: colors.secondaryText,
                            labelStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            unselectedLabelStyle: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            dividerColor: colors.borderColor.withValues(
                              alpha: 0.5,
                            ),
                            tabs: const [
                              Tab(
                                icon: Icon(Icons.list_alt_rounded, size: 20),
                                text: "Posts",
                              ),
                              Tab(
                                icon: Icon(Icons.show_chart_rounded, size: 20),
                                text: "Activity",
                              ),
                            ],
                          ),
                          colors.bgColor,
                        ),
                      ),
                    ];
                  },
                  body: TabBarView(
                    children: [
                      CustomScrollView(
                        key: PageStorageKey<String>(
                          'posts_tab_${widget.userId}',
                        ),
                        slivers: [
                          ProfilePostsSection(
                            data: _userData!,
                            posts: posts,
                            ref: ref,
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 90)),
                        ],
                      ),
                      Center(
                        child: Text(
                          "Activity - Coming Soon",
                          style: TextStyle(color: colors.secondaryText),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _SolidTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabBar tabBar;
  final Color color;

  const _SolidTabBar(this.tabBar, this.color);

  @override
  Size get preferredSize => tabBar.preferredSize;

  @override
  Widget build(BuildContext context) {
    return Container(color: color, child: tabBar);
  }
}
