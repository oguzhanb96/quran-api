import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  SupabaseClient? _client;
  
  SupabaseClient? get client {
    try {
      _client ??= Supabase.instance.client;
    } catch (e) {
      _client = null;
    }
    return _client;
  }

  Stream<AuthState> get authStateChanges => 
      client?.auth.onAuthStateChange ?? const Stream.empty();

  User? get currentUser => client?.auth.currentUser;
  
  String? get currentUserId => client?.auth.currentUser?.id;

  bool get isAuthenticated => client?.auth.currentUser != null;

  SupabaseClient get _requireClient {
    final c = client;
    if (c == null) {
      throw StateError(
        'Supabase is not configured. Build with --dart-define=SUPABASE_URL=... '
        'and --dart-define=SUPABASE_ANON_KEY=...',
      );
    }
    return c;
  }

  Future<AuthResponse> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return _requireClient.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    return _requireClient.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }

  Future<void> signOut() async {
    await client?.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await client?.auth.resetPasswordForEmail(email);
  }
}
