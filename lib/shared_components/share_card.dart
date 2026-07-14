import 'package:flutter/material.dart';

class ShareCard extends StatelessWidget {
  final String userName;
  final String userRole;
  final String userAvatar;
  final String postContent;

  const ShareCard({
    super.key,
    required this.userName,
    required this.userRole,
    required this.userAvatar,
    required this.postContent,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
            width: 400,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Avatar, Name, Role
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: userAvatar.isNotEmpty
                          ? NetworkImage(userAvatar)
                          : null,
                      child: userAvatar.isEmpty
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            userRole,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // LinkPeer Branding Logo
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/LinkPeer.png',
                            height: 16,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'LinkPeer',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Post Content
                Text(
                  postContent,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 24),
                // Footer
                const Divider(),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'View full post on LinkPeer',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
      ),
    );
  }
}
