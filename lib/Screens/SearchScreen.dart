import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../Component/AppColour.dart';
import '../Component/Home/PostCard.dart';
import '../Controllers/PostProvider.dart';

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
    final posts = ref.watch(postsProvider);

    return Scaffold(
      backgroundColor: AppColours.bgColor,

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
                        color: AppColours.cardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColours.borderColor),
                      ),

                      child: Row(
                        children: [
                          const Icon(
                            Icons.search,
                            color: AppColours.secondaryText,
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: TextField(
                              controller: searchController,

                              autofocus: true,

                              style: const TextStyle(
                                color: AppColours.primaryText,
                              ),

                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: "Search name, title, content...",
                                hintStyle: TextStyle(
                                  color: AppColours.secondaryText,
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

                              child: const Icon(
                                Icons.close,
                                color: AppColours.secondaryText,
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
                        color: AppColours.cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColours.borderColor),
                      ),

                      child: const Icon(
                        Icons.close_rounded,
                        color: AppColours.primaryText,
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

                error: (e, s) => const Center(
                  child: Text(
                    "Failed to load",
                    style: TextStyle(color: Colors.white),
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
                    return const Center(
                      child: Text(
                        "Search posts by user, title or content",
                        style: TextStyle(color: AppColours.secondaryText),
                      ),
                    );
                  }

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text(
                        "No results found",
                        style: TextStyle(color: AppColours.secondaryText),
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
