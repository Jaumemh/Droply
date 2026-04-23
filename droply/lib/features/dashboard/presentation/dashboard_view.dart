import 'package:droply/features/dashboard/data/file_browser_repository.dart';
import 'package:droply/features/auth/auth_controller.dart';
import 'package:droply/features/dashboard/presentation/dashboard_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
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
          appBar: AppBar(
            title: const Text('Droply'),
            actions: [
              TextButton.icon(
                onPressed: controller.isBusy ? null : () => _showFolderDialog(context, controller),
                icon: const Icon(Icons.create_new_folder_outlined),
                label: const Text('Carpeta'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: controller.isBusy ? null : () => _showUploadMenu(context, controller),
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Text('Subir'),
              ),
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: widget.authController.isBusy
                    ? null
                    : () => widget.authController.signOut(),
                icon: const Icon(Icons.logout_outlined),
                label: const Text('Salir'),
              ),
              const SizedBox(width: 12),
            ],
          ),
          body: SafeArea(
            child: controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      _Header(
                        controller: controller,
                        userEmail: widget.userEmail,
                        onGoRoot: () => controller.openFolder(null),
                        onRefresh: controller.isBusy ? null : controller.refresh,
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
                      _Actions(
                        onCreateFolder: () => _showFolderDialog(context, controller),
                        onCreateFile: () => _showUploadMenu(context, controller),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Carpetas',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      if (controller.folders.isEmpty)
                        const _EmptyState(label: 'No hay carpetas en este nivel.')
                      else
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: controller.folders
                              .map(
                                (folder) => _FolderCard(
                                  folder: folder,
                                  onOpen: () => controller.openFolder(folder.id),
                                  onRename: () => _showRenameFolderDialog(context, controller, folder),
                                  onDelete: () => controller.deleteFolder(folder.id),
                                ),
                              )
                              .toList(),
                        ),
                      const SizedBox(height: 24),
                      Text(
                        'Archivos',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      if (controller.files.isEmpty)
                        const _EmptyState(label: 'No hay archivos en esta carpeta.')
                      else
                        Card(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: const MaterialStatePropertyAll(Color(0xFFEAF2FF)),
                              columns: const [
                                DataColumn(label: Text('Nombre')),
                                DataColumn(label: Text('Mime')),
                                DataColumn(label: Text('Tamano')),
                                DataColumn(label: Text('Ruta')),
                                DataColumn(label: Text('Acciones')),
                              ],
                              rows: controller.files
                                  .map(
                                    (file) => DataRow(
                                      cells: [
                                        DataCell(Text(file.name)),
                                        DataCell(Text(file.mimeType)),
                                        DataCell(Text(_formatBytes(file.sizeBytes))),
                                        DataCell(Text(file.storagePath)),
                                        DataCell(
                                          Wrap(
                                            spacing: 8,
                                            children: [
                                              TextButton(
                                                onPressed: () => _showRenameFileDialog(
                                                  context,
                                                  controller,
                                                  file,
                                                ),
                                                child: const Text('Renombrar'),
                                              ),
                                              TextButton(
                                                onPressed: () => _shareFile(context, controller, file),
                                                child: const Text('Compartir'),
                                              ),
                                              TextButton(
                                                onPressed: () => controller.deleteFile(file.id),
                                                child: const Text('Eliminar'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      Text(
                        'Compartidos conmigo',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      if (controller.sharedFiles.isEmpty)
                        const _EmptyState(label: 'Aun no tienes archivos compartidos aceptados.')
                      else
                        Card(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: const MaterialStatePropertyAll(Color(0xFFEAF2FF)),
                              columns: const [
                                DataColumn(label: Text('Nombre')),
                                DataColumn(label: Text('Mime')),
                                DataColumn(label: Text('Tamano')),
                                DataColumn(label: Text('Ruta')),
                              ],
                              rows: controller.sharedFiles
                                  .map(
                                    (file) => DataRow(
                                      cells: [
                                        DataCell(Text(file.name)),
                                        DataCell(Text(file.mimeType)),
                                        DataCell(Text(_formatBytes(file.sizeBytes))),
                                        DataCell(Text(file.storagePath)),
                                      ],
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Future<void> _showFolderDialog(BuildContext context, DashboardController controller) async {
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

  Future<void> _shareFile(
    BuildContext context,
    DashboardController controller,
    FileItem file,
  ) async {
    final noteController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
      await _createShareLink(context, controller, file, noteController.text);
            },
            child: const Text('Crear enlace'),
          ),
        ],
      ),
    );
  }

  Future<void> _createShareLink(
    BuildContext context,
    DashboardController controller,
    FileItem file,
    String? note,
  ) async {
    try {
      final result = await controller.createShare(fileId: file.id, note: note);
      final link = Uri.base.resolve('/share/${result.token}').toString();
      if (!context.mounted) {
        return;
      }

      await Clipboard.setData(ClipboardData(text: link));
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enlace copiado. Caduca el ${result.expiresAt}.')),
      );

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Enlace listo'),
          content: SelectableText(link),
          actions: [
            TextButton(
              onPressed: () async {
                await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
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

  Future<void> _showUploadMenu(BuildContext context, DashboardController controller) async {
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
                subtitle: const Text('Selecciona cualquier archivo hasta 50 MB'),
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
      final extension = fileName.contains('.') ? fileName.split('.').last : 'jpg';
      await controller.uploadFile(
        bytes: bytes,
        name: fileName,
        mimeType: _guessMimeType(extension),
        extension: extension,
      );
    } on MissingPluginException {
      _showPickerError('La galeria aun no esta registrada. Haz un reinicio completo de la app.');
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
      _showPickerError('El selector de archivos aun no esta inicializado. Haz un reinicio completo de la app.');
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

  void _showPickerError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0066CC), Color(0xFF0057B2)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tauler',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Base tecnica lista para Android, Web y Desktop con carga real a Storage.',
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Text(
            userEmail,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                label: const Text('Raiz'),
                onPressed: onGoRoot,
                backgroundColor: Colors.white,
              ),
              for (final folder in path)
                ActionChip(
                  label: Text(folder.name),
                  onPressed: () => controller.openFolder(folder.id),
                  backgroundColor: Colors.white,
                ),
              if (onRefresh != null)
                ActionChip(
                  label: const Text('Refrescar'),
                  onPressed: onRefresh,
                  backgroundColor: Colors.white,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.onCreateFolder,
    required this.onCreateFile,
  });

  final VoidCallback onCreateFolder;
  final VoidCallback onCreateFile;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        FilledButton.icon(
          onPressed: onCreateFolder,
          icon: const Icon(Icons.create_new_folder_outlined),
          label: const Text('Crear carpeta'),
        ),
        FilledButton.icon(
          onPressed: onCreateFile,
          icon: const Icon(Icons.upload_file_outlined),
          label: const Text('Subir archivo'),
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
    return SizedBox(
      width: 240,
      child: Card(
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.folder_rounded, color: Color(0xFF0066CC), size: 36),
                const SizedBox(height: 12),
                Text(
                  folder.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  folder.parentId == null ? 'Carpeta raiz' : 'Subcarpeta',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    TextButton(onPressed: onOpen, child: const Text('Abrir')),
                    TextButton(onPressed: onRename, child: const Text('Renombrar')),
                    TextButton(onPressed: onDelete, child: const Text('Eliminar')),
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
  const _EmptyState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDCE4F0)),
      ),
      child: Text(label),
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
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
