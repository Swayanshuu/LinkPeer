import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../Component/AppColour.dart';
import '../Component/Home/FeedFilterBar.dart';
import '../Component/Home/HomeHeader.dart';
import '../Component/Home/PostCard.dart';
import '../Controllers/PostProvider.dart';
import '../Controllers/UserProvider.dart';

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
    final user = ref.watch(userProvider);

    final posts = ref.watch(postsProvider);

    return Scaffold(
      backgroundColor: AppColours.bgColor,

      floatingActionButton: showFab
          ? FloatingActionButton(
              onPressed: scrollToTop,

              backgroundColor: AppColours.primaryText,

              foregroundColor: Colors.black,

              child: const Icon(Icons.keyboard_arrow_up_rounded, size: 30),
            )
          : null,

      body: SafeArea(
        child: user.when(
          loading: () => const Center(child: CircularProgressIndicator()),

          error: (e, s) => const Center(
            child: Text("Error", style: TextStyle(color: Colors.white)),
          ),

          data: (me) => RefreshIndicator(

            onRefresh: () async {
              ref.refresh(postsProvider);
            },
            color: Colors.black,
            backgroundColor:
            AppColours.primaryText,

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

                  const Text(
                    "Latest Posts",
                    style: TextStyle(
                      color: AppColours.primaryText,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 14),

                  posts.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),

                    error: (e, s) => const Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Text(
                        "Error loading posts",
                        style: TextStyle(color: Colors.white),
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
                        return const Padding(
                          padding: EdgeInsets.only(top: 30),
                          child: Center(
                            child: Text(
                              "No posts found",
                              style: TextStyle(color: AppColours.secondaryText),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,

                        physics: const NeverScrollableScrollPhysics(),

                        itemCount: filtered.length,

                        itemBuilder: (context, index) {
                          return PostCard(
                            post: filtered[index],

                            onRefresh: () {
                              ref.invalidate(postsProvider);
                            },
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
