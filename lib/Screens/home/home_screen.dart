import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:igit_connects/shared_components/banner_ad_widget.dart';
import 'package:igit_connects/screens/post/full_post_screen.dart';
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
          ? FloatingActionButton(
              onPressed: scrollToTop,

              backgroundColor: colors.primaryText,

              foregroundColor: isDark ? Colors.black : Colors.white,

              child: const Icon(Icons.keyboard_arrow_up_rounded, size: 30),
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
              return await ref.refresh(postsProvider.future);
            },
            color: isDark ? Colors.black : Colors.white,
            backgroundColor: colors.primaryText,

            strokeWidth: 2.8,

            displacement: 70,

            edgeOffset: 8,

            child: SingleChildScrollView(
              controller: scrollController,

              physics: const AlwaysScrollableScrollPhysics(),

              padding: const EdgeInsets.all(14),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  HomeHeader(me: me),

                  const SizedBox(height: 20),

                  FeedFilterBar(
                    selected: selected,

                    onChanged: (value) {
                      setState(() {
                        selected = value;
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  Text(
                    "Latest Posts",
                    style: TextStyle(
                      color: colors.primaryText,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 14),

                  posts.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),

                    error: (e, s) => Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text(
                        "Error loading posts",
                        style: TextStyle(color: colors.primaryText),
                      ),
                    ),

                    data: (list) {
                      final filtered = selected == "all"
                          ? list
                          : list
                                .where(
                                  (p) =>
                                      p["post_type"].toString().toLowerCase() ==
                                      selected,
                                )
                                .toList();

                      if (filtered.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 30),
                          child: Center(
                            child: Text(
                              "No posts found",
                              style: TextStyle(color: colors.secondaryText),
                            ),
                          ),
                        );
                      }

                      final adPositions = generateAdPositions(filtered.length);

                      final feedItems = [];

                      for (int i = 0; i < filtered.length; i++) {
                        feedItems.add(filtered[i]);

                        if (adPositions.contains(i + 1)) {
                          feedItems.add("__AD__");
                        }
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),

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
                      );
                    },
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
