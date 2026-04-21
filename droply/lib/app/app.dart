import 'package:droply/core/config/env.dart';
import 'package:droply/features/auth/auth_controller.dart';
import 'package:droply/features/auth/presentation/auth_gate.dart';
import 'package:droply/features/auth/supabase_auth_repository.dart';
import 'package:droply/features/auth/unsupported_auth_repository.dart';
import 'package:droply/features/dashboard/presentation/dashboard_controller.dart';
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
      home: AuthGate(
        controller: _controller,
        dashboardController: _dashboardController,
      ),
    );
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
