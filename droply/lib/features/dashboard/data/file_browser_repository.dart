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
  });

  final String? currentFolderId;
  final List<FolderItem> folderPath;
  final List<FolderItem> folders;
  final List<FileItem> files;
}

abstract class FileBrowserRepositoryBase {
  Future<FileBrowserSnapshot> load({String? folderId});
  Future<void> createFolder({required String name, String? parentId});
  Future<void> renameFolder({required String folderId, required String newName});
  Future<void> deleteFolder({required String folderId});
  Future<void> createFile({
    String? folderId,
    required String name,
    required String mimeType,
    required int sizeBytes,
    String? extension,
    required String storagePath,
  });
  Future<void> renameFile({required String fileId, required String newName});
  Future<void> deleteFile({required String fileId});
  Future<List<FolderItem>> loadFolderPath(String? folderId);
}

class FileBrowserRepository extends FileBrowserRepositoryBase {
  FileBrowserRepository(this._client);

  final SupabaseClient _client;

  String get currentUserId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('User session is required for file operations.');
    }
    return user.id;
  }

  Future<FileBrowserSnapshot> load({
    String? folderId,
  }) async {
    final foldersQuery = await _client
        .from('folders')
        .select('id, owner_id, name, parent_id, created_at')
        .eq('owner_id', currentUserId)
        .order('name');

    final filesQuery = await _client
        .from('files')
        .select(
          'id, owner_id, folder_id, name, extension, size_bytes, mime_type, storage_path, version, is_deleted, created_at',
        )
        .eq('owner_id', currentUserId)
        .eq('is_deleted', false)
        .order('created_at', ascending: false);

    final folders = (foldersQuery as List<dynamic>)
        .map((row) => FolderItem.fromMap(Map<String, dynamic>.from(row as Map)))
        .where((folder) => folder.parentId == folderId)
        .toList();

    final files = (filesQuery as List<dynamic>)
        .map((row) => FileItem.fromMap(Map<String, dynamic>.from(row as Map)))
        .where((file) => file.folderId == folderId)
        .toList();

    return FileBrowserSnapshot(
      currentFolderId: folderId,
      folderPath: _buildPath(folderId, foldersQuery),
      folders: folders,
      files: files,
    );
  }

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

  Future<void> renameFolder({
    required String folderId,
    required String newName,
  }) async {
    await _client
        .from('folders')
        .update({'name': newName.trim()}).eq('id', folderId).eq('owner_id', currentUserId);
  }

  Future<void> deleteFolder({
    required String folderId,
  }) async {
    await _client.from('folders').delete().eq('id', folderId).eq('owner_id', currentUserId);
  }

  Future<void> createFile({
    String? folderId,
    required String name,
    required String mimeType,
    required int sizeBytes,
    String? extension,
    required String storagePath,
  }) async {
    await _client.from('files').insert({
      'owner_id': currentUserId,
      'folder_id': folderId,
      'name': name.trim(),
      'extension': extension,
      'size_bytes': sizeBytes,
      'mime_type': mimeType.trim(),
      'storage_path': storagePath.trim(),
      'version': 1,
      'is_deleted': false,
    });
  }

  Future<void> renameFile({
    required String fileId,
    required String newName,
  }) async {
    await _client
        .from('files')
        .update({'name': newName.trim()}).eq('id', fileId).eq('owner_id', currentUserId);
  }

  Future<void> deleteFile({
    required String fileId,
  }) async {
    await _client
        .from('files')
        .update({'is_deleted': true}).eq('id', fileId).eq('owner_id', currentUserId);
  }

  Future<List<FolderItem>> loadFolderPath(String? folderId) async {
    if (folderId == null) {
      return const [];
    }

    final foldersQuery = await _client
        .from('folders')
        .select('id, owner_id, name, parent_id, created_at')
        .eq('owner_id', currentUserId);

    final folders = (foldersQuery as List<dynamic>)
        .map((row) => FolderItem.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();

    final index = {
      for (final folder in folders) folder.id: folder,
    };

    final result = <FolderItem>[];
    var current = index[folderId];
    while (current != null) {
      result.add(current);
      current = current.parentId == null ? null : index[current.parentId];
    }

    return result.reversed.toList();
  }

  List<FolderItem> _buildPath(String? folderId, dynamic foldersQuery) {
    if (folderId == null) {
      return const [];
    }

    final folders = (foldersQuery as List<dynamic>)
        .map((row) => FolderItem.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
    final index = {for (final folder in folders) folder.id: folder};
    final result = <FolderItem>[];
    var current = index[folderId];
    while (current != null) {
      result.add(current);
      current = current.parentId == null ? null : index[current.parentId];
    }
    return result.reversed.toList();
  }
}
