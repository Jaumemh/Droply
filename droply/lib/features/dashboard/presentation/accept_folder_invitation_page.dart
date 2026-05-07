import 'package:droply/features/dashboard/data/folder_sharing_repository.dart';
import 'package:flutter/material.dart';
import 'package:droply/core/platform_utils.dart' as platform_utils;
import 'package:supabase_flutter/supabase_flutter.dart';

class AcceptFolderInvitationPage extends StatefulWidget {
  const AcceptFolderInvitationPage({
    super.key,
    required this.token,
  });

  final String token;

  @override
  State<AcceptFolderInvitationPage> createState() =>
      _AcceptFolderInvitationPageState();
}

class _AcceptFolderInvitationPageState extends State<AcceptFolderInvitationPage> {
  final _supabase = Supabase.instance.client;
  late final FolderSharingRepository _repository;
  bool _isLoading = true;
  bool _isAccepting = false;
  String? _errorMessage;
  FolderInvitation? _invitation;
  String? _folderName;
  String? _ownerEmail;

  @override
  void initState() {
    super.initState();
    _repository = FolderSharingRepository(_supabase);
    _loadInvitation();
  }

  Future<void> _loadInvitation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _supabase.rpc(
        'get_folder_invitation_by_token',
        params: {'p_token': widget.token},
      );

      final data = response is List
          ? (response.isNotEmpty ? response.first as Map<String, dynamic> : null)
          : null;

      if (data == null) {
        setState(() {
          _errorMessage = 'Invitacion no encontrada';
          _isLoading = false;
        });
        return;
      }

      final invitation = FolderInvitation.fromMap(data);

      if (!invitation.isValid) {
        if (invitation.revoked) {
          _errorMessage = 'Esta invitacion ha sido revocada';
        } else if (invitation.accepted) {
          _errorMessage = 'Esta invitacion ya ha sido aceptada';
        } else if (invitation.expiresAt.isBefore(DateTime.now())) {
          _errorMessage = 'Esta invitacion ha expirado';
        }
      }

      setState(() {
        _invitation = invitation;
        _folderName = data['folder_name'] as String?;
        _ownerEmail = data['owner_email'] as String?;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar la invitacion: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptInvitation() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _showLoginDialog();
      return;
    }

    setState(() => _isAccepting = true);

    try {
      final result = await _repository.acceptInvitation(token: widget.token);
      platform_utils.sessionStorageRemove('droply_pending_invitation_token');
      platform_utils.sessionStorageSet('droply_accepted_folder_id', result.folderId);
      if (!mounted) return;
      platform_utils.locationAssign(Uri.base.origin);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error al aceptar la invitacion: $e';
        _isAccepting = false;
      });
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.lock_open_rounded,
                color: Color(0xFF0EA5E9),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Inicia sesion para continuar',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Tu invitacion ya esta lista. Solo necesitas entrar con tu cuenta para aceptarla y llevar esta carpeta a tu espacio Droply.',
          style: TextStyle(
            fontSize: 15,
            height: 1.45,
            color: Color(0xFF475569),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {
              platform_utils.sessionStorageSet('droply_pending_invitation_token', widget.token);
              platform_utils.locationAssign(Uri.base.origin);
            },
            child: const Text(
              'Ir a login',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  String _formatExpiryDate(DateTime date) {
    final months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}, '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              margin: const EdgeInsets.all(24),
              elevation: 8,
              shadowColor: Colors.black.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(64.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _buildContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null) {
      return _buildError();
    }

    if (_invitation == null) {
      return _buildError();
    }

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.folder_shared_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Invitacion a Carpeta',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Droply',
            style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.folder, size: 32, color: Color(0xFF10B981)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _folderName ?? 'Carpeta compartida',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                _buildInfoRow('Compartido por:', _ownerEmail ?? 'Usuario'),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Permisos:',
                  _invitation!.permission.displayName,
                  valueColor: const Color(0xFF10B981),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Valido hasta:',
                  _formatExpiryDate(_invitation!.expiresAt),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isAccepting ? null : _acceptInvitation,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFD1D5DB),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isAccepting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Aceptar Invitacion',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              border: Border.all(color: const Color(0xFF3B82F6)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFF1E40AF),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _supabase.auth.currentUser != null
                        ? 'Al aceptar, la carpeta aparecera en tu dashboard.'
                        : 'Necesitas iniciar sesion para aceptar esta invitacion.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1E40AF),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: valueColor ?? const Color(0xFF111827),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.error_outline,
              size: 40,
              color: Color(0xFFEF4444),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Invitacion no valida',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage ?? 'La invitacion no existe o no es valida',
            style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0EA5E9),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Ir al inicio'),
            ),
          ),
        ],
      ),
    );
  }
}
