import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final postsProvider =
FutureProvider<List<Map<String,dynamic>>>(
        (ref) async {
      final data = await Supabase.instance.client
          .from('posts')
          .select(
          'user_id ,title, content, link, post_type, user_name, user_photo, created_at, user_type, department, id,file_name, image_url, file_url, file_type'
      )
          .order('created_at', ascending: false);

      return List<Map<String,dynamic>>.from(data);
    });