import 'package:droply/features/auth/auth_controller.dart';
import 'package:flutter/material.dart';

class AuthenticatedHomePage extends StatelessWidget {
  const AuthenticatedHomePage({
    super.key,
    required this.controller,
  });

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email = controller.currentUser?.email ?? controller.email;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Droply'),
        actions: [
          TextButton(
            onPressed: controller.isBusy ? null : controller.signOut,
            child: const Text('Cerrar sesion'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Dashboard autenticado',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _DashboardCard(
                      title: 'Usuario',
                      value: email.isEmpty ? 'Pendiente' : email,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF64748B),
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF0E9F6E),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
