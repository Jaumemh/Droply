import 'dart:io';

import 'package:droply/features/dashboard/data/file_browser_repository.dart';
import 'package:droply/features/dashboard/presentation/dashboard_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({
    super.key,
    required this.controller,
    required this.userEmail,
  });

  final DashboardController controller;
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
                onPressed: controller.isBusy ? null : () => controller.createFolder('Nueva carpeta'),
                icon: const Icon(Icons.create_new_folder_outlined),
                label: const Text('Carpeta'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: controller.isBusy ? null : () => controller.createFile(
                      name: 'Nuevo archivo',
                      mimeType: 'application/octet-stream',
                      sizeBytes: 0,
                      extension: 'bin',
                      storagePath:
                          '${controller.currentFolderId ?? 'root'}/nuevo-archivo.bin',
                    ),
                icon: const Icon(Icons.add_box_outlined),
                label: const Text('Archivo'),
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
                      _Actions(
                        onCreateFolder: () => _showFolderDialog(context, controller),
                        onCreateFile: () => _showCreateFileMenu(context, controller),
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
                              headingRowColor: const MaterialStatePropertyAll(
                                Color(0xFFEAF2FF),
                              ),
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
                                        DataCell(Text('${file.sizeBytes} B')),
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

  Future<void> _showCreateFileMenu(BuildContext context, DashboardController controller) async {
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
                subtitle: const Text('Selecciona una foto o imagen del telefono'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _pickFromGallery(controller);
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder_open_outlined),
                title: const Text('Abrir archivos'),
                subtitle: const Text('Navega por el sistema de archivos del telefono'),
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

      await _createFileFromPickedPath(controller, image.path);
    } on MissingPluginException {
      _showPickerError('La galeria aun no esta registrada. Haz un reinicio completo de la app.');
    } on Object catch (error) {
      _showPickerError('No se pudo abrir la galeria: $error');
    }
  }

  Future<void> _pickFromFiles(DashboardController controller) async {
    try {
      final result = await FilePicker.platform.pickFiles(withData: false);
      final path = result?.files.single.path;
      if (path == null) {
        return;
      }

      await _createFileFromPickedPath(controller, path);
    } on Error catch (_) {
      _showPickerError('El selector de archivos aun no esta inicializado. Haz un reinicio completo de la app.');
    } on Object catch (error) {
      _showPickerError('No se pudo abrir el explorador de archivos: $error');
    }
  }

  Future<void> _createFileFromPickedPath(
    DashboardController controller,
    String path,
  ) async {
    final fileName = path.split(RegExp(r'[\\/]+')).last;
    final extension = fileName.contains('.') ? fileName.split('.').last : null;
    final mimeType = _guessMimeType(extension);
    final sizeBytes = await File(path).length();
    final storagePath = '${controller.currentFolderId ?? 'root'}/$fileName';

    await controller.createFile(
      name: fileName,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      extension: extension,
      storagePath: storagePath,
    );
  }

  String _guessMimeType(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      case 'mp4':
        return 'video/mp4';
      default:
        return 'application/octet-stream';
    }
  }

  void _showPickerError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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
    final breadcrumbs = <_Breadcrumb>[
      const _Breadcrumb(label: 'Raiz', folderId: null),
      ...controller.folderPath
          .map((folder) => _Breadcrumb(label: folder.name, folderId: folder.id)),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tauler',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final crumb in breadcrumbs)
                  ActionChip(
                    label: Text(crumb.label),
                    onPressed: () => crumb.folderId == null ? onGoRoot() : controller.openFolder(crumb.folderId),
                    backgroundColor: crumb.folderId == null ? const Color(0xFFEAF2FF) : null,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              controller.currentFolderId == null
                  ? 'Estas en la raiz. Entra en una carpeta para navegar la jerarquia.'
                  : 'Navegacion por parent_id activa. Cada carpeta se carga segun su nivel actual.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.start,
              children: [
                FilledButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Actualizar'),
                ),
                Text(
                  controller.isBusy ? 'Procesando cambios...' : 'Estado listo',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
                ),
                Text(
                  userEmail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF0066CC),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Breadcrumb {
  const _Breadcrumb({
    required this.label,
    required this.folderId,
  });

  final String label;
  final String? folderId;
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
          icon: const Icon(Icons.note_add_outlined),
          label: const Text('Crear archivo'),
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
