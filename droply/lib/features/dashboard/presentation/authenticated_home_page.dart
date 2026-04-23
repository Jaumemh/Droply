import 'package:droply/features/auth/auth_controller.dart';
import 'package:droply/features/dashboard/data/file_browser_repository.dart';
import 'package:droply/features/dashboard/presentation/dashboard_controller.dart';
import 'package:droply/features/dashboard/presentation/dashboard_view.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthenticatedHomePage extends StatefulWidget {
  const AuthenticatedHomePage({
    super.key,
    required this.controller,
    this.dashboardController,
  });

  final AuthController controller;
  final DashboardController? dashboardController;

  @override
  State<AuthenticatedHomePage> createState() => _AuthenticatedHomePageState();
}

class _AuthenticatedHomePageState extends State<AuthenticatedHomePage> {
  late final DashboardController _dashboardController;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.dashboardController == null;
    _dashboardController = widget.dashboardController ??
        DashboardController(
          repository: FileBrowserRepository(Supabase.instance.client),
        );
  }

  @override
  void dispose() {
    if (_ownsController) {
      _dashboardController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DashboardView(
      controller: _dashboardController,
      authController: widget.controller,
      userEmail: widget.controller.currentUser?.email ?? widget.controller.email,
    );
  }
}
