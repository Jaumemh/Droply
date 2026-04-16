import 'package:droply/core/config/env.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InfrastructureHomePage extends StatelessWidget {
  const InfrastructureHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final client = _tryGetClient();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Droply'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Sprint 1: Infraestructura y Datos',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Base tecnica preparada para Android, Web y Desktop con Supabase privada, RLS y auditoria lista.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: const [
                    _MetricCard(title: '<=3 toques', subtitle: 'Promesa del MVP'),
                    _MetricCard(title: '50 MB', subtitle: 'Limite inicial por archivo'),
                    _MetricCard(title: 'Privado', subtitle: 'Bucket y acceso por RLS'),
                  ],
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Checklist tecnico del sprint',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const _CheckRow('Flutter preparado para Android, Web y Desktop'),
                        const _CheckRow('Bootstrap de Supabase centralizado y seguro'),
                        const _CheckRow('SQL inicial con tablas users, folders, files, shares y events'),
                        const _CheckRow('RLS activado y alineado por owner_id'),
                        const _CheckRow('Bucket privado droply-files con acceso por prefijo'),
                        const _CheckRow('Auditoria lista para UPLOAD, DOWNLOAD y PREVIEW'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estado de conexion base',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _StatusTile(
                          label: 'Supabase URL',
                          value: EnvConfig.supabaseUrl ?? 'Pendiente de configurar',
                        ),
                        _StatusTile(
                          label: 'Estado backend',
                          value: client == null ? 'Pendiente' : 'Inicializado',
                        ),
                        const _StatusTile(
                          label: 'Siguiente sprint',
                          value: 'Auth UI + CRUD inicial de archivos',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  SupabaseClient? _tryGetClient() {
    try {
      return Supabase.instance.client;
    } on Object {
      return null;
    }
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0066CC),
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF475569),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF0E9F6E),
              size: 20,
            ),
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

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 170,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
