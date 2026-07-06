import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:igit_connects/core/app_colors.dart';
import 'package:igit_connects/screens/home/components/post_card.dart';
import 'package:igit_connects/core/post_provider.dart';

class Searchscreen extends ConsumerStatefulWidget {
  const Searchscreen({super.key});

  @override
  ConsumerState<Searchscreen> createState() => _SearchscreenState();
}

class _SearchscreenState extends ConsumerState<Searchscreen> {
  final TextEditingController searchController = TextEditingController();

  String query = "";

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final posts = ref.watch(postsProvider);

    return Scaffold(
      backgroundColor: colors.bgColor,

      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),

              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 14),

                      decoration: BoxDecoration(
                        color: colors.cardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: colors.borderColor),
                      ),

                      child: Row(
                        children: [
                          Icon(
                            Icons.search,
                            color: colors.secondaryText,
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: TextField(
                              controller: searchController,

                              autofocus: true,

                              style: TextStyle(
                                color: colors.primaryText,
                              ),

                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: "Search name, title, content...",
                                hintStyle: TextStyle(
                                  color: colors.secondaryText,
                                ),
                              ),

                              onChanged: (value) {
                                setState(() {
                                  query = value.trim().toLowerCase();
                                });
                              },
                            ),
                          ),

                          if (query.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                searchController.clear();

                                setState(() {
                                  query = "";
                                });
                              },

                              child: Icon(
                                Icons.close,
                                color: colors.secondaryText,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  GestureDetector(
                    onTap: () {
                      searchController.clear();

                      setState(() {
                        query = "";
                      });
                    },

                    child: Container(
                      height: 44,
                      width: 44,

                      decoration: BoxDecoration(
                        color: colors.cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colors.borderColor),
                      ),

                      child: Icon(
                        Icons.close_rounded,
                        color: colors.primaryText,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// RESULTS
            Expanded(
              child: posts.when(
                loading: () => const Center(child: CircularProgressIndicator()),

                error: (e, s) => Center(
                  child: Text(
                    "Failed to load",
                    style: TextStyle(color: colors.primaryText),
                  ),
                ),

                data: (list) {
                  final filtered = query.isEmpty
                      ? []
                      : list.where((post) {
                          final name = (post["user_name"] ?? "")
                              .toString()
                              .toLowerCase();

                          final title = (post["title"] ?? "")
                              .toString()
                              .toLowerCase();

                          final content = (post["content"] ?? "")
                              .toString()
                              .toLowerCase();

                          return name.contains(query) ||
                              title.contains(query) ||
                              content.contains(query);
                        }).toList();

                  if (query.isEmpty) {
                    return Center(
                      child: Text(
                        "Search posts by user, title or content",
                        style: TextStyle(color: colors.secondaryText),
                      ),
                    );
                  }

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        "No results found",
                        style: TextStyle(color: colors.secondaryText),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 6, 14, 20),

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
            ),
          ],
        ),
      ),
    );
  }
}
