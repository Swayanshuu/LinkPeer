// test/unit/post_filter_test.dart
//
// Unit tests for the post filtering and search logic used in
// HomeScreen (FeedFilterBar) and SearchScreen.
// These are pure Dart tests — no Flutter widgets required.

import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helper functions extracted from screen logic for isolated testing.
// These mirror the exact filter predicates used in HomeScreen and SearchScreen.
// ---------------------------------------------------------------------------

/// Filters posts by post_type. 'all' returns the full list unchanged.
List<Map<String, dynamic>> filterByType(
  List<Map<String, dynamic>> posts,
  String selected,
) {
  if (selected == 'all') return posts;
  return posts
      .where((p) => p['post_type'].toString().toLowerCase() == selected)
      .toList();
}

/// Filters posts by a search query across user_name, title, and content.
/// Returns an empty list when the query is empty or contains only whitespace.
List<Map<String, dynamic>> filterByQuery(
  List<Map<String, dynamic>> posts,
  String query,
) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return [];
  return posts.where((post) {
    final name = (post['user_name'] ?? '').toString().toLowerCase();
    final title = (post['title'] ?? '').toString().toLowerCase();
    final content = (post['content'] ?? '').toString().toLowerCase();
    return name.contains(q) || title.contains(q) || content.contains(q);
  }).toList();
}

// ---------------------------------------------------------------------------
// Sample data
// ---------------------------------------------------------------------------

final List<Map<String, dynamic>> _samplePosts = [
  {
    'id': '1',
    'user_id': 'uid_1',
    'user_name': 'Rahul Sharma',
    'post_type': 'job',
    'title': 'Software Engineer at Google',
    'content': 'Exciting opportunity #job #SWE',
  },
  {
    'id': '2',
    'user_id': 'uid_2',
    'user_name': 'Priya Das',
    'post_type': 'internship',
    'title': 'Summer Internship at Infosys',
    'content': 'Apply before June #internship',
  },
  {
    'id': '3',
    'user_id': 'uid_3',
    'user_name': 'Admin IGIT',
    'post_type': 'announcement',
    'title': 'Exam schedule released',
    'content': 'Please check the portal for dates',
  },
  {
    'id': '4',
    'user_id': 'uid_1',
    'user_name': 'Rahul Sharma',
    'post_type': 'normal',
    'title': '',
    'content': 'Great time at the tech fest #igit',
  },
];

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('filterByType()', () {
    test('"all" returns every post', () {
      final result = filterByType(_samplePosts, 'all');
      expect(result.length, 4);
    });

    test('"job" returns only job posts', () {
      final result = filterByType(_samplePosts, 'job');
      expect(result.length, 1);
      expect(result.first['post_type'], 'job');
    });

    test('"internship" returns only internship posts', () {
      final result = filterByType(_samplePosts, 'internship');
      expect(result.length, 1);
      expect(result.first['post_type'], 'internship');
    });

    test('"announcement" returns only announcement posts', () {
      final result = filterByType(_samplePosts, 'announcement');
      expect(result.length, 1);
      expect(result.first['post_type'], 'announcement');
    });

    test('returns empty list when no posts match the selected type', () {
      final result = filterByType(_samplePosts, 'nonexistent');
      expect(result, isEmpty);
    });

    test('filter is case-insensitive on post_type', () {
      final posts = [
        {..._samplePosts[0], 'post_type': 'JOB'},
      ];
      final result = filterByType(posts, 'job');
      expect(result.length, 1);
    });
  });

  group('filterByQuery()', () {
    test('empty query returns empty list', () {
      final result = filterByQuery(_samplePosts, '');
      expect(result, isEmpty);
    });

    test('matches on user_name (case-insensitive)', () {
      final result = filterByQuery(_samplePosts, 'rahul');
      expect(result.length, 2); // uid_1 has two posts
      expect(result.every((p) => p['user_name'] == 'Rahul Sharma'), isTrue);
    });

    test('matches on title', () {
      final result = filterByQuery(_samplePosts, 'google');
      expect(result.length, 1);
      expect(result.first['id'], '1');
    });

    test('matches on content', () {
      final result = filterByQuery(_samplePosts, 'portal');
      expect(result.length, 1);
      expect(result.first['id'], '3');
    });

    test('query matching multiple fields returns all matches', () {
      // 'internship' appears in both post_type (ignored here) and content
      final result = filterByQuery(_samplePosts, 'internship');
      expect(result.length, 1);
    });

    test('whitespace-only query returns empty list', () {
      final result = filterByQuery(_samplePosts, '   ');
      expect(result, isEmpty);
    });

    test('returns empty when no post matches the query', () {
      final result = filterByQuery(_samplePosts, 'xyznotfound123');
      expect(result, isEmpty);
    });
  });

  group('Role auto-detection logic', () {
    // Mirrors the logic in OnboardingUserDetailsScreen.detectRole()
    String detectUserType(int graduatingYear) {
      final now = DateTime.now().year;
      return graduatingYear <= now ? 'alumni' : 'student';
    }

    test('past graduating year returns "alumni"', () {
      expect(detectUserType(2020), 'alumni');
    });

    test('current year returns "alumni"', () {
      expect(detectUserType(DateTime.now().year), 'alumni');
    });

    test('future graduating year returns "student"', () {
      expect(detectUserType(DateTime.now().year + 2), 'student');
    });
  });

  group('Post owner check logic', () {
    // Mirrors the isOwner check in PostCard.
    bool isOwner(String currentUid, Map post) {
      return currentUid == post['user_id'];
    }

    test('returns true when uid matches post user_id', () {
      expect(isOwner('uid_1', _samplePosts[0]), isTrue);
    });

    test('returns false when uid does not match', () {
      expect(isOwner('uid_99', _samplePosts[0]), isFalse);
    });

    test('returns false for empty uid', () {
      expect(isOwner('', _samplePosts[0]), isFalse);
    });
  });

  group('Post type colour mapping logic', () {
    // Mirrors the postTypeColor() helper in PostCard.
    String postTypeLabel(String type) {
      switch (type.toLowerCase()) {
        case 'job':
          return 'green';
        case 'announcement':
          return 'orange';
        case 'internship':
          return 'blue';
        default:
          return 'grey';
      }
    }

    test('job maps to green', () => expect(postTypeLabel('job'), 'green'));
    test(
      'announcement maps to orange',
      () => expect(postTypeLabel('announcement'), 'orange'),
    );
    test(
      'internship maps to blue',
      () => expect(postTypeLabel('internship'), 'blue'),
    );
    test('normal maps to grey', () => expect(postTypeLabel('normal'), 'grey'));
    test(
      'unknown type maps to grey',
      () => expect(postTypeLabel('random'), 'grey'),
    );
    test('is case-insensitive', () => expect(postTypeLabel('JOB'), 'green'));
  });
}
