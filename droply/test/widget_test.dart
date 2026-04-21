import 'dart:async';

import 'package:droply/app/app.dart';
import 'package:droply/features/auth/auth_controller.dart';
import 'package:droply/features/auth/auth_repository.dart';
import 'package:droply/features/dashboard/data/file_browser_repository.dart';
import 'package:droply/features/dashboard/presentation/dashboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('shows OTP login flow in two steps', (tester) async {
    final repository = FakeAuthRepository();
    final controller = AuthController(repository: repository);

    await tester.pumpWidget(
      DroplyApp(authController: controller, dashboardController: FakeDashboardController()),
    );
    await tester.pump();

    expect(
      find.text('Paso 1 de 2. Introduce tu email para recibir un codigo OTP.'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField).first, 'jaume@example.com');
    await tester.tap(find.text('Enviar codigo'));
    await tester.pump();

    expect(find.textContaining('Paso 2 de 2.'), findsOneWidget);
    expect(repository.lastOtpEmail, 'jaume@example.com');
  });

  testWidgets('shows authenticated dashboard with folder and file shell', (tester) async {
    final repository = FakeAuthRepository.authenticated();
    final controller = AuthController(repository: repository);

    await tester.pumpWidget(
      DroplyApp(authController: controller, dashboardController: FakeDashboardController()),
    );
    await tester.pump();

    expect(find.text('Tauler'), findsOneWidget);
    expect(find.text('Documentos'), findsOneWidget);
    expect(find.text('informe.pdf'), findsOneWidget);
  });
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    Session? session,
    User? user,
  })  : _currentSession = session,
        _currentUser = user;

  factory FakeAuthRepository.authenticated() {
    final user = User.fromJson({
      'id': '90f7fa61-40f2-4fb8-a88d-7fc3ff9cb251',
      'aud': 'authenticated',
      'role': 'authenticated',
      'email': 'tester@example.com',
      'email_confirmed_at': '2026-04-16T12:00:00.000Z',
      'phone': '',
      'app_metadata': <String, dynamic>{},
      'user_metadata': <String, dynamic>{},
      'identities': <dynamic>[],
      'created_at': '2026-04-16T12:00:00.000Z',
      'updated_at': '2026-04-16T12:00:00.000Z',
    })!;

    final session = Session.fromJson({
      'access_token': 'access-token',
      'token_type': 'bearer',
      'expires_in': 3600,
      'expires_at': 1999999999,
      'refresh_token': 'refresh-token',
      'user': user.toJson(),
    });

    return FakeAuthRepository(
      session: session,
      user: user,
    );
  }

  final StreamController<AuthState> _controller =
      StreamController<AuthState>.broadcast();

  Session? _currentSession;
  User? _currentUser;
  String? lastOtpEmail;

  @override
  Session? get currentSession => _currentSession;

  @override
  User? get currentUser => _currentUser;

  @override
  Stream<AuthState> get onAuthStateChange => _controller.stream;

  @override
  Future<void> sendOtp(String email) async {
    lastOtpEmail = email;
  }

  @override
  Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
  }) async {
    _currentUser ??= User.fromJson({
      'id': '90f7fa61-40f2-4fb8-a88d-7fc3ff9cb251',
      'aud': 'authenticated',
      'role': 'authenticated',
      'email': email,
      'email_confirmed_at': '2026-04-16T12:00:00.000Z',
      'phone': '',
      'app_metadata': <String, dynamic>{},
      'user_metadata': <String, dynamic>{},
      'identities': <dynamic>[],
      'created_at': '2026-04-16T12:00:00.000Z',
      'updated_at': '2026-04-16T12:00:00.000Z',
    })!;
    _currentSession = Session.fromJson({
      'access_token': 'access-token',
      'token_type': 'bearer',
      'expires_in': 3600,
      'expires_at': 1999999999,
      'refresh_token': 'refresh-token',
      'user': _currentUser!.toJson(),
    });
    return AuthResponse(
      session: _currentSession,
      user: _currentUser,
    );
  }

  @override
  Future<void> signOut() async {
    _currentSession = null;
    _currentUser = null;
    _controller.add(const AuthState(AuthChangeEvent.signedOut, null));
  }
}

class FakeDashboardController extends DashboardController {
  FakeDashboardController()
      : super(repository: _FakeFileBrowserRepository());
}

class _FakeFileBrowserRepository extends FileBrowserRepositoryBase {
  @override
  Future<void> createFile({
    String? folderId,
    required String name,
    required String mimeType,
    required int sizeBytes,
    String? extension,
    required String storagePath,
  }) async {}

  @override
  Future<void> createFolder({
    required String name,
    String? parentId,
  }) async {}

  @override
  Future<void> deleteFile({required String fileId}) async {}

  @override
  Future<void> deleteFolder({required String folderId}) async {}

  @override
  Future<FileBrowserSnapshot> load({String? folderId}) async {
    return FileBrowserSnapshot(
      currentFolderId: folderId,
      folderPath: const [
        FolderItem(
          id: 'folder-root',
          ownerId: 'owner-id',
          name: 'Documentos',
          parentId: null,
          createdAt: DateTime.utc(2026, 4, 21),
        ),
      ],
      folders: const [
        FolderItem(
          id: 'folder-root',
          ownerId: 'owner-id',
          name: 'Documentos',
          parentId: null,
          createdAt: DateTime.utc(2026, 4, 21),
        ),
      ],
      files: const [
        FileItem(
          id: 'file-1',
          ownerId: 'owner-id',
          folderId: null,
          name: 'informe.pdf',
          extension: 'pdf',
          sizeBytes: 1024,
          mimeType: 'application/pdf',
          storagePath: 'owner-id/informe.pdf',
          version: 1,
          isDeleted: false,
          createdAt: DateTime.utc(2026, 4, 21),
        ),
      ],
    );
  }

  @override
  Future<List<FolderItem>> loadFolderPath(String? folderId) async {
    return const [];
  }

  @override
  Future<void> renameFile({
    required String fileId,
    required String newName,
  }) async {}

  @override
  Future<void> renameFolder({
    required String folderId,
    required String newName,
  }) async {}
}
