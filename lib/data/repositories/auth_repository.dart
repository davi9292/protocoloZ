import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

class AuthRepository {
  final SupabaseClient client = Supabase.instance.client;
  bool get isSignedIn => client.auth.currentSession != null;
  User? get user => client.auth.currentUser;

  Future<void> signIn(String email, String password) async {
    await client.auth.signInWithPassword(email: email.trim(), password: password);
  }

  Future<void> signUp(String nickname, String email, String password) async {
    await client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'nickname': nickname.trim()},
    );
  }

  Future<void> signOut() => client.auth.signOut();
}
