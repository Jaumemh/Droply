import 'package:droply/features/dashboard/data/file_browser_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ShareAccessResult {
  const ShareAccessResult({
    required this.shareId,
    required this.token,
    required this.fileId,
    required this.fileName,
    required this.mimeType,
    required this.storagePath,
    required this.expiresAt,
    required this.signedUrl,
    required this.isImage,
    required this.isPdf,
    required this.sizeBytes,
  });

  final String shareId;
  final String token;
  final String fileId;
  final String fileName;
  final String mimeType;
  final String storagePath;
  final DateTime expiresAt;
  final String? signedUrl;
  final bool isImage;
  final bool isPdf;
  final int sizeBytes;
}

class AcceptedShareResult {
  const AcceptedShareResult({
    required this.shareId,
    required this.fileId,
    required this.fileName,
    required this.mimeType,
    required this.storagePath,
    required this.expiresAt,
    required this.sizeBytes,
  });

  final String shareId;
  final String fileId;
  final String fileName;
  final String mimeType;
  final String storagePath;
  final DateTime expiresAt;
  final int sizeBytes;
}

class ShareLinkResult {
  const ShareLinkResult({
    required this.shareId,
    required this.token,
    required this.expiresAt,
  });

  final String shareId;
  final String token;
  final DateTime expiresAt;
}

class ShareRepository {
  ShareRepository(this._client);

  final SupabaseClient _client;

  Map<String, dynamic> _firstRow(dynamic response) {
    if (response is List && response.isNotEmpty) {
      return Map<String, dynamic>.from(response.first as Map);
    }
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    throw StateError('Unexpected RPC response format.');
  }

  Future<ShareLinkResult> createShare({
    required String fileId,
    String? note,
  }) async {
    final response = await _client.rpc(
      'create_share_link',
      params: {
        'p_file_id': fileId,
        'p_note': note,
      },
    );

    final map = _firstRow(response);
    try {
      await logEvent(
        action: 'SHARE_CREATE',
        fileId: fileId,
        shareId: map['id'] as String,
        userAgent: 'flutter',
        ipClient: null,
      );
    } on Object {
      // El enlace ya esta creado; un fallo de auditoria no debe bloquearlo.
    }

    return ShareLinkResult(
      shareId: map['id'] as String,
      token: map['token'] as String,
      expiresAt: DateTime.parse(map['expires_at'] as String),
    );
  }

  Future<void> logEvent({
    required String action,
    required String fileId,
    String? shareId,
    String? userAgent,
    String? ipClient,
  }) async {
    await _client.from('events').insert({
      'user_id': _client.auth.currentUser?.id,
      'file_id': fileId,
      'share_id': shareId,
      'action': action,
      'target_type': 'file',
      'ip_client': ipClient,
      'user_agent': userAgent,
      'metadata': <String, dynamic>{},
    });
  }

  Future<ShareAccessResult> resolveShare({
    required String token,
    required String action,
    String? userAgent,
    String? ipClient,
  }) async {
    final response = await _client.rpc(
      'resolve_share_token',
      params: {
        'p_token': token,
        'p_action': action,
        'p_user_agent': userAgent,
        'p_ip_client': ipClient,
      },
    );

    final map = _firstRow(response);
    String? signedUrl;
    try {
      signedUrl = await _client.storage
          .from('droply-files')
          .createSignedUrl(map['storage_path'] as String, 300);
    } on Object {
      signedUrl = null;
    }

    return ShareAccessResult(
      shareId: map['share_id'] as String,
      token: token,
      fileId: map['file_id'] as String,
      fileName: map['file_name'] as String,
      mimeType: map['mime_type'] as String,
      storagePath: map['storage_path'] as String,
      expiresAt: DateTime.parse(map['expires_at'] as String),
      signedUrl: signedUrl,
      isImage: map['is_image'] as bool? ?? false,
      isPdf: map['is_pdf'] as bool? ?? false,
      sizeBytes: (map['size_bytes'] as num).toInt(),
    );
  }

  Future<AcceptedShareResult> acceptShare({
    required String token,
    String? userAgent,
    String? ipClient,
  }) async {
    final response = await _client.rpc(
      'accept_share_token',
      params: {
        'p_token': token,
        'p_user_agent': userAgent,
        'p_ip_client': ipClient,
      },
    );

    final map = _firstRow(response);
    return AcceptedShareResult(
      shareId: map['share_id'] as String,
      fileId: map['file_id'] as String,
      fileName: map['file_name'] as String,
      mimeType: map['mime_type'] as String,
      storagePath: map['storage_path'] as String,
      expiresAt: DateTime.parse(map['expires_at'] as String),
      sizeBytes: (map['size_bytes'] as num).toInt(),
    );
  }
}
