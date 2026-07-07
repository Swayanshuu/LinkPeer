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
            // Premium Search Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              decoration: BoxDecoration(
                color: colors.bgColor,
                border: Border(bottom: BorderSide(color: colors.borderColor.withValues(alpha: 0.5))),
              ),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: colors.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: TextField(
                  controller: searchController,
                  style: TextStyle(color: colors.primaryText, fontSize: 16),
                  onChanged: (value) {
                    setState(() {
                      query = value.trim().toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Search posts, topics, or people...",
                    hintStyle: TextStyle(color: colors.secondaryText, fontSize: 15),
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search_rounded, color: colors.secondaryText, size: 22),
                    suffixIcon: query.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              searchController.clear();
                              setState(() {
                                query = "";
                              });
                            },
                            child: Icon(Icons.close_rounded, color: colors.primaryText, size: 20),
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            // Results Area
            Expanded(
              child: posts.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(
                  child: Text(
                    "Failed to load posts",
                    style: TextStyle(color: colors.primaryText),
                  ),
                ),
                data: (list) {
                  if (query.isEmpty) {
                    return _buildEmptyState(colors, Icons.search_rounded, "Explore", "Start typing to search posts, announcements, and more.");
                  }

                  final filtered = list.where((post) {
                    final name = (post["user_name"] ?? "").toString().toLowerCase();
                    final title = (post["title"] ?? "").toString().toLowerCase();
                    final content = (post["content"] ?? "").toString().toLowerCase();
                    return name.contains(query) || title.contains(query) || content.contains(query);
                  }).toList();

                  if (filtered.isEmpty) {
                    return _buildEmptyState(colors, Icons.search_off_rounded, "No results found", "We couldn't find anything matching '$query'.");
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
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

  Widget _buildEmptyState(AppColors colors, IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.cardColor,
                shape: BoxShape.circle,
                border: Border.all(color: colors.borderColor),
              ),
              child: Icon(icon, size: 48, color: colors.secondaryText.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                color: colors.primaryText,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.secondaryText,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

