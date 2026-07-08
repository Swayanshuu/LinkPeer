import 'package:supabase/supabase.dart';
import 'dart:io';

void main() async {
  final envFile = File('.env');
  final lines = await envFile.readAsLines();
  String supabaseUrl = '';
  String supabaseKey = '';
  
  for (final line in lines) {
    if (line.startsWith('SUPABASE_URL=')) {
      supabaseUrl = line.split('=')[1];
    }
    if (line.startsWith('SUPABASE_ANON_KEY=')) {
      supabaseKey = line.split('=')[1];
    }
  }

  final supabase = SupabaseClient(supabaseUrl, supabaseKey);

  try {
    final res = await supabase.from('posts').select('*, post_likes(user_id), saved_posts(user_id), users!posts_user_id_fkey(is_verified, subscription_plan)').order('created_at', ascending: false).limit(1);
    print("Success: ${res.first.keys}");
  } catch (e) {
    print("Error querying posts: $e");
  }
}
