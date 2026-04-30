import 'dart:typed_data';

import 'package:droply/core/network/app_http_client.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class FolderItem {
  const FolderItem({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.parentId,
    required this.createdAt,
  });

  factory FolderItem.fromMap(Map<String, dynamic> map) {
    return FolderItem(
      id: map['id'] as String,
      ownerId: map['owner_id'] as String,
      name: map['name'] as String,
      parentId: map['parent_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  final String id;
  final String ownerId;
  final String name;
  final String? parentId;
  final DateTime createdAt;
}

class FileItem {
  const FileItem({
    required this.id,
    this.shareId,
    required this.ownerId,
    required this.folderId,
    required this.name,
    required this.extension,
    required this.sizeBytes,
    required this.mimeType,
    required this.storagePath,
    required this.version,
    required this.isDeleted,
    required this.createdAt,
  });

  factory FileItem.fromMap(Map<String, dynamic> map) {
    return FileItem(
      id: map['id'] as String,
      shareId: map['share_id'] as String?,
      ownerId: map['owner_id'] as String,
      folderId: map['folder_id'] as String?,
      name: map['name'] as String,
      extension: map['extension'] as String?,
      sizeBytes: (map['size_bytes'] as num).toInt(),
      mimeType: map['mime_type'] as String,
      storagePath: map['storage_path'] as String,
      version: (map['version'] as num?)?.toInt() ?? 1,
      isDeleted: map['is_deleted'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  final String id;
  final String? shareId;
  final String ownerId;
  final String? folderId;
  final String name;
  final String? extension;
  final int sizeBytes;
  final String mimeType;
  final String storagePath;
  final int version;
  final bool isDeleted;
  final DateTime createdAt;
}

class FileBrowserSnapshot {
  FileBrowserSnapshot({
    required this.currentFolderId,
    required this.folderPath,
    required this.folders,
    required this.files,
    required this.sharedFiles,
  });

  final String? currentFolderId;
  final List<FolderItem> folderPath;
  final List<FolderItem> folders;
  final List<FileItem> files;
  final List<FileItem> sharedFiles;
}

class UploadProgress {
  const UploadProgress({
    required this.bytesTransferred,
    required this.totalBytes,
    required this.elapsed,
    required this.remaining,
  });

  final int bytesTransferred;
  final int totalBytes;
  final Duration elapsed;
  final Duration? remaining;

  double get progress => totalBytes == 0 ? 0 : bytesTransferred / totalBytes;
}

abstract class FileBrowserRepositoryBase {
  String get currentUserId;
  Future<FileBrowserSnapshot> load({String? folderId});
  Future<void> createFolder({required String name, String? parentId});
  Future<void> renameFolder({required String folderId, required String newName});
  Future<void> deleteFolder({required String folderId});
  Future<FileItem> uploadFile({
    String? folderId,
    required String name,
    required String mimeType,
    required int sizeBytes,
    String? extension,
    required String storagePath,
    required Uint8List bytes,
    required void Function(UploadProgress progress) onProgress,
  });
  Future<void> renameFile({required String fileId, required String newName});
  Future<void> deleteFile({required String fileId});
  Future<void> removeSharedFile({required String shareId});
  Future<List<FolderItem>> loadFolderPath(String? folderId);
  Future<List<FileItem>> loadSharedFiles();
}

class FileBrowserRepository extends FileBrowserRepositoryBase {
  FileBrowserRepository(this._client);

  final SupabaseClient _client;

  SupabaseClient get client => _client;

  String get currentUserId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('User session is required for file operations.');
    }
    return user.id;
  }

  @override
  Future<FileBrowserSnapshot> load({
    String? folderId,
  }) async {
    final foldersQuery = await _client
        .from('folders')
        .select('id, owner_id, name, parent_id, created_at')
        .eq('owner_id', currentUserId)
        .order('created_at');

    final filesQuery = await _client
        .from('files')
        .select(
          'id, owner_id, folder_id, name, extension, size_bytes, mime_type, storage_path, version, is_deleted, created_at',
        )
        .eq('owner_id', currentUserId)
        .eq('is_deleted', false)
        .order('created_at', ascending: false);

    final folders = _mapFolders(foldersQuery);
    final files = _mapFiles(filesQuery)
        .where((file) => file.folderId == folderId)
        .toList();
    final sharedFiles = await loadSharedFiles();

    return FileBrowserSnapshot(
      currentFolderId: folderId,
      folderPath: _buildPath(folderId, folders),
      folders: folders.where((folder) => folder.parentId == folderId).toList(),
      files: files,
      sharedFiles: sharedFiles,
    );
  }

  @override
  Future<void> createFolder({
    required String name,
    String? parentId,
  }) async {
    await _client.from('folders').insert({
      'owner_id': currentUserId,
      'name': name.trim(),
      'parent_id': parentId,
    });
  }

  @override
  Future<void> renameFolder({
    required String folderId,
    required String newName,
  }) async {
    await _client
        .from('folders')
        .update({'name': newName.trim()}).eq('id', folderId).eq('owner_id', currentUserId);
  }

  @override
  Future<void> deleteFolder({
    required String folderId,
  }) async {
    await _client.from('folders').delete().eq('id', folderId).eq('owner_id', currentUserId);
  }

  @override
  Future<FileItem> uploadFile({
    String? folderId,
    required String name,
    required String mimeType,
    required int sizeBytes,
    String? extension,
    required String storagePath,
    required Uint8List bytes,
    required void Function(UploadProgress progress) onProgress,
  }) async {
    const maxSizeBytes = 50 * 1024 * 1024;
    if (sizeBytes > maxSizeBytes) {
      throw StateError('El archivo supera el limite de 50 MB.');
    }

    final signedUpload = await _client.storage
        .from('droply-files')
        .createSignedUploadUrl(storagePath);

    final client = createAppHttpClient();
    try {
      final request = http.StreamedRequest('PUT', Uri.parse(signedUpload.signedUrl));
      request.headers['Content-Type'] = mimeType;
      request.headers['x-upsert'] = 'true';
      request.contentLength = bytes.length;
      final responseFuture = client.send(request);

      final chunkSize = 64 * 1024;
      var transferred = 0;
      var lastEmission = DateTime.fromMillisecondsSinceEpoch(0);
      final stopwatch = Stopwatch()..start();

      for (var offset = 0; offset < bytes.length; offset += chunkSize) {
        final end = (offset + chunkSize < bytes.length) ? offset + chunkSize : bytes.length;
        final chunk = bytes.sublist(offset, end);
        request.sink.add(chunk);
        transferred += chunk.length;

        final now = DateTime.now();
        if (now.difference(lastEmission) >= const Duration(milliseconds: 80)) {
          final elapsed = stopwatch.elapsed;
          final remaining = _estimateRemaining(elapsed, transferred, bytes.length);
          onProgress(
            UploadProgress(
              bytesTransferred: transferred,
              totalBytes: bytes.length,
              elapsed: elapsed,
              remaining: remaining,
            ),
          );
          lastEmission = now;
        }
      }

      await request.sink.close();
      final response = await responseFuture;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final body = await response.stream.bytesToString();
        throw StateError('Error subiendo a Storage: ${response.statusCode} $body');
      }

      final inserted = await _client
          .from('files')
          .insert({
            'owner_id': currentUserId,
            'folder_id': folderId,
            'name': name.trim(),
            'extension': extension,
            'size_bytes': sizeBytes,
            'mime_type': mimeType.trim(),
            'storage_path': storagePath.trim(),
            'version': 1,
            'is_deleted': false,
          })
          .select(
            'id, owner_id, folder_id, name, extension, size_bytes, mime_type, storage_path, version, is_deleted, created_at',
          )
          .single();

      final file = FileItem.fromMap(Map<String, dynamic>.from(inserted as Map));

      await _client.from('events').insert({
        'user_id': currentUserId,
        'file_id': file.id,
        'action': 'UPLOAD',
        'target_type': 'file',
        'metadata': {
          'size_bytes': sizeBytes,
          'storage_path': storagePath,
          'mime_type': mimeType,
          'elapsed_ms': stopwatch.elapsedMilliseconds,
          'folder_id': folderId,
        },
      });

      onProgress(
        UploadProgress(
          bytesTransferred: bytes.length,
          totalBytes: bytes.length,
          elapsed: stopwatch.elapsed,
          remaining: Duration.zero,
        ),
      );

      return file;
    } finally {
      client.close();
    }
  }

  @override
  Future<void> renameFile({
    required String fileId,
    required String newName,
  }) async {
    await _client
        .from('files')
        .update({'name': newName.trim()}).eq('id', fileId).eq('owner_id', currentUserId);
  }

  @override
  Future<void> deleteFile({
    required String fileId,
  }) async {
    await _client
        .from('files')
        .update({'is_deleted': true}).eq('id', fileId).eq('owner_id', currentUserId);
  }

  @override
  Future<void> removeSharedFile({
    required String shareId,
  }) async {
    await _client
        .from('share_grants')
        .delete()
        .eq('share_id', shareId)
        .eq('recipient_id', currentUserId);
  }

  @override
  Future<List<FolderItem>> loadFolderPath(String? folderId) async {
    if (folderId == null) {
      return const [];
    }

    final foldersQuery = await _client
        .from('folders')
        .select('id, owner_id, name, parent_id, created_at')
        .eq('owner_id', currentUserId);

    final folders = _mapFolders(foldersQuery);
    return _buildPath(folderId, folders);
  }

  @override
  Future<List<FileItem>> loadSharedFiles() async {
    final response = await _client.rpc('get_shared_files');
    return _mapFiles(response);
  }

  List<FolderItem> _mapFolders(dynamic foldersQuery) {
    return (foldersQuery as List<dynamic>)
        .map((row) => FolderItem.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  List<FileItem> _mapFiles(dynamic filesQuery) {
    return (filesQuery as List<dynamic>)
        .map((row) => FileItem.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  List<FolderItem> _buildPath(String? folderId, List<FolderItem> folders) {
    if (folderId == null) {
      return const [];
    }

    final index = {for (final folder in folders) folder.id: folder};
    final result = <FolderItem>[];
    var current = index[folderId];
    while (current != null) {
      result.add(current);
      current = current.parentId == null ? null : index[current.parentId];
    }
    return result.reversed.toList();
  }

  Duration? _estimateRemaining(Duration elapsed, int transferred, int total) {
    if (transferred <= 0 || transferred >= total || elapsed.inMilliseconds <= 0) {
      return transferred >= total ? Duration.zero : null;
    }

    final rate = transferred / elapsed.inMilliseconds;
    if (rate <= 0) {
      return null;
    }

    final remainingMs = ((total - transferred) / rate).round();
    return Duration(milliseconds: remainingMs);
  }
}
