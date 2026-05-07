import 'package:droply/features/auth/auth_controller.dart';
import 'package:droply/features/auth/auth_status.dart';
import 'package:droply/features/auth/presentation/otp_login_page.dart';
import 'package:droply/features/dashboard/presentation/authenticated_home_page.dart';
import 'package:droply/features/dashboard/presentation/dashboard_controller.dart';
import 'package:droply/features/dashboard/presentation/accept_folder_invitation_page.dart';
import 'package:droply/features/onboarding/presentation/droply_intro_page.dart';
import 'package:flutter/material.dart';
import 'package:droply/core/platform_utils.dart' as platform_utils;

class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    required this.controller,
    this.dashboardController,
  });

  final AuthController controller;
  final DashboardController? dashboardController;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _introCompleted = false;

  @override
  void initState() {
    super.initState();
    widget.controller.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final pendingInvitationToken =
            platform_utils.sessionStorageGet('droply_pending_invitation_token');
        final hasPendingInvitation =
            pendingInvitationToken != null && pendingInvitationToken.isNotEmpty;

        switch (widget.controller.status) {
          case AuthStatus.unknown:
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          case AuthStatus.unauthenticated:
            if (hasPendingInvitation) {
              return OtpLoginPage(controller: widget.controller);
            }
            if (!_introCompleted) {
              return DroplyIntroPage(
                onFinished: () {
                  if (!mounted) {
                    return;
                  }
                  setState(() {
                    _introCompleted = true;
                  });
                },
              );
            }
            return OtpLoginPage(controller: widget.controller);
          case AuthStatus.otpSent:
            return OtpLoginPage(controller: widget.controller);
          case AuthStatus.authenticated:
            if (hasPendingInvitation) {
              return AcceptFolderInvitationPage(token: pendingInvitationToken!);
            }
            return AuthenticatedHomePage(
              controller: widget.controller,
              dashboardController: widget.dashboardController,
            );
        }
      },
    );
  }
}
