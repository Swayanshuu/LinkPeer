import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:igit_connects/Screens/Post/full_post_screen.dart';
import 'package:igit_connects/shared_components/banner_ad_widget.dart';
import 'package:igit_connects/utils/ad_position.dart';
import 'package:igit_connects/shared_components/app_drawer.dart';

import 'package:igit_connects/core/app_colors.dart';
import 'package:igit_connects/screens/home/components/feed_filter_bar.dart';
import 'package:igit_connects/screens/home/components/home_header.dart';
import 'package:igit_connects/screens/home/components/post_card.dart';
import 'package:igit_connects/core/post_provider.dart';
import 'package:igit_connects/core/user_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String selected = "all";

  final ScrollController scrollController = ScrollController();

  bool showFab = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollController.addListener(_scrollListener);
    });
  }

  void _scrollListener() {
    if (!scrollController.hasClients) {
      return;
    }

    final shouldShow = scrollController.offset > 250;

    if (shouldShow != showFab) {
      setState(() {
        showFab = shouldShow;
      });
    }
  }

  void scrollToTop() {
    scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    scrollController.removeListener(_scrollListener);

    scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(userProvider);

    final posts = ref.watch(postsProvider);

    return Scaffold(
      backgroundColor: colors.bgColor,
      drawer: const AppDrawer(),
      floatingActionButton: showFab
          ? Padding(
              padding: const EdgeInsets.only(
                bottom: 100.0,
              ), // Push above the parent's BottomAppBar
              child: FloatingActionButton(
                onPressed: scrollToTop,
                backgroundColor: colors.primaryAccent,
                foregroundColor: colors.onPrimaryAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 4,
                child: const Icon(Icons.keyboard_arrow_up_rounded, size: 30),
              ),
            )
          : null,

      body: SafeArea(
        child: user.when(
          loading: () => const Center(child: CircularProgressIndicator()),

          error: (e, s) => Center(
            child: Text("Error", style: TextStyle(color: colors.primaryText)),
          ),

          data: (me) => RefreshIndicator(
            onRefresh: () async {
              return ref.refresh(postsProvider.future);
            },
            color: isDark ? Colors.black : Colors.white,
            backgroundColor: colors.primaryText,

            strokeWidth: 2.8,

            displacement: 70,

            edgeOffset: 8,

            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: CustomScrollView(
                  controller: scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                      sliver: SliverToBoxAdapter(child: HomeHeader(me: me)),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _StickyFilterDelegate(
                        backgroundColor: colors.bgColor,
                        child: FeedFilterBar(
                          selected: selected,
                          onChanged: (value) {
                            setState(() {
                              selected = value;
                            });
                          },
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          "Latest Posts",
                          style: TextStyle(
                            color: colors.primaryText,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    posts.when(
                      loading: () => const SliverToBoxAdapter(
                        child: Center(child: CircularProgressIndicator()),
                      ),

                      error: (e, s) => SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Center(
                            child: Text(
                              "Error loading posts: $e",
                              style: TextStyle(color: colors.primaryText),
                            ),
                          ),
                        ),
                      ),

                      data: (list) {
                        final filtered = selected == "all"
                            ? list
                            : list
                                  .where(
                                    (p) =>
                                        p["post_type"]
                                            .toString()
                                            .toLowerCase() ==
                                        selected,
                                  )
                                  .toList();

                        if (filtered.isEmpty) {
                          return SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: 30,
                                bottom: 100,
                              ),
                              child: Center(
                                child: Text(
                                  "No posts found",
                                  style: TextStyle(color: colors.secondaryText),
                                ),
                              ),
                            ),
                          );
                        }

                        final adPositions = generateAdPositions(
                          filtered.length,
                        );

                        final feedItems = [];

                        for (int i = 0; i < filtered.length; i++) {
                          feedItems.add(filtered[i]);

                          if (adPositions.contains(i + 1)) {
                            feedItems.add("__AD__");
                          }
                        }

                        return SliverPadding(
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            bottom: 100,
                          ),
                          sliver: SliverList.builder(
                            itemCount: feedItems.length,
                            itemBuilder: (context, index) {
                              final item = feedItems[index];

                              if (item == "__AD__") {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: BannerAdWidget(),
                                );
                              }

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          FullPostScreen(post: item),
                                    ),
                                  );
                                },
                                child: PostCard(
                                  post: item,
                                  onRefresh: () {
                                    ref.invalidate(postsProvider);
                                  },
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StickyFilterDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final Color backgroundColor;

  _StickyFilterDelegate({required this.child, required this.backgroundColor});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: backgroundColor,
      alignment: Alignment.center,
      child: child,
    );
  }

  @override
  double get maxExtent => 52.0; // Height of the FeedFilterBar

  @override
  double get minExtent => 52.0;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
