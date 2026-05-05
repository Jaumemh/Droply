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
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8FDFF),
              Color(0xFFEAF8FF),
              Color(0xFFF7FBFF),
            ],
          ),
        ),
        child: SafeArea(
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
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFD6EAF5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: const Color(0xFF0EA5E9).withValues(alpha: 0.05),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0EA5E9),
                  Color(0xFF0284C7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.cloud_download_outlined,
              size: 38,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          const CircularProgressIndicator(
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Cargando enlace...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
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
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFFFD7D1),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFFEDEA),
                  Color(0xFFFFE1DC),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFFD7D1),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.link_off_outlined,
              size: 42,
              color: Color(0xFFB42318),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            detail,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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

    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFD6EAF5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: const Color(0xFF0EA5E9).withValues(alpha: 0.05),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0EA5E9),
                      Color(0xFF0284C7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_outline,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      access.fileName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFF6F8FB),
                            Color(0xFFF1F5F9),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFE3EAF5),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        _formatBytes(access.sizeBytes),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF5C6F8C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFF8FBFF),
                  Color(0xFFF0F7FF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFFD6EAF5),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                _previewForAccess(access),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.schedule_outlined,
                      size: 18,
                      color: Color(0xFF0EA5E9),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Enlace temporal generado con Droply',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7E6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFEEFC7),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.event_outlined,
                        size: 16,
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Caduca el ${access.expiresAt}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFD97706),
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: onDownload,
              icon: const Icon(Icons.download_outlined, size: 22),
              label: const Text(
                'Descargar archivo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0EA5E9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Aviso legal: Enlace temporal generado con Droply.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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

  Widget _previewForAccess(ShareAccessResult access) {
    final signedUrl = access.signedUrl;
    if ((access.isImage || _isImageFileName(access.fileName)) &&
        signedUrl != null &&
        signedUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 260),
          child: Image.network(
            signedUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _fileIcon(access.mimeType),
          ),
        ),
      );
    }

    return _fileIcon(access.mimeType);
  }

  bool _isImageFileName(String fileName) {
    final name = fileName.toLowerCase();
    return name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.png') ||
        name.endsWith('.webp') ||
        name.endsWith('.gif') ||
        name.endsWith('.svg') ||
        name.endsWith('.heic') ||
        name.endsWith('.heif') ||
        name.endsWith('.avif') ||
        name.endsWith('.bmp') ||
        name.endsWith('.tif') ||
        name.endsWith('.tiff');
  }

  Widget _fileIcon(String mimeType) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0EA5E9).withValues(alpha: 0.15),
            const Color(0xFF0EA5E9).withValues(alpha: 0.25),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Icon(
        _iconForMime(mimeType),
        size: 48,
        color: const Color(0xFF0EA5E9),
      ),
    );
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
