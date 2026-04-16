import 'package:droply/features/auth/auth_controller.dart';
import 'package:droply/features/auth/auth_status.dart';
import 'package:droply/features/auth/presentation/otp_login_page.dart';
import 'package:droply/features/dashboard/presentation/authenticated_home_page.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    required this.controller,
  });

  final AuthController controller;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    widget.controller.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        switch (widget.controller.status) {
          case AuthStatus.unknown:
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          case AuthStatus.unauthenticated:
          case AuthStatus.otpSent:
            return OtpLoginPage(controller: widget.controller);
          case AuthStatus.authenticated:
            return AuthenticatedHomePage(controller: widget.controller);
        }
      },
    );
  }
}
