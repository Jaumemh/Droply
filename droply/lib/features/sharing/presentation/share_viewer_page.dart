import 'package:droply/features/sharing/data/share_repository.dart';
import 'package:droply/features/sharing/web_noindex.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ShareViewerPage extends StatefulWidget {
  const ShareViewerPage({
    super.key,
    required this.token,
  });

  final String token;

  @override
  State<ShareViewerPage> createState() => _ShareViewerPageState();
}

class _ShareViewerPageState extends State<ShareViewerPage> {
  late final ShareRepository _repository;
  late final Future<ShareAccessResult> _future;

  @override
  void initState() {
    super.initState();
    applyNoIndexMeta();
    _repository = ShareRepository(Supabase.instance.client);
    _future = _resolve('ACCESS');
  }

  Future<ShareAccessResult> _resolve(String action) {
    return _repository.resolveShare(
      token: widget.token,
      action: action,
      userAgent: _userAgent,
      ipClient: null,
    );
  }

  String get _userAgent => 'web';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: FutureBuilder<ShareAccessResult>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _LoadingCard();
                }

                if (snapshot.hasError) {
                  return _ErrorCard(
                    message: 'Enlace caducado o no disponible',
                    detail: snapshot.error.toString().replaceFirst('Exception: ', ''),
                  );
                }

                final access = snapshot.data!;
                return _VisitorCard(
                  access: access,
                  onDownload: () async {
                    try {
                      final downloadAccess = await _resolve('DOWNLOAD');
                      if (!context.mounted) {
                        return;
                      }
                      if (downloadAccess.signedUrl == null || downloadAccess.signedUrl!.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No se pudo firmar la URL de descarga.')),
                        );
                        return;
                      }
                      await launchUrl(
                        Uri.parse(downloadAccess.signedUrl!),
                        mode: LaunchMode.externalApplication,
                      );
                    } on Object catch (error) {
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('No se pudo descargar el archivo: $error')),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      margin: EdgeInsets.all(24),
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.detail,
  });

  final String message;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.link_off_outlined, size: 72, color: Color(0xFFB91C1C)),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(detail, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _VisitorCard extends StatelessWidget {
  const _VisitorCard({
    required this.access,
    required this.onDownload,
  });

  final ShareAccessResult access;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: Color(0xFF0066CC),
                  child: Icon(Icons.lock_outline, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        access.fileName,
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatBytes(access.sizeBytes),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FBFF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFDCE4F0)),
              ),
              child: Column(
                children: [
                  Icon(_iconForMime(access.mimeType), size: 72, color: const Color(0xFF0066CC)),
                  const SizedBox(height: 12),
                  Text(
                    'Enlace temporal generado con Droply',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Caduca el ${access.expiresAt}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF64748B)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onDownload,
              icon: const Icon(Icons.download_outlined),
              label: const Text('Descargar archivo'),
            ),
            const SizedBox(height: 12),
            Text(
              'Aviso legal: Enlace temporal generado con Droply.',
              style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    final mb = bytes / (1024 * 1024);
    if (mb >= 1) {
      return '${mb.toStringAsFixed(1)} MB';
    }
    final kb = bytes / 1024;
    return '${kb.toStringAsFixed(1)} KB';
  }

  IconData _iconForMime(String mimeType) {
    final mime = mimeType.toLowerCase();
    if (mime.startsWith('image/')) {
      return Icons.image_outlined;
    }
    if (mime == 'application/pdf') {
      return Icons.picture_as_pdf_outlined;
    }
    if (mime.contains('word')) {
      return Icons.description_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }
}

