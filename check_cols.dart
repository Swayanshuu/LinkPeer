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
    final res = await supabase.from('posts').select().limit(1);
    final cols = res.first.keys.toList();
    print("Post columns: $cols");
  } catch (e) {
    print("Error: $e");
  }
}
