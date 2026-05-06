import 'package:droply/core/config/env.dart';
import 'package:droply/features/auth/auth_controller.dart';
import 'package:droply/features/auth/presentation/auth_gate.dart';
import 'package:droply/features/auth/supabase_auth_repository.dart';
import 'package:droply/features/auth/unsupported_auth_repository.dart';
import 'package:droply/features/dashboard/presentation/dashboard_controller.dart';
import 'package:droply/features/dashboard/presentation/accept_folder_invitation_page.dart';
import 'package:droply/features/sharing/presentation/share_viewer_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DroplyApp extends StatefulWidget {
  const DroplyApp({
    super.key,
    AuthController? authController,
    DashboardController? dashboardController,
  })  : _providedController = authController,
        _dashboardController = dashboardController;

  final AuthController? _providedController;
  final DashboardController? _dashboardController;

  @override
  State<DroplyApp> createState() => _DroplyAppState();
}

class _DroplyAppState extends State<DroplyApp> {
  late final AuthController _controller;
  late final DashboardController? _dashboardController;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget._providedController == null;
    _controller = widget._providedController ?? _createDefaultController();
    _dashboardController = widget._dashboardController;
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0066CC),
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'Droply',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF6F8FB),
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.surface,
          foregroundColor: const Color(0xFF1E293B),
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFFDCE4F0)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      home: _buildEntryPage(),
    );
  }

  Widget _buildEntryPage() {
    final token = _shareTokenFromUri(Uri.base);
    if (token != null) {
      return ShareViewerPage(token: token);
    }

    final invitationToken = _folderInvitationTokenFromUri(Uri.base);
    if (invitationToken != null) {
      return AcceptFolderInvitationPage(token: invitationToken);
    }

    return AuthGate(
      controller: _controller,
      dashboardController: _dashboardController,
    );
  }

  String? _shareTokenFromUri(Uri uri) {
    final pathToken = _shareTokenFromSegments(uri.pathSegments);
    if (pathToken != null) {
      return pathToken;
    }

    if (uri.fragment.isEmpty) {
      return null;
    }

    final fragmentPath = uri.fragment.startsWith('/')
        ? uri.fragment
        : '/${uri.fragment}';
    final fragmentUri = Uri.parse(fragmentPath);
    return _shareTokenFromSegments(fragmentUri.pathSegments);
  }

  String? _shareTokenFromSegments(List<String> segments) {
    if (segments.isEmpty || segments.first != 'share') {
      return null;
    }

    return segments.length > 1 ? segments[1] : '';
  }

  String? _folderInvitationTokenFromUri(Uri uri) {
    // Primero intentar desde el path
    final pathToken = _folderInvitationTokenFromSegments(uri.pathSegments);
    if (pathToken != null) {
      return pathToken;
    }

    // Intentar desde el fragment
    if (uri.fragment.isEmpty) {
      return null;
    }

    final fragmentPath = uri.fragment.startsWith('/')
        ? uri.fragment
        : '/${uri.fragment}';
    final fragmentUri = Uri.parse(fragmentPath);
    
    // Intentar desde segments del fragment
    final fragmentToken = _folderInvitationTokenFromSegments(fragmentUri.pathSegments);
    if (fragmentToken != null) {
      return fragmentToken;
    }

    // Intentar desde query parameters del fragment
    return fragmentUri.queryParameters['token'];
  }

  String? _folderInvitationTokenFromSegments(List<String> segments) {
    if (segments.isEmpty || segments.first != 'accept-folder-invitation') {
      return null;
    }

    return segments.length > 1 ? segments[1] : null;
  }

  AuthController _createDefaultController() {
    if (!EnvConfig.isSupabaseConfigured) {
      return AuthController(
        repository: UnsupportedAuthRepository(
          message:
              'Configura SUPABASE_URL y SUPABASE_ANON_KEY para usar el login OTP.',
        ),
      );
    }

    try {
      final client = Supabase.instance.client;
      return AuthController(
        repository: SupabaseAuthRepository(client),
      );
    } on Object {
      return AuthController(
        repository: UnsupportedAuthRepository(
          message:
              'Supabase no se ha inicializado correctamente. Revisa la configuracion del entorno.',
        ),
      );
    }
  }
}
