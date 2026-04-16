import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  Session? get currentSession => _client.auth.currentSession;

  @override
  User? get currentUser => _client.auth.currentUser;

  @override
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  @override
  Future<void> sendOtp(String email) {
    return _client.auth.signInWithOtp(
      email: email,
      shouldCreateUser: true,
    );
  }

  @override
  Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
  }) {
    return _client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email,
    );
  }

  @override
  Future<void> signOut() {
    return _client.auth.signOut();
  }
}
