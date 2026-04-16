import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_repository.dart';

class UnsupportedAuthRepository implements AuthRepository {
  UnsupportedAuthRepository({
    required this.message,
  });

  final String message;

  @override
  Session? get currentSession => null;

  @override
  User? get currentUser => null;

  @override
  Stream<AuthState> get onAuthStateChange => Stream<AuthState>.empty();

  @override
  Future<void> sendOtp(String email) {
    throw AuthException(message);
  }

  @override
  Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
  }) {
    throw AuthException(message);
  }

  @override
  Future<void> signOut() async {}
}
