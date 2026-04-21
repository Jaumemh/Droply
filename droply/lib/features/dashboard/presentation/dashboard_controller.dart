import 'package:flutter/foundation.dart';

import '../data/file_browser_repository.dart';

class DashboardController extends ChangeNotifier {
  DashboardController({
    required FileBrowserRepositoryBase repository,
  }) : _repository = repository;

  final FileBrowserRepositoryBase _repository;

  bool _isLoading = true;
  bool _isBusy = false;
  String? _currentFolderId;
  String? _errorMessage;
  String? _infoMessage;
  List<FolderItem> _folderPath = const [];
  List<FolderItem> _folders = const [];
  List<FileItem> _files = const [];

  bool get isLoading => _isLoading;
  bool get isBusy => _isBusy;
  String? get currentFolderId => _currentFolderId;
  String? get errorMessage => _errorMessage;
  String? get infoMessage => _infoMessage;
  List<FolderItem> get folderPath => _folderPath;
  List<FolderItem> get folders => _folders;
  List<FileItem> get files => _files;

  Future<void> initialize() async {
    await refresh();
  }

  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final snapshot = await _repository.load(folderId: _currentFolderId);
      _folderPath = snapshot.folderPath;
      _folders = snapshot.folders;
      _files = snapshot.files;
    } catch (error) {
      _errorMessage = _readableError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> openFolder(String? folderId) async {
    _currentFolderId = folderId;
    await refresh();
  }

  Future<void> createFolder(String name) async {
    await _runBusyAction(() async {
      await _repository.createFolder(
        name: name,
        parentId: _currentFolderId,
      );
      _infoMessage = 'Carpeta creada.';
      await refresh();
    });
  }

  Future<void> renameFolder({
    required String folderId,
    required String newName,
  }) async {
    await _runBusyAction(() async {
      await _repository.renameFolder(
        folderId: folderId,
        newName: newName,
      );
      _infoMessage = 'Carpeta renombrada.';
      await refresh();
    });
  }

  Future<void> deleteFolder(String folderId) async {
    await _runBusyAction(() async {
      await _repository.deleteFolder(folderId: folderId);
      _infoMessage = 'Carpeta eliminada.';
      await refresh();
    });
  }

  Future<void> createFile({
    required String name,
    required String mimeType,
    required int sizeBytes,
    String? extension,
    required String storagePath,
  }) async {
    await _runBusyAction(() async {
      await _repository.createFile(
        folderId: _currentFolderId,
        name: name,
        mimeType: mimeType,
        sizeBytes: sizeBytes,
        extension: extension,
        storagePath: storagePath,
      );
      _infoMessage = 'Archivo creado.';
      await refresh();
    });
  }

  Future<void> renameFile({
    required String fileId,
    required String newName,
  }) async {
    await _runBusyAction(() async {
      await _repository.renameFile(fileId: fileId, newName: newName);
      _infoMessage = 'Archivo renombrado.';
      await refresh();
    });
  }

  Future<void> deleteFile(String fileId) async {
    await _runBusyAction(() async {
      await _repository.deleteFile(fileId: fileId);
      _infoMessage = 'Archivo eliminado.';
      await refresh();
    });
  }

  Future<void> _runBusyAction(Future<void> Function() action) async {
    _isBusy = true;
    _errorMessage = null;
    _infoMessage = null;
    notifyListeners();

    try {
      await action();
    } catch (error) {
      _errorMessage = _readableError(error);
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  String _readableError(Object error) {
    final message = error.toString();
    if (message.contains('RLS') || message.contains('row-level security')) {
      return 'No tienes permisos para realizar esta accion.';
    }
    if (message.contains('duplicate') || message.contains('unique')) {
      return 'Ya existe un elemento con ese nombre en esta carpeta.';
    }
    return message.replaceFirst('Exception: ', '');
  }
}
