import 'package:droply/features/sharing/data/share_repository.dart';
import 'package:flutter/foundation.dart';
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
  Future<ShareAccessResult>? _future;
  String? _fatalMessage;

  @override
  void initState() {
    super.initState();
    _repository = ShareRepository(Supabase.instance.client);
    _future = _resolve('PREVIEW');
  }

  Future<ShareAccessResult> _resolve(String action) async {
    try {
      return await _repository.resolveShare(
        token: widget.token,
        action: action,
        userAgent: _userAgent,
        ipClient: null,
      );
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _fatalMessage = error.toString().replaceFirst('Exception: ', '');
        });
      }
      rethrow;
    }
  }

  String get _userAgent {
    if (kIsWeb) {
      return 'web';
    }
    return defaultTargetPlatform.name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: FutureBuilder<ShareAccessResult>(
              future: _future,
              builder: (context, snapshot) {
                if (_fatalMessage != null) {
                  return _FatalState(message: _fatalMessage!);
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                if (snapshot.hasError) {
                  return _ErrorState(
                    message: snapshot.error.toString().replaceFirst('Exception: ', ''),
                  );
                }

                final access = snapshot.data!;
                return _ViewerCard(
                  access: access,
                  onDownload: () async {
                    final downloadAccess = await _resolve('DOWNLOAD');
                    if (!mounted) {
                      return;
                    }
                    if (downloadAccess.signedUrl == null || downloadAccess.signedUrl!.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No se pudo firmar la URL. Revisa que el archivo exista en Storage con la ruta guardada.'),
                        ),
                      );
                      return;
                    }
                    await launchUrl(
                      Uri.parse(downloadAccess.signedUrl!),
                      mode: LaunchMode.externalApplication,
                    );
                    setState(() {
                      _future = Future.value(downloadAccess);
                    });
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

class _FatalState extends StatelessWidget {
  const _FatalState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 72, color: Color(0xFFB91C1C)),
            const SizedBox(height: 16),
            Text(
              'No se pudo abrir el enlace',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewerCard extends StatelessWidget {
  const _ViewerCard({
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
        padding: const EdgeInsets.all(24),
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
                        'Enlace temporal seguro hasta ${access.expiresAt}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _PreviewBox(access: access),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: onDownload,
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Descargar'),
                ),
                TextButton.icon(
                  onPressed: access.signedUrl == null || access.signedUrl!.isEmpty
                      ? null
                      : () async {
                          await launchUrl(
                            Uri.parse(access.signedUrl!),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                  icon: const Icon(Icons.open_in_new_outlined),
                  label: const Text('Abrir'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewBox extends StatelessWidget {
  const _PreviewBox({required this.access});

  final ShareAccessResult access;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 260),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDCE4F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: access.isImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: access.signedUrl == null || access.signedUrl!.isEmpty
                    ? _PreviewFallback(access: access)
                    : Image.network(
                        access.signedUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, _) => _PreviewFallback(access: access),
                      ),
              )
            : _PreviewFallback(access: access),
      ),
    );
  }
}

class _PreviewFallback extends StatelessWidget {
  const _PreviewFallback({required this.access});

  final ShareAccessResult access;

  @override
  Widget build(BuildContext context) {
    final label = access.isPdf
        ? 'PDF listo para previsualizar o descargar'
        : 'Archivo listo para descargar';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.description_outlined, size: 72, color: Color(0xFF0066CC)),
          const SizedBox(height: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            access.mimeType,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.link_off_outlined, size: 72, color: Color(0xFFB91C1C)),
            const SizedBox(height: 16),
            Text(
              'Enlace no valido',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
