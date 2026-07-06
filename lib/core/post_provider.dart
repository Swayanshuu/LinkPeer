import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final postsProvider =
FutureProvider<List<Map<String,dynamic>>>(
        (ref) async {
      final data = await Supabase.instance.client
          .from('posts')
          .select(
          '*, post_likes(user_id), saved_posts(user_id)'
      )
          .order('created_at', ascending: false);

      return List<Map<String,dynamic>>.from(data);
    });