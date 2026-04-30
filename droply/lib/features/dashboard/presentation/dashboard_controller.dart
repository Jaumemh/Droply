import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../data/file_browser_repository.dart';
import '../../sharing/data/share_repository.dart';

class DashboardController extends ChangeNotifier {
  DashboardController({
    required FileBrowserRepositoryBase repository,
    ShareRepository? shareRepository,
  })  : _repository = repository,
        _shareRepository = shareRepository;

  final FileBrowserRepositoryBase _repository;
  final ShareRepository? _shareRepository;
  static const _infoMessageDuration = Duration(seconds: 5);

  bool _isLoading = true;
  bool _isBusy = false;
  bool _isUploading = false;
  double _uploadProgress = 0;
  int _uploadTransferredBytes = 0;
  int _uploadTotalBytes = 0;
  Duration? _uploadEta;
  String? _currentFolderId;
  String? _errorMessage;
  String? _infoMessage;
  String? _uploadMessage;
  Timer? _infoMessageTimer;
  String _searchQuery = '';
  FileTypeFilter _fileTypeFilter = FileTypeFilter.all;
  List<FolderItem> _folderPath = const [];
  List<FolderItem> _allFolders = const [];
  List<FolderItem> _folders = const [];
  List<FileItem> _files = const [];
  List<FileItem> _sharedFiles = const [];

  bool get isLoading => _isLoading;
  bool get isBusy => _isBusy;
  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;
  int get uploadTransferredBytes => _uploadTransferredBytes;
  int get uploadTotalBytes => _uploadTotalBytes;
  Duration? get uploadEta => _uploadEta;
  String? get currentFolderId => _currentFolderId;
  String? get errorMessage => _errorMessage;
  String? get infoMessage => _infoMessage;
  String? get uploadMessage => _uploadMessage;
  String get searchQuery => _searchQuery;
  FileTypeFilter get fileTypeFilter => _fileTypeFilter;
  List<FolderItem> get folderPath => _folderPath;
  List<FolderItem> get allFolders => _allFolders;
  List<FolderItem> get folders => _folders;
  List<FileItem> get files => _filterFiles(_files);
  List<FileItem> get sharedFiles => _filterFiles(_sharedFiles);

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
      _allFolders = snapshot.allFolders;
      _folders = snapshot.folders;
      _files = snapshot.files;
      _sharedFiles = snapshot.sharedFiles;
    } catch (error) {
      _errorMessage = _readableError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  void setFileTypeFilter(FileTypeFilter filter) {
    _fileTypeFilter = filter;
    notifyListeners();
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

  Future<void> uploadFile({
    required Uint8List bytes,
    required String name,
    required String mimeType,
    String? extension,
  }) async {
    await _runBusyAction(() async {
      _isUploading = true;
      _uploadProgress = 0;
      _uploadTransferredBytes = 0;
      _uploadTotalBytes = bytes.length;
      _uploadEta = null;
      _uploadMessage = 'Preparando subida...';
      notifyListeners();

      final storagePath = _buildStoragePath(name);
      await _repository.uploadFile(
        folderId: _currentFolderId,
        name: name,
        mimeType: mimeType,
        sizeBytes: bytes.length,
        extension: extension,
        storagePath: storagePath,
        bytes: bytes,
        onProgress: (progress) {
          _uploadProgress = progress.progress;
          _uploadTransferredBytes = progress.bytesTransferred;
          _uploadTotalBytes = progress.totalBytes;
          _uploadEta = progress.remaining;
          _uploadMessage = _formatUploadMessage(progress);
          notifyListeners();
        },
      );

      _showTimedInfoMessage('Archivo subido y registrado.');
      await refresh();
    }).whenComplete(() {
      _isUploading = false;
      _uploadProgress = 0;
      _uploadTransferredBytes = 0;
      _uploadTotalBytes = 0;
      _uploadEta = null;
      _uploadMessage = null;
      notifyListeners();
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

  Future<void> moveFile({
    required String fileId,
    String? folderId,
  }) async {
    await _runBusyAction(() async {
      await _repository.moveFile(
        fileId: fileId,
        folderId: folderId,
      );
      _infoMessage = 'Archivo movido.';
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

  Future<void> removeSharedFile(String shareId) async {
    await _runBusyAction(() async {
      await _repository.removeSharedFile(shareId: shareId);
      _infoMessage = 'Archivo quitado de compartidos.';
      await refresh();
    });
  }

  Future<void> recordFileEvent({
    required String fileId,
    required String action,
    String? shareId,
  }) async {
    final repository = _shareRepository ?? ShareRepository(_repositoryClient);
    await repository.logEvent(
      action: action,
      fileId: fileId,
      shareId: shareId,
      userAgent: 'flutter',
      ipClient: null,
    );
  }

  Future<ShareLinkResult> createShare({
    required String fileId,
    String? note,
  }) async {
    final repository = _shareRepository ?? ShareRepository(_repositoryClient);
    return repository.createShare(fileId: fileId, note: note);
  }

  Future<void> _runBusyAction(Future<void> Function() action) async {
    _isBusy = true;
    _errorMessage = null;
    _infoMessageTimer?.cancel();
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

  String _buildStoragePath(String fileName) {
    final userId = _repository.currentUserId;
    final folderSegments = _folderPath
        .map((folder) => _sanitizePathSegment(folder.name))
        .toList();
    final safeFileName = _sanitizePathSegment(fileName);
    if (folderSegments.isEmpty) {
      return '$userId/root/$safeFileName';
    }
    return '$userId/${folderSegments.join('/')}/$safeFileName';
  }

  String _formatUploadMessage(UploadProgress progress) {
    final percent = (progress.progress * 100).clamp(0, 100).toStringAsFixed(0);
    final eta = progress.remaining == null
        ? 'estimando...'
        : '${progress.remaining!.inSeconds}s restantes';
    return '$percent% - ${_formatTransferSize(progress.bytesTransferred)} / ${_formatTransferSize(progress.totalBytes)} - $eta';
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

  void _showTimedInfoMessage(String message) {
    _infoMessageTimer?.cancel();
    _infoMessage = message;
    _infoMessageTimer = Timer(_infoMessageDuration, () {
      if (_infoMessage != message) {
        return;
      }

      _infoMessage = null;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _infoMessageTimer?.cancel();
    super.dispose();
  }

  String _sanitizePathSegment(String value) {
    final trimmed = value.trim();
    final sanitized = trimmed.replaceAll(RegExp(r'[\\/]+'), '-');
    return sanitized.isEmpty ? 'unnamed' : sanitized;
  }

  dynamic get _repositoryClient {
    if (_repository is FileBrowserRepository) {
      return (_repository as FileBrowserRepository).client;
    }
    throw StateError('Share creation requires a Supabase-backed repository.');
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

  List<FileItem> _filterFiles(List<FileItem> items) {
    return items.where((file) {
      final matchesSearch = _searchQuery.trim().isEmpty ||
          file.name.toLowerCase().contains(_searchQuery.trim().toLowerCase());
      final matchesType = switch (_fileTypeFilter) {
        FileTypeFilter.all => true,
        FileTypeFilter.pdf => _isPdf(file),
        FileTypeFilter.images => _isImage(file),
        FileTypeFilter.other => !_isPdf(file) && !_isImage(file),
      };
      return matchesSearch && matchesType;
    }).toList();
  }

  bool _isPdf(FileItem file) {
    return file.mimeType.toLowerCase() == 'application/pdf' ||
        file.name.toLowerCase().endsWith('.pdf');
  }

  bool _isImage(FileItem file) {
    final mime = file.mimeType.toLowerCase();
    return mime.startsWith('image/') ||
        file.name.toLowerCase().endsWith('.jpg') ||
        file.name.toLowerCase().endsWith('.jpeg') ||
        file.name.toLowerCase().endsWith('.png') ||
        file.name.toLowerCase().endsWith('.gif') ||
        file.name.toLowerCase().endsWith('.webp');
  }
}

enum FileTypeFilter { all, pdf, images, other }
