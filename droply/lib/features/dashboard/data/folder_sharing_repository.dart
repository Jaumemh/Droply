import 'package:supabase_flutter/supabase_flutter.dart';

/// Enum para los permisos de carpetas compartidas
enum FolderPermission {
  view('view'),
  download('download'),
  upload('upload'),
  full('full');

  const FolderPermission(this.value);
  final String value;

  static FolderPermission fromString(String value) {
    return FolderPermission.values.firstWhere(
      (e) => e.value == value,
      orElse: () => FolderPermission.view,
    );
  }

  String get displayName {
    switch (this) {
      case FolderPermission.view:
        return 'Solo ver';
      case FolderPermission.download:
        return 'Ver y descargar';
      case FolderPermission.upload:
        return 'Ver, descargar y subir';
      case FolderPermission.full:
        return 'Control total';
    }
  }

  String get description {
    switch (this) {
      case FolderPermission.view:
        return 'Puede ver archivos pero no descargarlos';
      case FolderPermission.download:
        return 'Puede ver y descargar archivos';
      case FolderPermission.upload:
        return 'Puede ver, descargar y subir archivos';
      case FolderPermission.full:
        return 'Puede ver, descargar, subir y eliminar archivos';
    }
  }
}

/// Modelo para una carpeta compartida activa
class FolderShare {
  const FolderShare({
    required this.id,
    required this.folderId,
    required this.ownerId,
    required this.sharedWithUserId,
    required this.permission,
    required this.inheritToSubfolders,
    required this.createdAt,
    this.acceptedAt,
    this.folderName,
    this.ownerEmail,
    this.sharedWithEmail,
  });

  factory FolderShare.fromMap(Map<String, dynamic> map) {
    return FolderShare(
      id: map['id'] as String,
      folderId: map['folder_id'] as String,
      ownerId: map['owner_id'] as String,
      sharedWithUserId: map['shared_with_user_id'] as String,
      permission: FolderPermission.fromString(map['permission'] as String),
      inheritToSubfolders: map['inherit_to_subfolders'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
      acceptedAt: map['accepted_at'] != null
          ? DateTime.parse(map['accepted_at'] as String)
          : null,
      folderName: map['folder_name'] as String?,
      ownerEmail: map['owner_email'] as String?,
      sharedWithEmail: map['shared_with_email'] as String?,
    );
  }

  final String id;
  final String folderId;
  final String ownerId;
  final String sharedWithUserId;
  final FolderPermission permission;
  final bool inheritToSubfolders;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final String? folderName;
  final String? ownerEmail;
  final String? sharedWithEmail;
}

/// Modelo para una invitación pendiente
class FolderInvitation {
  const FolderInvitation({
    required this.id,
    required this.folderId,
    required this.ownerId,
    required this.inviteeEmail,
    required this.token,
    required this.permission,
    required this.inheritToSubfolders,
    required this.expiresAt,
    required this.accepted,
    required this.revoked,
    required this.createdAt,
    this.message,
    this.folderName,
    this.ownerEmail,
  });

  factory FolderInvitation.fromMap(Map<String, dynamic> map) {
    return FolderInvitation(
      id: map['id'] as String,
      folderId: map['folder_id'] as String,
      ownerId: map['owner_id'] as String,
      inviteeEmail: map['invitee_email'] as String,
      token: map['token'] as String,
      permission: FolderPermission.fromString(map['permission'] as String),
      inheritToSubfolders: map['inherit_to_subfolders'] as bool? ?? true,
      expiresAt: DateTime.parse(map['expires_at'] as String),
      accepted: map['accepted'] as bool? ?? false,
      revoked: map['revoked'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
      message: map['message'] as String?,
      folderName: map['folder_name'] as String?,
      ownerEmail: map['owner_email'] as String?,
    );
  }

  final String id;
  final String folderId;
  final String ownerId;
  final String inviteeEmail;
  final String token;
  final FolderPermission permission;
  final bool inheritToSubfolders;
  final DateTime expiresAt;
  final bool accepted;
  final bool revoked;
  final DateTime createdAt;
  final String? message;
  final String? folderName;
  final String? ownerEmail;

  bool get isValid =>
      !accepted && !revoked && expiresAt.isAfter(DateTime.now());
}

/// Resultado al crear una invitación
class CreateInvitationResult {
  const CreateInvitationResult({
    required this.invitationId,
    required this.token,
    required this.expiresAt,
  });

  final String invitationId;
  final String token;
  final DateTime expiresAt;
}

/// Resultado al aceptar una invitación
class AcceptInvitationResult {
  const AcceptInvitationResult({
    required this.folderShareId,
    required this.folderId,
    required this.folderName,
    required this.permission,
  });

  final String folderShareId;
  final String folderId;
  final String folderName;
  final FolderPermission permission;
}

/// Información de acceso a una carpeta
class FolderAccessInfo {
  const FolderAccessInfo({
    required this.hasAccess,
    required this.isOwner,
    this.permission,
  });

  final bool hasAccess;
  final bool isOwner;
  final FolderPermission? permission;

  bool get canView => hasAccess;
  bool get canDownload =>
      permission == FolderPermission.download ||
      permission == FolderPermission.upload ||
      permission == FolderPermission.full ||
      isOwner;
  bool get canUpload =>
      permission == FolderPermission.upload ||
      permission == FolderPermission.full ||
      isOwner;
  bool get canDelete => permission == FolderPermission.full || isOwner;
}

/// Repositorio para gestionar carpetas compartidas
class FolderSharingRepository {
  FolderSharingRepository(this._supabase);

  final SupabaseClient _supabase;

  /// Crear una invitación para compartir una carpeta
  Future<CreateInvitationResult> createInvitation({
    required String folderId,
    required String inviteeEmail,
    required FolderPermission permission,
    bool inheritToSubfolders = true,
    String? message,
    int daysValid = 7,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final response = await _supabase.rpc(
      'create_folder_invitation',
      params: {
        'p_folder_id': folderId,
        'p_owner_id': userId,
        'p_invitee_email': inviteeEmail.trim().toLowerCase(),
        'p_permission': permission.value,
        'p_inherit_to_subfolders': inheritToSubfolders,
        'p_message': message,
        'p_days_valid': daysValid,
      },
    );

    if (response == null || (response as List).isEmpty) {
      throw Exception('Failed to create invitation');
    }

    final result = (response as List).first;
    return CreateInvitationResult(
      invitationId: result['invitation_id'] as String,
      token: result['token'] as String,
      expiresAt: DateTime.parse(result['expires_at'] as String),
    );
  }

  /// Aceptar una invitación usando el token
  Future<AcceptInvitationResult> acceptInvitation({
    required String token,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('User not authenticated');
    }

    final response = await _supabase.rpc(
      'accept_folder_invitation',
      params: {
        'p_token': token,
        'p_user_id': user.id,
        'p_user_email': user.email!,
      },
    );

    if (response == null || (response as List).isEmpty) {
      throw Exception('Failed to accept invitation');
    }

    final result = (response as List).first;
    return AcceptInvitationResult(
      folderShareId: result['folder_share_id'] as String,
      folderId: result['folder_id'] as String,
      folderName: result['folder_name'] as String,
      permission: FolderPermission.fromString(result['permission'] as String),
    );
  }

  /// Obtener carpetas compartidas con el usuario actual
  Future<List<FolderShare>> getSharedFolders() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final response = await _supabase.rpc(
      'get_shared_folders_for_user',
      params: {'p_user_id': userId},
    ) as List<dynamic>;

    return response.map((e) {
      final map = e as Map<String, dynamic>;
      return FolderShare(
        id: '', // No disponible en este query
        folderId: map['folder_id'] as String,
        ownerId: map['owner_id'] as String,
        sharedWithUserId: userId,
        permission: FolderPermission.fromString(map['permission'] as String),
        inheritToSubfolders: true,
        createdAt: DateTime.parse(map['shared_at'] as String),
        folderName: map['folder_name'] as String,
        ownerEmail: map['owner_email'] as String,
      );
    }).toList();
  }

  /// Verificar acceso de usuario a una carpeta
  Future<FolderAccessInfo> checkAccess(String folderId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return const FolderAccessInfo(
        hasAccess: false,
        isOwner: false,
      );
    }

    final response = await _supabase.rpc(
      'user_has_folder_access',
      params: {
        'p_user_id': userId,
        'p_folder_id': folderId,
      },
    );

    if (response == null || (response as List).isEmpty) {
      return const FolderAccessInfo(
        hasAccess: false,
        isOwner: false,
      );
    }

    final result = (response as List).first;
    return FolderAccessInfo(
      hasAccess: result['has_access'] as bool? ?? false,
      isOwner: result['is_owner'] as bool? ?? false,
      permission: result['permission'] != null
          ? FolderPermission.fromString(result['permission'] as String)
          : null,
    );
  }

  /// Revocar acceso a una carpeta compartida
  Future<bool> revokeAccess({
    required String folderId,
    required String sharedWithUserId,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final response = await _supabase.rpc(
      'revoke_folder_share',
      params: {
        'p_folder_id': folderId,
        'p_owner_id': userId,
        'p_shared_with_user_id': sharedWithUserId,
      },
    );

    return response as bool? ?? false;
  }

  /// Obtener invitaciones pendientes para una carpeta
  Future<List<FolderInvitation>> getInvitationsForFolder(
    String folderId,
  ) async {
    final response = await _supabase
        .from('folder_invitations')
        .select('*')
        .eq('folder_id', folderId)
        .eq('accepted', false)
        .eq('revoked', false)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((e) => FolderInvitation.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Obtener usuarios con acceso a una carpeta
  Future<List<FolderShare>> getUsersWithAccess(String folderId) async {
    final response = await _supabase
        .from('folder_shares')
        .select('*, users!shared_with_user_id(email)')
        .eq('folder_id', folderId)
        .order('created_at', ascending: false);

    return (response as List<dynamic>).map((e) {
      final map = e as Map<String, dynamic>;
      return FolderShare.fromMap({
        ...map,
        'shared_with_email': map['users']?['email'],
      });
    }).toList();
  }

  /// Revocar una invitación pendiente
  Future<void> revokeInvitation(String invitationId) async {
    await _supabase
        .from('folder_invitations')
        .update({'revoked': true}).eq('id', invitationId);
  }
}
