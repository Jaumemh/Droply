import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  Session? get currentSession;
  User? get currentUser;
  Stream<AuthState> get onAuthStateChange;

  Future<void> sendOtp(String email);
  Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
  });
  Future<void> signOut();
}
