import 'dart:html' as html;
import 'dart:math' as math;

import 'package:droply/features/auth/auth_controller.dart';
import 'package:droply/features/dashboard/data/file_browser_repository.dart';
import 'package:droply/features/dashboard/data/folder_sharing_repository.dart';
import 'package:droply/features/dashboard/presentation/dashboard_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({
    super.key,
    required this.controller,
    required this.authController,
    required this.userEmail,
  });

  final DashboardController controller;
  final AuthController authController;
  final String userEmail;

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  List<FolderShare>? _sharedFolders;
  bool _loadingSharedFolders = true;
  bool _isSendingInvitation = false;
  String? _highlightedSharedFolderId;
  bool _handledAcceptedFolder = false;

  @override
  void initState() {
    super.initState();
    _highlightedSharedFolderId =
        html.window.sessionStorage['droply_accepted_folder_id'];
    _initializeDashboard();
  }

  Future<void> _initializeDashboard() async {
    await widget.controller.initialize();
    await _loadSharedFolders();
  }

  Future<void> _loadSharedFolders() async {
    try {
      final supabase = Supabase.instance.client;
      final repository = FolderSharingRepository(supabase);
      final folders = await repository.getSharedFolders();
      if (mounted) {
        setState(() {
          _sharedFolders = folders;
          _loadingSharedFolders = false;
        });
      }
      await _openAcceptedFolderIfNeeded(folders);
    } catch (e) {
      if (mounted) {
        setState(() {
          _sharedFolders = [];
          _loadingSharedFolders = false;
        });
      }
    }
  }

  Future<void> _openAcceptedFolderIfNeeded(List<FolderShare> folders) async {
    if (_handledAcceptedFolder) {
      return;
    }

    final acceptedFolderId =
        html.window.sessionStorage['droply_accepted_folder_id'];
    if (acceptedFolderId == null || acceptedFolderId.isEmpty) {
      return;
    }

    final exists = folders.any((share) => share.folderId == acceptedFolderId);
    if (!exists) {
      return;
    }

    _handledAcceptedFolder = true;
    html.window.sessionStorage.remove('droply_accepted_folder_id');
    if (!mounted) {
      return;
    }

    setState(() {
      _highlightedSharedFolderId = acceptedFolderId;
    });
    await widget.controller.openFolder(acceptedFolderId);
  }

  FolderShare? get _currentSharedFolder {
    final currentFolderId = widget.controller.currentFolderId;
    if (currentFolderId == null || _sharedFolders == null) {
      return null;
    }
    for (final share in _sharedFolders!) {
      final pathContainsShare = widget.controller.folderPath.any(
        (folder) => folder.id == share.folderId,
      );
      if (share.folderId == currentFolderId || pathContainsShare) {
        return share;
      }
    }
    return null;
  }

  bool get _canCreateInCurrentFolder {
    final share = _currentSharedFolder;
    return share == null ||
        share.permission == FolderPermission.upload ||
        share.permission == FolderPermission.full;
  }

  bool get _canModifyCurrentFolder {
    final share = _currentSharedFolder;
    return share == null || share.permission == FolderPermission.full;
  }

  bool get _canDownloadInCurrentFolder {
    final share = _currentSharedFolder;
    return share == null ||
        share.permission == FolderPermission.download ||
        share.permission == FolderPermission.upload ||
        share.permission == FolderPermission.full;
  }

  bool _canShareFolder(FolderItem folder) {
    return folder.ownerId == widget.controller.currentUserId;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        final theme = Theme.of(context);

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
            child: Stack(
              children: [
                const Positioned.fill(
                  child: CustomPaint(painter: _DriveBackgroundPainter()),
                ),
                SafeArea(
                  child: controller.isLoading
                      ? const _DriveLoadingState()
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
                          children: [
                            _DriveTopBar(
                              controller: controller,
                              authController: widget.authController,
                              canCreateFolder: _canCreateInCurrentFolder,
                              canUpload: _canCreateInCurrentFolder,
                              onCreateFolder: () =>
                                  _showFolderDialog(context, controller),
                              onUpload: () =>
                                  _showUploadMenu(context, controller),
                              onSignOut: () => widget.authController.signOut(),
                            ),
                            const SizedBox(height: 22),
                            _Header(
                              controller: controller,
                              userEmail: widget.userEmail,
                              sharedFolder: _currentSharedFolder,
                              onGoRoot: () => controller.openFolder(null),
                              onRefresh: controller.isBusy
                                  ? null
                                  : controller.refresh,
                              theme: theme,
                            ),
                            const SizedBox(height: 20),
                            if (controller.uploadMessage != null) ...[
                              _Banner(
                                color: const Color(0xFFEAF2FF),
                                textColor: const Color(0xFF0057B2),
                                text: controller.uploadMessage!,
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (controller.errorMessage != null) ...[
                              _Banner(
                                color: const Color(0xFFFEE2E2),
                                textColor: const Color(0xFF991B1B),
                                text: controller.errorMessage!,
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (controller.infoMessage != null) ...[
                              _Banner(
                                color: const Color(0xFFE0F2FE),
                                textColor: const Color(0xFF075985),
                                text: controller.infoMessage!,
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (controller.isUploading) ...[
                              _UploadProgressCard(controller: controller),
                              const SizedBox(height: 16),
                            ],
                            _SearchAndFilterBar(controller: controller),
                            const SizedBox(height: 20),
                            if (_currentSharedFolder != null) ...[
                              _SharedFolderContextCard(
                                share: _currentSharedFolder!,
                              ),
                              const SizedBox(height: 16),
                            ],
                            _SectionHeader(
                              icon: Icons.folder_rounded,
                              title: 'Carpetas',
                              subtitle:
                                  '${controller.folders.length} en este nivel',
                            ),
                            const SizedBox(height: 12),
                            if (controller.folders.isEmpty)
                              const _EmptyState(
                                icon: Icons.create_new_folder_outlined,
                                title: 'No hay carpetas en este nivel',
                                label:
                                    'Crea una carpeta para organizar esta zona.',
                              )
                            else
                              Wrap(
                                alignment: WrapAlignment.start,
                                spacing: 16,
                                runSpacing: 16,
                                children: controller.folders
                                    .map(
                                      (folder) => _FolderCard(
                                        folder: folder,
                                        onOpen: () =>
                                            controller.openFolder(folder.id),
                                        onRename: _canModifyCurrentFolder
                                            ? () => _showRenameFolderDialog(
                                                  context,
                                                  controller,
                                                  folder,
                                                )
                                            : null,
                                        onDelete: _canModifyCurrentFolder
                                            ? () => controller.deleteFolder(folder.id)
                                            : null,
                                        onShare: _canShareFolder(folder)
                                            ? () => _shareFolderDialog(
                                                  context,
                                                  folder,
                                                )
                                            : null,
                                      ),
                                    )
                                    .toList(),
                              ),
                            const SizedBox(height: 24),
                            _SectionHeader(
                              icon: Icons.insert_drive_file_outlined,
                              title: 'Archivos',
                              subtitle:
                                  '${controller.files.length} encontrados',
                            ),
                            const SizedBox(height: 12),
                            if (controller.files.isEmpty)
                              const _EmptyState(
                                icon: Icons.upload_file_outlined,
                                title: 'No hay archivos en esta carpeta',
                                label:
                                    'Sube un archivo o cambia el filtro de busqueda.',
                              )
                            else
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final columns = constraints.maxWidth >= 1100
                                      ? 3
                                      : constraints.maxWidth >= 700
                                      ? 2
                                      : 1;
                                  return Wrap(
                                    alignment: WrapAlignment.start,
                                    spacing: 16,
                                    runSpacing: 16,
                                    children: controller.files
                                        .map(
                                          (file) => SizedBox(
                                            width: _cardWidth(
                                              constraints.maxWidth,
                                              columns,
                                            ),
                                            child: _FileCard(
                                              title: file.name,
                                              subtitle: _formatBytes(
                                                file.sizeBytes,
                                              ),
                                              icon: _iconForFile(file),
                                              accent: const Color(0xFF0EA5E9),
                                              onTap: () => _openFilePreview(
                                                context,
                                                file,
                                              ),
                                              actions: [
                                                if (_canDownloadInCurrentFolder)
                                                  _FileAction(
                                                    label: 'Descargar',
                                                    icon: Icons.download_outlined,
                                                    onPressed: () =>
                                                        _downloadSharedFile(
                                                          context,
                                                          file,
                                                        ),
                                                  ),
                                                if (_canModifyCurrentFolder)
                                                  _FileAction(
                                                    label: 'Renombrar',
                                                    icon: Icons.edit_outlined,
                                                    onPressed: () =>
                                                        _showRenameFileDialog(
                                                          context,
                                                          controller,
                                                          file,
                                                        ),
                                                  ),
                                                if (_canModifyCurrentFolder)
                                                  _FileAction(
                                                    label: 'Mover',
                                                    icon: Icons
                                                        .drive_file_move_outlined,
                                                    onPressed: () =>
                                                        _showMoveFileDialog(
                                                          context,
                                                          controller,
                                                          file,
                                                        ),
                                                  ),
                                                if (file.ownerId ==
                                                    controller.currentUserId)
                                                  _FileAction(
                                                    label: 'Compartir',
                                                    icon: Icons.share_outlined,
                                                    onPressed: () => _shareFile(
                                                      context,
                                                      controller,
                                                      file,
                                                    ),
                                                  ),
                                                if (_canModifyCurrentFolder)
                                                  _FileAction(
                                                    label: 'Eliminar',
                                                    icon: Icons.delete_outline,
                                                    onPressed: () => controller
                                                        .deleteFile(file.id),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  );
                                },
                              ),
                            const SizedBox(height: 24),
                            if (controller.currentFolderId == null) ...[
                              _SectionHeader(
                                icon: Icons.folder_shared_rounded,
                                title: 'Carpetas compartidas',
                                subtitle:
                                    '${_sharedFolders?.length ?? 0} carpeta${(_sharedFolders?.length ?? 0) == 1 ? '' : 's'}',
                              ),
                              const SizedBox(height: 12),
                              if (_sharedFolders == null || _sharedFolders!.isEmpty)
                                const _EmptyState(
                                  icon: Icons.folder_off_outlined,
                                  title: 'Sin carpetas compartidas',
                                  label:
                                      'Las carpetas compartidas apareceran aqui cuando las aceptes o crees.',
                                )
                              else
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final columns = constraints.maxWidth >= 1100
                                        ? 3
                                        : constraints.maxWidth >= 700
                                        ? 2
                                        : 1;
                                    return Wrap(
                                      alignment: WrapAlignment.start,
                                      spacing: 16,
                                      runSpacing: 16,
                                      children: _sharedFolders!
                                          .map(
                                            (share) => SizedBox(
                                              width: _cardWidth(
                                                constraints.maxWidth,
                                                columns,
                                              ),
                                              child: _SharedFolderHoverCard(
                                                share: share,
                                                isHighlighted:
                                                    share.folderId ==
                                                        _highlightedSharedFolderId,
                                                onOpen: () => controller.openFolder(share.folderId),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    );
                                  },
                                ),
                              const SizedBox(height: 24),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  double _cardWidth(double availableWidth, int columns) {
    final gutters = 16.0 * (columns - 1);
    final usable = availableWidth - gutters;
    final width = usable / columns;
    return width.clamp(260.0, 360.0);
  }

  Future<void> _downloadSharedFile(BuildContext context, FileItem file) async {
    try {
      final signedUrl = await Supabase.instance.client.storage
          .from('droply-files')
          .createSignedUrl(file.storagePath, 300);
      final uri = Uri.parse(signedUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo descargar el archivo: $error')),
      );
    }
  }

  Future<void> _openFilePreview(BuildContext context, FileItem file) async {
    try {
      await widget.controller.recordFileEvent(
        fileId: file.id,
        action: 'PREVIEW',
        shareId: file.shareId,
      );
      final signedUrl = await Supabase.instance.client.storage
          .from('droply-files')
          .createSignedUrl(file.storagePath, 300);
      if (!context.mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980, maxHeight: 760),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FBFF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFDCE4F0)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: _previewForFile(file, signedUrl),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir la previsualizacion: $error')),
      );
    }
  }

  Widget _previewForFile(FileItem file, String signedUrl) {
    final mime = file.mimeType.toLowerCase();
    final isImage =
        mime.startsWith('image/') ||
        file.name.toLowerCase().endsWith('.jpg') ||
        file.name.toLowerCase().endsWith('.jpeg') ||
        file.name.toLowerCase().endsWith('.png') ||
        file.name.toLowerCase().endsWith('.webp') ||
        file.name.toLowerCase().endsWith('.gif') ||
        file.name.toLowerCase().endsWith('.svg') ||
        file.name.toLowerCase().endsWith('.heic') ||
        file.name.toLowerCase().endsWith('.heif') ||
        file.name.toLowerCase().endsWith('.avif') ||
        file.name.toLowerCase().endsWith('.bmp') ||
        file.name.toLowerCase().endsWith('.tif') ||
        file.name.toLowerCase().endsWith('.tiff');
    final isPdf =
        mime == 'application/pdf' || file.name.toLowerCase().endsWith('.pdf');

    if (isImage) {
      return Stack(
        fit: StackFit.expand,
        children: [
          const Center(child: CircularProgressIndicator()),
          InteractiveViewer(
            child: Image.network(
              signedUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, progress) {
                if (progress == null) {
                  return Center(child: child);
                }
                return const Center(child: CircularProgressIndicator());
              },
              errorBuilder: (context, error, stackTrace) =>
                  _previewFallback(file),
            ),
          ),
        ],
      );
    }

    if (isPdf) {
      return Stack(
        fit: StackFit.expand,
        children: [
          const Center(child: CircularProgressIndicator()),
          SfPdfViewer.network(
            signedUrl,
            canShowScrollHead: false,
            canShowScrollStatus: false,
            canShowPaginationDialog: false,
          ),
        ],
      );
    }

    if (_isDocx(file)) {
      return _docxFallback(file, signedUrl);
    }

    return _previewFallback(file);
  }

  Widget _previewFallback(FileItem file) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconForFile(file), size: 72, color: const Color(0xFF0066CC)),
          const SizedBox(height: 12),
          Text(
            file.name,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Formato no previsualizable dentro de la tarjeta',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _docxFallback(FileItem file, String signedUrl) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.description_outlined,
            size: 72,
            color: Color(0xFF0066CC),
          ),
          const SizedBox(height: 12),
          Text(
            file.name,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Vista previa DOCX disponible en navegador',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () async {
              final officeUrl = Uri.https(
                'view.officeapps.live.com',
                '/op/embed.aspx',
                {'src': signedUrl},
              );
              await launchUrl(officeUrl, mode: LaunchMode.externalApplication);
            },
            icon: const Icon(Icons.open_in_new_outlined),
            label: const Text('Abrir visor DOCX'),
          ),
        ],
      ),
    );
  }

  bool _isDocx(FileItem file) {
    final mime = file.mimeType.toLowerCase();
    final name = file.name.toLowerCase();
    return mime.contains('wordprocessingml.document') ||
        name.endsWith('.docx') ||
        name.endsWith('.doc');
  }

  Future<void> _showFolderDialog(
    BuildContext context,
    DashboardController controller,
  ) async {
    final nameController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva carpeta'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await controller.createFolder(nameController.text);
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRenameFolderDialog(
    BuildContext context,
    DashboardController controller,
    FolderItem folder,
  ) async {
    final nameController = TextEditingController(text: folder.name);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renombrar carpeta'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Nuevo nombre'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await controller.renameFolder(
                folderId: folder.id,
                newName: nameController.text,
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRenameFileDialog(
    BuildContext context,
    DashboardController controller,
    FileItem file,
  ) async {
    final nameController = TextEditingController(text: file.name);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renombrar archivo'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Nuevo nombre'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await controller.renameFile(
                fileId: file.id,
                newName: nameController.text,
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareFolderDialog(
    BuildContext context,
    FolderItem folder,
  ) async {
    final emailController = TextEditingController();
    final messageController = TextEditingController();
    String selectedPermission = 'download';
    bool inheritToSubfolders = true;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.folder_shared_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Compartir carpeta',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      folder.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Email del destinatario',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'ejemplo@correo.com',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Permisos de acceso',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...['view', 'download', 'upload', 'full'].map((perm) {
                    final permissionLabels = {
                      'view': ('Solo ver', Icons.visibility_outlined),
                      'download': ('Ver y descargar', Icons.download_outlined),
                      'upload': ('Ver, descargar y subir', Icons.upload_outlined),
                      'full': ('Control total', Icons.admin_panel_settings_outlined),
                    };
                    final label = permissionLabels[perm]!;
                    
                    return RadioListTile<String>(
                      value: perm,
                      groupValue: selectedPermission,
                      onChanged: (value) {
                        setDialogState(() {
                          selectedPermission = value!;
                        });
                      },
                      title: Row(
                        children: [
                          Icon(label.$2, size: 20, color: const Color(0xFF10B981)),
                          const SizedBox(width: 8),
                          Text(
                            label.$1,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      activeColor: const Color(0xFF10B981),
                    );
                  }),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    value: inheritToSubfolders,
                    onChanged: (value) {
                      setDialogState(() {
                        inheritToSubfolders = value ?? true;
                      });
                    },
                    title: const Text(
                      'Aplicar a subcarpetas',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Los permisos se heredarán a todas las subcarpetas',
                      style: TextStyle(fontSize: 12),
                    ),
                    activeColor: const Color(0xFF10B981),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Mensaje opcional',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: messageController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Agrega un mensaje personalizado...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty || !email.contains('@')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor ingresa un email válido'),
                      backgroundColor: Color(0xFFEF4444),
                    ),
                  );
                  return;
                }

                Navigator.of(context).pop();
                if (!mounted) return;

                setState(() {
                  _isSendingInvitation = true;
                });

                Object? sendError;
                try {
                  await _sendFolderInvitation(
                    folder.id,
                    email,
                    selectedPermission,
                    inheritToSubfolders,
                    messageController.text.trim().isEmpty
                        ? null
                        : messageController.text.trim(),
                  );
                } catch (e) {
                  sendError = e;
                } finally {
                  if (mounted) {
                    setState(() {
                      _isSendingInvitation = false;
                    });
                  }
                }

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      sendError == null
                          ? 'Invitacion enviada a $email'
                          : 'Error: $sendError',
                    ),
                    backgroundColor: sendError == null
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                  ),
                );

                if (sendError == null) {
                  await _loadSharedFolders();
                }
              },
              icon: const Icon(Icons.send_outlined),
              label: const Text(
                'Enviar invitación',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendFolderInvitation(
    String folderId,
    String email,
    String permission,
    bool inheritToSubfolders,
    String? message,
  ) async {
    final supabase = Supabase.instance.client;
    final repository = FolderSharingRepository(supabase);

    // Convertir string a enum
    final folderPermission = FolderPermission.fromString(permission);

    // Crear la invitación en la base de datos
    final result = await repository.createInvitation(
      folderId: folderId,
      inviteeEmail: email,
      permission: folderPermission,
      inheritToSubfolders: inheritToSubfolders,
      message: message,
      daysValid: 7,
    );

    // Construir el enlace de invitación
    final baseUrl = Uri.base.origin;
    final invitationLink = '$baseUrl/#/accept-folder-invitation?token=${result.token}';

    // Enviar el email usando Edge Function
    final response = await supabase.functions.invoke(
      'send-folder-invitation',
      body: {
        'to': email,
        'invitationLink': invitationLink,
        'folderName': widget.controller.folders
            .firstWhere((f) => f.id == folderId)
            .name,
        'senderEmail': widget.userEmail,
        'message': message,
        'permission': folderPermission.displayName,
        'expiresAt': result.expiresAt.toIso8601String(),
      },
    );

    // Verificar respuesta
    if (response.status != 200) {
      final error = response.data is Map ? response.data['error'] ?? 'Unknown error' : 'Failed to send email';
      throw Exception(error);
    }
  }

  Future<void> _showMoveFileDialog(
    BuildContext context,
    DashboardController controller,
    FileItem file,
  ) async {
    final folders = controller.allFolders;
    final canMoveToRoot = file.ownerId == controller.currentUserId;
    await showDialog<void>(
      context: context,
      builder: (context) {
        String? selectedFolderId = file.folderId;
        if (!canMoveToRoot &&
            !folders.any((folder) => folder.id == selectedFolderId)) {
          selectedFolderId = folders.isEmpty ? null : folders.first.id;
        }
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Mover archivo'),
              content: DropdownButtonFormField<String?>(
                initialValue:
                    folders.any((folder) => folder.id == selectedFolderId)
                    ? selectedFolderId
                    : null,
                decoration: const InputDecoration(labelText: 'Carpeta destino'),
                items: [
                  if (canMoveToRoot)
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Raiz'),
                    ),
                  ...folders.map(
                    (folder) => DropdownMenuItem<String?>(
                      value: folder.id,
                      child: Text(folder.name),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedFolderId = value;
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await controller.moveFile(
                      fileId: file.id,
                      folderId: selectedFolderId,
                    );
                  },
                  child: const Text('Mover'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _shareFile(
    BuildContext context,
    DashboardController controller,
    FileItem file,
  ) async {
    final noteController = TextEditingController();
    String selectedPermission = 'download';
    
    try {
      final result = await showDialog<Map<String, String>?>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF0EA5E9),
                        Color(0xFF0284C7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.share_outlined,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                const Text(
                  'Compartir archivo',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFF8FBFF),
                        Color(0xFFF0F7FF),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFD6EAF5),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.insert_drive_file_outlined,
                        color: Color(0xFF0EA5E9),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          file.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Permisos de acceso',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FBFD),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        value: 'read',
                        groupValue: selectedPermission,
                        onChanged: (value) {
                          setState(() {
                            selectedPermission = value!;
                          });
                        },
                        title: const Row(
                          children: [
                            Icon(
                              Icons.visibility_outlined,
                              size: 20,
                              color: Color(0xFF8B5CF6),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Solo visualizar',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        subtitle: const Padding(
                          padding: EdgeInsets.only(left: 30),
                          child: Text(
                            'El usuario podrá ver el archivo pero no descargarlo',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        activeColor: const Color(0xFF8B5CF6),
                      ),
                      const Divider(height: 1),
                      RadioListTile<String>(
                        value: 'download',
                        groupValue: selectedPermission,
                        onChanged: (value) {
                          setState(() {
                            selectedPermission = value!;
                          });
                        },
                        title: const Row(
                          children: [
                            Icon(
                              Icons.download_outlined,
                              size: 20,
                              color: Color(0xFF10B981),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Visualizar y descargar',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        subtitle: const Padding(
                          padding: EdgeInsets.only(left: 30),
                          child: Text(
                            'El usuario podrá ver y descargar el archivo',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        activeColor: const Color(0xFF10B981),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Nota opcional',
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                    helperText: 'Caduca por defecto en 7 días.',
                    helperStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FBFD),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFFE2E8F0),
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFFE2E8F0),
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFF0EA5E9),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF64748B),
                  backgroundColor: const Color(0xFFF1F5F9),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.of(dialogContext).pop({
                  'note': noteController.text,
                  'permission': selectedPermission,
                }),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5E9),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.link, size: 20),
                label: const Text(
                  'Crear enlace',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      );

      if (result == null || !context.mounted) {
        return;
      }

      await _createShareLink(
        context,
        controller,
        file,
        result['note'],
        result['permission'] ?? 'download',
      );
    } finally {
      noteController.dispose();
    }
  }

  Future<void> _createShareLink(
    BuildContext context,
    DashboardController controller,
    FileItem file,
    String? note,
    String permission,
  ) async {
    try {
      final result = await controller.createShare(
        fileId: file.id,
        note: note,
        permission: permission,
      );
      final link = _buildShareLink(result.token).toString();
      if (!context.mounted) {
        return;
      }

      await Clipboard.setData(ClipboardData(text: link));
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enlace copiado. Caduca el ${_formatExpiryDate(result.expiresAt)}.'),
        ),
      );

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF10B981),
                      Color(0xFF059669),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                'Enlace listo',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFF8FBFF),
                      Color(0xFFF0F7FF),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFD6EAF5),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.link,
                          color: Color(0xFF0EA5E9),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Enlace compartido',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ).copyWith(letterSpacing: 0.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SelectableText(
                      link,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFD1FAE5),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF10B981),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Enlace copiado al portapapeles',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                await launchUrl(
                  Uri.parse(link),
                  mode: LaunchMode.externalApplication,
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF0EA5E9),
                backgroundColor: const Color(0xFFE7F8FE),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text(
                'Abrir',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0EA5E9),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.close, size: 18),
              label: const Text(
                'Cerrar',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    } on Object catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo crear el enlace: $error')),
      );
    }
  }

  Uri _buildShareLink(String token) {
    return Uri.base.replace(
      fragment: '/share/${Uri.encodeComponent(token)}',
      query: null,
    );
  }

  Future<void> _showUploadMenu(
    BuildContext context,
    DashboardController controller,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Abrir galeria'),
                subtitle: const Text('Selecciona una imagen con progreso real'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _pickFromGallery(controller);
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder_open_outlined),
                title: const Text('Abrir archivos'),
                subtitle: const Text(
                  'Selecciona cualquier archivo hasta 50 MB',
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _pickFromFiles(controller);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFromGallery(DashboardController controller) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) {
        return;
      }

      final bytes = await image.readAsBytes();
      final fileName = image.name;
      final extension = fileName.contains('.')
          ? fileName.split('.').last
          : 'jpg';
      await controller.uploadFile(
        bytes: bytes,
        name: fileName,
        mimeType: _guessMimeType(extension),
        extension: extension,
      );
    } on MissingPluginException {
      _showPickerError(
        'La galeria aun no esta registrada. Haz un reinicio completo de la app.',
      );
    } on Object catch (error) {
      _showPickerError('No se pudo abrir la galeria: $error');
    }
  }

  Future<void> _pickFromFiles(DashboardController controller) async {
    try {
      final result = await FilePicker.platform.pickFiles(withData: true);
      final file = result?.files.single;
      final bytes = file?.bytes;
      if (file == null || bytes == null) {
        return;
      }

      final fileName = file.name;
      final extension = file.extension;
      await controller.uploadFile(
        bytes: bytes,
        name: fileName,
        mimeType: _guessMimeType(extension),
        extension: extension,
      );
    } on Error catch (_) {
      _showPickerError(
        'El selector de archivos aun no esta inicializado. Haz un reinicio completo de la app.',
      );
    } on Object catch (error) {
      _showPickerError('No se pudo abrir el explorador de archivos: $error');
    }
  }

  String _guessMimeType(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'svg':
        return 'image/svg+xml';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      case 'avif':
        return 'image/avif';
      case 'bmp':
        return 'image/bmp';
      case 'tif':
      case 'tiff':
        return 'image/tiff';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      case 'md':
        return 'text/markdown';
      case 'csv':
        return 'text/csv';
      case 'json':
        return 'application/json';
      case 'xml':
        return 'application/xml';
      case 'html':
      case 'htm':
        return 'text/html';
      case 'css':
        return 'text/css';
      case 'js':
        return 'application/javascript';
      case 'zip':
        return 'application/zip';
      case 'rar':
        return 'application/x-rar-compressed';
      case '7z':
        return 'application/x-7z-compressed';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'm4a':
        return 'audio/mp4';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      default:
        return 'application/octet-stream';
    }
  }

  String _formatBytes(int bytes) {
    final mb = bytes / (1024 * 1024);
    if (mb >= 1) {
      return '${mb.toStringAsFixed(1)} MB';
    }
    final kb = bytes / 1024;
    return '${kb.toStringAsFixed(1)} KB';
  }

  IconData _iconForFile(FileItem file) {
    final mime = file.mimeType.toLowerCase();
    final name = file.name.toLowerCase();
    if (mime.startsWith('image/') ||
        name.endsWith('.jpg') ||
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
        name.endsWith('.tiff')) {
      return Icons.image_outlined;
    }
    if (mime == 'application/pdf' || name.endsWith('.pdf')) {
      return Icons.picture_as_pdf_outlined;
    }
    if (mime.startsWith('video/')) {
      return Icons.movie_outlined;
    }
    if (mime.startsWith('audio/')) {
      return Icons.music_note_outlined;
    }
    if (name.endsWith('.doc') || name.endsWith('.docx')) {
      return Icons.description_outlined;
    }
    if (name.endsWith('.xls') || name.endsWith('.xlsx')) {
      return Icons.table_chart_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }

  void _showPickerError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatExpiryDate(DateTime dateTime) {
    final months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    final day = dateTime.day;
    final month = months[dateTime.month - 1];
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day $month $year, $hour:$minute';
  }
}

class _UploadProgressCard extends StatelessWidget {
  const _UploadProgressCard({required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    final progress = controller.uploadProgress;
    final transferred = _formatTransferSize(controller.uploadTransferredBytes);
    final total = _formatTransferSize(controller.uploadTotalBytes);
    final eta = controller.uploadEta == null
        ? 'Calculando...'
        : '${controller.uploadEta!.inSeconds}s restantes';

    return Card(
      color: const Color(0xFFEAF2FF),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subiendo archivo...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0057B2),
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(value: progress, minHeight: 10),
            ),
            const SizedBox(height: 12),
            Text(
              '${(progress * 100).toStringAsFixed(0)}% - $transferred / $total - $eta',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTransferSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _DriveTopBar extends StatelessWidget {
  const _DriveTopBar({
    required this.controller,
    required this.authController,
    required this.canCreateFolder,
    required this.canUpload,
    required this.onCreateFolder,
    required this.onUpload,
    required this.onSignOut,
  });

  final DashboardController controller;
  final AuthController authController;
  final bool canCreateFolder;
  final bool canUpload;
  final VoidCallback onCreateFolder;
  final VoidCallback onUpload;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFD6EAF5)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final logo = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 42,
                height: 42,
                child: CustomPaint(painter: _DroplyLogoPainter()),
              ),
              const SizedBox(width: 12),
              Text(
                'Droply',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF0F172A),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          );

          final buttons = Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _TopBarButton(
                label: 'Carpeta',
                icon: Icons.create_new_folder_outlined,
                onPressed:
                    controller.isBusy || !canCreateFolder ? null : onCreateFolder,
              ),
              _TopBarButton(
                label: 'Subir',
                icon: Icons.cloud_upload_outlined,
                onPressed: controller.isBusy || !canUpload ? null : onUpload,
                filled: true,
              ),
              _TopBarButton(
                label: 'Salir',
                icon: Icons.logout_outlined,
                onPressed: authController.isBusy ? null : onSignOut,
                danger: true,
              ),
            ],
          );

          // En pantallas pequeñas, usar layout vertical
          if (constraints.maxWidth < 600) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                logo,
                const SizedBox(height: 12),
                buttons,
              ],
            );
          }

          // En pantallas grandes, logo a la izquierda y botones a la derecha
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              logo,
              buttons,
            ],
          );
        },
      ),
    );
  }
}

class _TopBarButton extends StatelessWidget {
  const _TopBarButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.filled = false,
    this.danger = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool filled;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF0EA5E9),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: Icon(icon),
        label: Text(label),
      );
    }

    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: danger
            ? const Color(0xFFB42318)
            : const Color(0xFF0369A1),
        backgroundColor: danger
            ? const Color(0xFFFFEDEA)
            : const Color(0xFFE7F8FE),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.controller,
    required this.userEmail,
    required this.sharedFolder,
    required this.onGoRoot,
    required this.onRefresh,
    required this.theme,
  });

  final DashboardController controller;
  final String userEmail;
  final FolderShare? sharedFolder;
  final VoidCallback onGoRoot;
  final VoidCallback? onRefresh;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final path = controller.folderPath;
    final currentName = path.isEmpty ? 'Mi unidad' : path.last.name;
    final totalItems = controller.folders.length + controller.files.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00B8D9), Color(0xFF0877D9)],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.20),
            blurRadius: 34,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Wrap(
        spacing: 28,
        runSpacing: 24,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 260, maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.24),
                    ),
                  ),
                  child: Text(
                    userEmail,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  currentName,
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.02,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  path.isEmpty
                      ? 'Tu unidad personal para guardar, ordenar y compartir.'
                      : 'Estas navegando dentro de ${path.map((folder) => folder.name).join(' / ')}.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                if (sharedFolder != null) ...[
                  const SizedBox(height: 16),
                  _SharedFolderMembersBar(share: sharedFolder!),
                ],
              ],
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 260, maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _DriveMetric(
                      icon: Icons.folder_rounded,
                      value: '${controller.folders.length}',
                      label: 'carpetas',
                    ),
                    _DriveMetric(
                      icon: Icons.insert_drive_file_outlined,
                      value: '${controller.files.length}',
                      label: 'archivos',
                    ),
                    _DriveMetric(
                      icon: Icons.inventory_2_outlined,
                      value: '$totalItems',
                      label: 'elementos',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _BreadcrumbBar(
                  path: path,
                  onGoRoot: onGoRoot,
                  onOpenFolder: controller.openFolder,
                  onRefresh: onRefresh,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DriveMetric extends StatelessWidget {
  const _DriveMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: const Color(0xFFCFFAFE),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BreadcrumbBar extends StatelessWidget {
  const _BreadcrumbBar({
    required this.path,
    required this.onGoRoot,
    required this.onOpenFolder,
    required this.onRefresh,
  });

  final List<FolderItem> path;
  final VoidCallback onGoRoot;
  final ValueChanged<String> onOpenFolder;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ActionChip(
            avatar: const Icon(Icons.home_rounded, size: 18),
            label: const Text('Mi unidad'),
            onPressed: onGoRoot,
            backgroundColor: Colors.white,
            labelStyle: const TextStyle(
              color: Color(0xFF0369A1),
              fontWeight: FontWeight.w800,
            ),
          ),
          for (final folder in path)
            ActionChip(
              avatar: const Icon(Icons.chevron_right_rounded, size: 18),
              label: Text(folder.name),
              onPressed: () => onOpenFolder(folder.id),
              backgroundColor: Colors.white.withValues(alpha: 0.92),
              labelStyle: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
              ),
            ),
          if (onRefresh != null)
            IconButton.filledTonal(
              tooltip: 'Refrescar',
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0369A1),
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchAndFilterBar extends StatelessWidget {
  const _SearchAndFilterBar({required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.white.withValues(alpha: 0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFD6EAF5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: const Color(0xFF0EA5E9).withValues(alpha: 0.04),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final filters = Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildFilterChip(
                context: context,
                icon: Icons.all_inbox_rounded,
                label: 'Todos',
                isSelected: controller.fileTypeFilter == FileTypeFilter.all,
                onSelected: () => controller.setFileTypeFilter(FileTypeFilter.all),
                color: const Color(0xFF0EA5E9),
              ),
              _buildFilterChip(
                context: context,
                icon: Icons.picture_as_pdf_outlined,
                label: 'PDF',
                isSelected: controller.fileTypeFilter == FileTypeFilter.pdf,
                onSelected: () => controller.setFileTypeFilter(FileTypeFilter.pdf),
                color: const Color(0xFFEF4444),
              ),
              _buildFilterChip(
                context: context,
                icon: Icons.image_outlined,
                label: 'Imágenes',
                isSelected: controller.fileTypeFilter == FileTypeFilter.images,
                onSelected: () => controller.setFileTypeFilter(FileTypeFilter.images),
                color: const Color(0xFF8B5CF6),
              ),
              _buildFilterChip(
                context: context,
                icon: Icons.more_horiz_rounded,
                label: 'Otros',
                isSelected: controller.fileTypeFilter == FileTypeFilter.other,
                onSelected: () => controller.setFileTypeFilter(FileTypeFilter.other),
                color: const Color(0xFF10B981),
              ),
            ],
          );

          final search = TextField(
            controller: TextEditingController(text: controller.searchQuery),
            onChanged: controller.setSearchQuery,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              labelText: 'Buscar por nombre',
              labelStyle: TextStyle(
                color: const Color(0xFF64748B).withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
              floatingLabelStyle: const TextStyle(
                color: Color(0xFF0EA5E9),
                fontWeight: FontWeight.w700,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF0EA5E9),
                  size: 22,
                ),
              ),
              suffixIcon: controller.searchQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: controller.clearSearch,
                      icon: const Icon(Icons.close_rounded, size: 20),
                      tooltip: 'Limpiar búsqueda',
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                        foregroundColor: const Color(0xFF64748B),
                      ),
                    ),
              filled: true,
              fillColor: const Color(0xFFF8FBFD),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: Color(0xFF0EA5E9),
                  width: 2.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: Color(0xFFEF4444),
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: Color(0xFFEF4444),
                  width: 2.5,
                ),
              ),
            ),
          );

          if (constraints.maxWidth >= 720) {
            return Row(
              children: [
                Expanded(child: search),
                const SizedBox(width: 18),
                filters,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [search, const SizedBox(height: 16), filters],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    required Color color,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onSelected,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        color,
                        color.withValues(alpha: 0.85),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSelected ? null : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? color.withValues(alpha: 0.3)
                    : const Color(0xFFE2E8F0),
                width: isSelected ? 2 : 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFE0F8FC),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: const Color(0xFF0EA5E9)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF0F172A),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SharedFolderMembersBar extends StatelessWidget {
  const _SharedFolderMembersBar({
    required this.share,
  });

  final FolderShare share;

  @override
  Widget build(BuildContext context) {
    // Filtrar miembros para excluir al propietario (evitar duplicación)
    final allMembers = share.members ?? const [];
    final members = allMembers
        .where((member) => member['email'] != share.ownerEmail)
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.groups_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Miembros de esta carpeta',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${members.length + 1} miembros',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniMemberChip(
                label: '${share.ownerEmail ?? 'Propietario'} · ADMIN',
                icon: Icons.person,
              ),
              ...members.map((member) {
                final email = member['email'] as String? ?? 'usuario';
                final permission = member['permission'] as String? ?? 'view';
                return _MiniMemberChip(
                  label: '$email · $permission',
                  icon: Icons.person_outline,
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniMemberChip extends StatelessWidget {
  const _MiniMemberChip({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SharedFolderContextCard extends StatelessWidget {
  const _SharedFolderContextCard({
    required this.share,
  });

  final FolderShare share;

  @override
  Widget build(BuildContext context) {
    final members = share.members ?? const [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD7E2F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.folder_shared_rounded, color: Color(0xFF0EA5E9)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  share.folderName ?? 'Carpeta compartida',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Compartida por ${share.ownerEmail ?? 'usuario'} · ${share.permission.displayName}',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SmallInfoChip(
                icon: Icons.group_outlined,
                label: '${share.memberCount ?? members.length} miembros',
              ),
              _SmallInfoChip(
                icon: Icons.security_outlined,
                label: 'Acceso compartido',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallInfoChip extends StatelessWidget {
  const _SmallInfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF0F172A)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

class _SharedFolderHoverCard extends StatefulWidget {
  const _SharedFolderHoverCard({
    required this.share,
    required this.isHighlighted,
    required this.onOpen,
  });

  final FolderShare share;
  final bool isHighlighted;
  final VoidCallback onOpen;

  @override
  State<_SharedFolderHoverCard> createState() => _SharedFolderHoverCardState();
}

class _SharedFolderHoverCardState extends State<_SharedFolderHoverCard> {
  bool _isHovered = false;

  Color _permissionColor(FolderPermission permission) {
    switch (permission) {
      case FolderPermission.view:
        return const Color(0xFF6B7280);
      case FolderPermission.download:
        return const Color(0xFF0EA5E9);
      case FolderPermission.upload:
        return const Color(0xFF8B5CF6);
      case FolderPermission.full:
        return const Color(0xFF10B981);
    }
  }

  IconData _permissionIcon(FolderPermission permission) {
    switch (permission) {
      case FolderPermission.view:
        return Icons.visibility_outlined;
      case FolderPermission.download:
        return Icons.download_outlined;
      case FolderPermission.upload:
        return Icons.cloud_upload_outlined;
      case FolderPermission.full:
        return Icons.admin_panel_settings_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final share = widget.share;
    final accent = _permissionColor(share.permission);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..translate(0.0, _isHovered ? -6.0 : 0.0),
        width: 280,
        child: Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(
              color: widget.isHighlighted
                  ? const Color(0xFFF59E0B)
                  : _isHovered
                      ? accent.withValues(alpha: 0.42)
                      : const Color(0xFFD7E2F2),
              width: widget.isHighlighted || _isHovered ? 2 : 1.5,
            ),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: _isHovered
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accent.withValues(alpha: 0.04),
                        accent.withValues(alpha: 0.10),
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        accent.withValues(alpha: 0.04),
                      ],
                    ),
              boxShadow: _isHovered || widget.isHighlighted
                  ? [
                      BoxShadow(
                        color: (widget.isHighlighted
                                ? const Color(0xFFF59E0B)
                                : accent)
                            .withValues(alpha: 0.16),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: accent.withValues(alpha: 0.07),
                        blurRadius: 38,
                        offset: const Offset(0, 18),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: const Color(0xFF64748B).withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: InkWell(
              onTap: widget.onOpen,
              borderRadius: BorderRadius.circular(22),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _isHovered
                                  ? [
                                      accent,
                                      accent.withValues(alpha: 0.82),
                                    ]
                                  : [
                                      accent.withValues(alpha: 0.14),
                                      accent.withValues(alpha: 0.22),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: accent.withValues(
                                alpha: _isHovered ? 0.35 : 0.22,
                              ),
                              width: 1.5,
                            ),
                            boxShadow: _isHovered
                                ? [
                                    BoxShadow(
                                      color: accent.withValues(alpha: 0.25),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            _isHovered
                                ? Icons.folder_open_rounded
                                : Icons.folder_shared_rounded,
                            color: _isHovered ? Colors.white : accent,
                            size: _isHovered ? 34 : 30,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                share.folderName ?? 'Carpeta compartida',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF172033),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Por ${share.ownerEmail ?? 'usuario'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F8FB),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: const Color(0xFFE3EAF5),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _permissionIcon(share.permission),
                            size: 17,
                            color: accent,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            share.permission.displayName,
                            style: TextStyle(
                              color: accent,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.isHighlighted) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Invitacion aceptada',
                          style: TextStyle(
                            color: Color(0xFF92400E),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                    if ((share.memberCount ?? 0) > 0) ...[
                      const SizedBox(height: 12),
                      Text(
                        '${share.memberCount} miembros',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isHovered
                            ? accent
                            : accent.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_open_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Abrir carpeta',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SharedFolderCard extends StatelessWidget {
  const _SharedFolderCard({
    required this.share,
    required this.isHighlighted,
    required this.onOpen,
  });

  final FolderShare share;
  final bool isHighlighted;
  final VoidCallback onOpen;

  String _getPermissionIcon(FolderPermission permission) {
    switch (permission) {
      case FolderPermission.view:
        return 'ðï¸';
      case FolderPermission.download:
        return 'ð¥';
      case FolderPermission.upload:
        return 'ð¤';
      case FolderPermission.full:
        return 'ð';
    }
  }

  IconData _getPermissionMaterialIcon(FolderPermission permission) {
    switch (permission) {
      case FolderPermission.view:
        return Icons.visibility_outlined;
      case FolderPermission.download:
        return Icons.download_outlined;
      case FolderPermission.upload:
        return Icons.cloud_upload_outlined;
      case FolderPermission.full:
        return Icons.admin_panel_settings_outlined;
    }
  }

  Color _getPermissionColor(FolderPermission permission) {
    switch (permission) {
      case FolderPermission.view:
        return const Color(0xFF6B7280);
      case FolderPermission.download:
        return const Color(0xFF0EA5E9);
      case FolderPermission.upload:
        return const Color(0xFF8B5CF6);
      case FolderPermission.full:
        return const Color(0xFF10B981);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            _getPermissionColor(share.permission).withOpacity(0.05),
          ],
        ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isHighlighted
                ? const Color(0xFFF59E0B)
                : _getPermissionColor(share.permission).withOpacity(0.3),
            width: isHighlighted ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isHighlighted
                  ? const Color(0xFFF59E0B).withOpacity(0.22)
                  : _getPermissionColor(share.permission).withOpacity(0.1),
              blurRadius: isHighlighted ? 24 : 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _getPermissionColor(share.permission).withOpacity(0.2),
                      _getPermissionColor(share.permission).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.folder_shared_rounded,
                  size: 28,
                  color: _getPermissionColor(share.permission),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      share.folderName ?? 'Carpeta compartida',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Por ${share.ownerEmail ?? 'usuario'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _getPermissionColor(share.permission).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getPermissionColor(share.permission).withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getPermissionMaterialIcon(share.permission),
                  size: 15,
                  color: _getPermissionColor(share.permission),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    share.permission.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getPermissionColor(share.permission),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (isHighlighted) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Invitacion aceptada',
                style: TextStyle(
                  color: Color(0xFF92400E),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if ((share.memberCount ?? 0) > 0) ...[
            Text(
              '${share.memberCount} miembros',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.folder_open, size: 18),
              label: const Text(
                'Abrir carpeta',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getPermissionColor(share.permission),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FolderCard extends StatefulWidget {
  const _FolderCard({
    required this.folder,
    required this.onOpen,
    required this.onRename,
    required this.onDelete,
    required this.onShare,
  });

  final FolderItem folder;
  final VoidCallback onOpen;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;
  final VoidCallback? onShare;

  @override
  State<_FolderCard> createState() => _FolderCardState();
}

class _FolderCardState extends State<_FolderCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRootFolder = widget.folder.parentId == null;

    return SizedBox(
      width: 260,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()
            ..translate(0.0, _isHovered ? -6.0 : 0.0),
          child: Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: BorderSide(
                color: _isHovered
                    ? const Color(0xFF0EA5E9).withValues(alpha: 0.4)
                    : const Color(0xFFD7E2F2),
                width: _isHovered ? 2 : 1.5,
              ),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: _isHovered
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF0EA5E9).withValues(alpha: 0.03),
                          const Color(0xFF0EA5E9).withValues(alpha: 0.08),
                        ],
                      )
                    : null,
                boxShadow: _isHovered
                    ? [
                        BoxShadow(
                          color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: const Color(0xFF0EA5E9).withValues(alpha: 0.08),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: const Color(0xFF64748B).withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: InkWell(
                onTap: widget.onOpen,
                borderRadius: BorderRadius.circular(22),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: _isHovered
                                ? [
                                    const Color(0xFF0EA5E9),
                                    const Color(0xFF0284C7),
                                  ]
                                : [
                                    const Color(0xFFEAF2FF),
                                    const Color(0xFFDBE9FF),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: _isHovered
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          _isHovered
                              ? Icons.folder_open_rounded
                              : Icons.folder_rounded,
                          color: _isHovered
                              ? Colors.white
                              : const Color(0xFF0066CC),
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        widget.folder.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF172033),
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFF6F8FB),
                              const Color(0xFFF1F5F9),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: const Color(0xFFE3EAF5),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isRootFolder
                                  ? Icons.account_tree_outlined
                                  : Icons.subdirectory_arrow_right_outlined,
                              color: const Color(0xFF5C6F8C),
                              size: 17,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              isRootFolder ? 'Carpeta raíz' : 'Subcarpeta',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF5C6F8C),
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildActionButton(
                            tooltip: 'Abrir',
                            icon: Icons.folder_open_outlined,
                            onPressed: widget.onOpen,
                            color: const Color(0xFF0EA5E9),
                          ),
                          const SizedBox(width: 8),
                          _buildActionButton(
                            tooltip: 'Compartir',
                            icon: Icons.person_add_outlined,
                            onPressed: widget.onShare,
                            color: const Color(0xFF10B981),
                          ),
                          const SizedBox(width: 8),
                          _buildActionButton(
                            tooltip: 'Renombrar',
                            icon: Icons.edit_outlined,
                            onPressed: widget.onRename,
                            color: const Color(0xFF8B5CF6),
                          ),
                          const SizedBox(width: 8),
                          _buildActionButton(
                            tooltip: 'Eliminar',
                            icon: Icons.delete_outline,
                            onPressed: widget.onDelete,
                            color: const Color(0xFFEF4444),
                            isDanger: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback? onPressed,
    required Color color,
    bool isDanger = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: isDanger
                  ? null
                  : LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.12),
                        color.withValues(alpha: 0.18),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              color: isDanger
                  ? const Color(0xFFFFEDEA)
                  : null,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDanger
                    ? const Color(0xFFFFD7D1)
                    : color.withValues(alpha: onPressed == null ? 0.10 : 0.25),
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              color: onPressed == null
                  ? const Color(0xFF94A3B8)
                  : isDanger
                      ? const Color(0xFFB42318)
                      : color,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.label,
  });

  final IconData icon;
  final String title;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD6EAF5)),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFE7F8FE),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: const Color(0xFF0EA5E9), size: 30),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF0F172A),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.color,
    required this.textColor,
    required this.text,
  });

  final Color color;
  final Color textColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FileAction {
  const _FileAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
}

class _FileCard extends StatefulWidget {
  const _FileCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
    required this.actions,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  final List<_FileAction> actions;
  static const _cardHeight = 272.0;
  static const _titleHeight = 48.0;

  @override
  State<_FileCard> createState() => _FileCardState();
}

class _FileCardState extends State<_FileCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..translate(0.0, _isHovered ? -6.0 : 0.0),
        constraints: const BoxConstraints(minHeight: _FileCard._cardHeight),
        child: Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(
              color: _isHovered
                  ? widget.accent.withValues(alpha: 0.4)
                  : const Color(0xFFD7E2F2),
              width: _isHovered ? 2 : 1.5,
            ),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: _isHovered
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.accent.withValues(alpha: 0.03),
                        widget.accent.withValues(alpha: 0.08),
                      ],
                    )
                  : null,
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: widget.accent.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: widget.accent.withValues(alpha: 0.08),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: const Color(0xFF64748B).withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(22),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            widget.accent.withValues(alpha: _isHovered ? 0.18 : 0.12),
                            widget.accent.withValues(alpha: _isHovered ? 0.25 : 0.18),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: widget.accent.withValues(alpha: _isHovered ? 0.35 : 0.22),
                          width: _isHovered ? 2 : 1.5,
                        ),
                        boxShadow: _isHovered
                            ? [
                                BoxShadow(
                                  color: widget.accent.withValues(alpha: 0.25),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.accent,
                        size: _isHovered ? 34 : 30,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: _FileCard._titleHeight,
                      child: Center(
                        child: Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: const Color(0xFF172033),
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFF6F8FB),
                            const Color(0xFFF1F5F9),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: const Color(0xFFE3EAF5),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.sd_storage_outlined,
                            color: const Color(0xFF5C6F8C),
                            size: 17,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            widget.subtitle,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF5C6F8C),
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: widget.actions.map(_buildActionButton).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(_FileAction action) {
    final isDangerAction =
        action.icon == Icons.delete_outline ||
        action.icon == Icons.remove_circle_outline;

    return Tooltip(
      message: action.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: action.onPressed,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: isDangerAction
                  ? LinearGradient(
                      colors: [
                        const Color(0xFFFFEDEA),
                        const Color(0xFFFFE1DC),
                      ],
                    )
                  : LinearGradient(
                      colors: [
                        widget.accent.withValues(alpha: 0.12),
                        widget.accent.withValues(alpha: 0.18),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDangerAction
                    ? const Color(0xFFFFD7D1)
                    : widget.accent.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: Icon(
              action.icon,
              color: isDangerAction
                  ? const Color(0xFFB42318)
                  : widget.accent,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _DriveLoadingState extends StatelessWidget {
  const _DriveLoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFD6EAF5)),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: CustomPaint(painter: _DroplyLogoPainter()),
            ),
            SizedBox(height: 18),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class _DroplyLogoPainter extends CustomPainter {
  const _DroplyLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final strokeWidth = size.shortestSide * 0.078;
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF00B8D9), Color(0xFF0877D9)],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final drop = Path()
      ..moveTo(size.width * 0.5, size.height * 0.09)
      ..cubicTo(
        size.width * 0.68,
        size.height * 0.33,
        size.width * 0.83,
        size.height * 0.42,
        size.width * 0.86,
        size.height * 0.63,
      )
      ..cubicTo(
        size.width * 0.90,
        size.height * 0.86,
        size.width * 0.70,
        size.height * 0.96,
        size.width * 0.50,
        size.height * 0.96,
      )
      ..cubicTo(
        size.width * 0.30,
        size.height * 0.96,
        size.width * 0.10,
        size.height * 0.86,
        size.width * 0.14,
        size.height * 0.63,
      )
      ..cubicTo(
        size.width * 0.17,
        size.height * 0.42,
        size.width * 0.32,
        size.height * 0.33,
        size.width * 0.5,
        size.height * 0.09,
      );

    final arrow = Path()
      ..moveTo(size.width * 0.50, size.height * 0.31)
      ..lineTo(size.width * 0.50, size.height * 0.73)
      ..moveTo(size.width * 0.30, size.height * 0.58)
      ..lineTo(size.width * 0.50, size.height * 0.78)
      ..lineTo(size.width * 0.70, size.height * 0.58);

    final arrowHead = Path()
      ..moveTo(size.width * 0.50, size.height * 0.31)
      ..lineTo(size.width * 0.59, size.height * 0.43)
      ..lineTo(size.width * 0.59, size.height * 0.62)
      ..moveTo(size.width * 0.50, size.height * 0.31)
      ..lineTo(size.width * 0.41, size.height * 0.43)
      ..lineTo(size.width * 0.41, size.height * 0.62);

    canvas.drawPath(drop, paint);
    canvas.drawPath(arrow, paint);
    canvas.drawPath(arrowHead, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DriveBackgroundPainter extends CustomPainter {
  const _DriveBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final wavePaint = Paint()
      ..color = const Color(0xFF0EA5E9).withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var i = 0; i < 5; i++) {
      final y = size.height * (0.14 + i * 0.16);
      final path = Path()..moveTo(-40, y);
      for (var x = -40.0; x <= size.width + 40; x += 34) {
        path.lineTo(x, y + math.sin((x / 86) + i) * (10 + i));
      }
      canvas.drawPath(path, wavePaint);
    }

    final bottomPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [Color(0x3322D3EE), Color(0x0014B8A6)],
      ).createShader(Offset.zero & size);

    final bottom = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.76)
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.62,
        size.width * 0.62,
        size.height * 0.96,
        size.width,
        size.height * 0.70,
      )
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(bottom, bottomPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
