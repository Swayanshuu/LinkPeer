import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final userProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;

  if (uid == null) {
    return {};
  }

  final data = await Supabase.instance.client
      .from('users')
      .select(
        'name, photo_url, user_type, id, profile_completed, department, email, role, created_at, last_login, branch, college, stream, graduating_year, designation, phone',
      )
      .eq('id', uid)
      .single();

  return data;
});
