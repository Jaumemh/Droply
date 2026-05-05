import 'dart:math' as math;

import 'package:droply/features/dashboard/data/file_browser_repository.dart';
import 'package:droply/features/auth/auth_controller.dart';
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
                                        onRename: () => _showRenameFolderDialog(
                                          context,
                                          controller,
                                          folder,
                                        ),
                                        onDelete: () =>
                                            controller.deleteFolder(folder.id),
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
                                                _FileAction(
                                                  label: 'Compartir',
                                                  icon: Icons.share_outlined,
                                                  onPressed: () => _shareFile(
                                                    context,
                                                    controller,
                                                    file,
                                                  ),
                                                ),
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
                            _SectionHeader(
                              icon: Icons.group_rounded,
                              title: 'Compartidos conmigo',
                              subtitle:
                                  '${controller.sharedFiles.length} archivos aceptados',
                            ),
                            const SizedBox(height: 12),
                            if (controller.sharedFiles.isEmpty)
                              const _EmptyState(
                                icon: Icons.link_off_rounded,
                                title: 'Sin compartidos aceptados',
                                label:
                                    'Los archivos compartidos contigo apareceran aqui.',
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
                                    children: controller.sharedFiles
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
                                              accent: const Color(0xFF1D4ED8),
                                              onTap: () => _openFilePreview(
                                                context,
                                                file,
                                              ),
                                              actions: [
                                                _FileAction(
                                                  label: 'Descargar',
                                                  icon: Icons.download_outlined,
                                                  onPressed: () =>
                                                      _downloadSharedFile(
                                                        context,
                                                        file,
                                                      ),
                                                ),
                                                _FileAction(
                                                  label: 'Quitar',
                                                  icon: Icons
                                                      .remove_circle_outline,
                                                  onPressed:
                                                      file.shareId == null
                                                      ? null
                                                      : () => controller
                                                            .removeSharedFile(
                                                              file.shareId!,
                                                            ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  );
                                },
                              ),
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

  Future<void> _showMoveFileDialog(
    BuildContext context,
    DashboardController controller,
    FileItem file,
  ) async {
    final folders = controller.allFolders;
    await showDialog<void>(
      context: context,
      builder: (context) {
        String? selectedFolderId = file.folderId;
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
    try {
      final note = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Compartir archivo'),
          content: TextField(
            controller: noteController,
            decoration: const InputDecoration(
              labelText: 'Nota opcional',
              helperText: 'Caduca por defecto en 7 dias.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(noteController.text),
              child: const Text('Crear enlace'),
            ),
          ],
        ),
      );

      if (note == null || !context.mounted) {
        return;
      }

      await _createShareLink(context, controller, file, note);
    } finally {
      noteController.dispose();
    }
  }

  Future<void> _createShareLink(
    BuildContext context,
    DashboardController controller,
    FileItem file,
    String? note,
  ) async {
    try {
      final result = await controller.createShare(fileId: file.id, note: note);
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
          content: Text('Enlace copiado. Caduca el ${result.expiresAt}.'),
        ),
      );

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Enlace listo'),
          content: SelectableText(link),
          actions: [
            TextButton(
              onPressed: () async {
                await launchUrl(
                  Uri.parse(link),
                  mode: LaunchMode.externalApplication,
                );
              },
              child: const Text('Abrir'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
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
    required this.onCreateFolder,
    required this.onUpload,
    required this.onSignOut,
  });

  final DashboardController controller;
  final AuthController authController;
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
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          const SizedBox(
            width: 42,
            height: 42,
            child: CustomPaint(painter: _DroplyLogoPainter()),
          ),
          Text(
            'Droply',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFF0F172A),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 8),
          _TopBarButton(
            label: 'Carpeta',
            icon: Icons.create_new_folder_outlined,
            onPressed: controller.isBusy ? null : onCreateFolder,
          ),
          _TopBarButton(
            label: 'Subir',
            icon: Icons.cloud_upload_outlined,
            onPressed: controller.isBusy ? null : onUpload,
            filled: true,
          ),
          _TopBarButton(
            label: 'Salir',
            icon: Icons.logout_outlined,
            onPressed: authController.isBusy ? null : onSignOut,
            danger: true,
          ),
        ],
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
    required this.onGoRoot,
    required this.onRefresh,
    required this.theme,
  });

  final DashboardController controller;
  final String userEmail;
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD6EAF5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final filters = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                avatar: const Icon(Icons.all_inbox_rounded, size: 18),
                label: const Text('Todos'),
                selected: controller.fileTypeFilter == FileTypeFilter.all,
                onSelected: (_) =>
                    controller.setFileTypeFilter(FileTypeFilter.all),
              ),
              ChoiceChip(
                avatar: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: const Text('PDF'),
                selected: controller.fileTypeFilter == FileTypeFilter.pdf,
                onSelected: (_) =>
                    controller.setFileTypeFilter(FileTypeFilter.pdf),
              ),
              ChoiceChip(
                avatar: const Icon(Icons.image_outlined, size: 18),
                label: const Text('Imagenes'),
                selected: controller.fileTypeFilter == FileTypeFilter.images,
                onSelected: (_) =>
                    controller.setFileTypeFilter(FileTypeFilter.images),
              ),
              ChoiceChip(
                avatar: const Icon(Icons.more_horiz_rounded, size: 18),
                label: const Text('Otros'),
                selected: controller.fileTypeFilter == FileTypeFilter.other,
                onSelected: (_) =>
                    controller.setFileTypeFilter(FileTypeFilter.other),
              ),
            ],
          );

          final search = TextField(
            controller: TextEditingController(text: controller.searchQuery),
            onChanged: controller.setSearchQuery,
            decoration: InputDecoration(
              labelText: 'Buscar por nombre',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: controller.searchQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: controller.clearSearch,
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: const Color(0xFFF8FBFD),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          );

          if (constraints.maxWidth >= 720) {
            return Row(
              children: [
                Expanded(child: search),
                const SizedBox(width: 16),
                filters,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [search, const SizedBox(height: 14), filters],
          );
        },
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

class _FolderCard extends StatelessWidget {
  const _FolderCard({
    required this.folder,
    required this.onOpen,
    required this.onRename,
    required this.onDelete,
  });

  final FolderItem folder;
  final VoidCallback onOpen;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRootFolder = folder.parentId == null;

    return SizedBox(
      width: 260,
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFD7E2F2)),
        ),
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.folder_rounded,
                    color: Color(0xFF0066CC),
                    size: 34,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  folder.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF172033),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F8FB),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFE3EAF5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isRootFolder
                            ? Icons.account_tree_outlined
                            : Icons.subdirectory_arrow_right_outlined,
                        color: const Color(0xFF5C6F8C),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isRootFolder ? 'Carpeta raiz' : 'Subcarpeta',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF5C6F8C),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filledTonal(
                      tooltip: 'Abrir',
                      onPressed: onOpen,
                      icon: const Icon(Icons.folder_open_outlined),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      tooltip: 'Renombrar',
                      onPressed: onRename,
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      tooltip: 'Eliminar',
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                      style: IconButton.styleFrom(
                        foregroundColor: const Color(0xFFB42318),
                        backgroundColor: const Color(0xFFFFEDEA),
                        hoverColor: const Color(0xFFFFD7D1),
                      ),
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

class _FileCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _cardHeight),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFD7E2F2)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: accent.withValues(alpha: 0.18)),
                  ),
                  child: Icon(icon, color: accent, size: 30),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: _titleHeight,
                  child: Center(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF172033),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F8FB),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFE3EAF5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.sd_storage_outlined,
                        color: Color(0xFF5C6F8C),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF5C6F8C),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: actions.map(_buildActionButton).toList(),
                ),
              ],
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

    return IconButton(
      tooltip: action.label,
      onPressed: action.onPressed,
      icon: Icon(action.icon, size: 20),
      style: IconButton.styleFrom(
        fixedSize: const Size.square(42),
        foregroundColor: isDangerAction ? const Color(0xFFB42318) : accent,
        backgroundColor: isDangerAction
            ? const Color(0xFFFFEDEA)
            : accent.withValues(alpha: 0.10),
        disabledForegroundColor: const Color(0xFF94A3B8),
        disabledBackgroundColor: const Color(0xFFF1F5F9),
        hoverColor: isDangerAction
            ? const Color(0xFFFFD7D1)
            : accent.withValues(alpha: 0.16),
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
