import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_repository.dart';
import 'auth_status.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required AuthRepository repository,
    this.resendCooldown = const Duration(seconds: 30),
  }) : _repository = repository;

  final AuthRepository _repository;
  final Duration resendCooldown;

  StreamSubscription<AuthState>? _authSubscription;
  Timer? _resendTimer;
  DateTime? _resendAvailableAt;

  AuthStatus _status = AuthStatus.unknown;
  bool _isBusy = false;
  String _email = '';
  String? _errorMessage;
  String? _infoMessage;
  User? _currentUser;

  AuthStatus get status => _status;
  bool get isBusy => _isBusy;
  String get email => _email;
  String? get errorMessage => _errorMessage;
  String? get infoMessage => _infoMessage;
  User? get currentUser => _currentUser;
  bool get canResendOtp => resendCooldownRemaining <= 0 && !_isBusy;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  int get resendCooldownRemaining {
    if (_resendAvailableAt == null) {
      return 0;
    }

    final difference = _resendAvailableAt!.difference(DateTime.now()).inSeconds;
    return difference > 0 ? difference : 0;
  }

  Future<void> initialize() async {
    _currentUser = _repository.currentUser;
    _status = _repository.currentSession == null
        ? AuthStatus.unauthenticated
        : AuthStatus.authenticated;
    notifyListeners();

    await _authSubscription?.cancel();
    _authSubscription = _repository.onAuthStateChange.listen(
      (authState) {
        _currentUser = authState.session?.user ?? _repository.currentUser;

        switch (authState.event) {
          case AuthChangeEvent.initialSession:
          case AuthChangeEvent.signedIn:
          case AuthChangeEvent.tokenRefreshed:
          case AuthChangeEvent.userUpdated:
            if (authState.session != null) {
              _status = AuthStatus.authenticated;
              _errorMessage = null;
              _infoMessage = null;
            }
            break;
          case AuthChangeEvent.signedOut:
          case AuthChangeEvent.userDeleted:
            _status = AuthStatus.unauthenticated;
            _currentUser = null;
            break;
          case AuthChangeEvent.passwordRecovery:
          case AuthChangeEvent.mfaChallengeVerified:
            // Not used in this sprint.
            break;
        }

        notifyListeners();
      },
      onError: (Object error) {
        _errorMessage = _readableError(error);
        notifyListeners();
      },
    );
  }

  Future<void> sendOtp(String rawEmail) async {
    final normalizedEmail = rawEmail.trim().toLowerCase();
    final validationError = _validateEmail(normalizedEmail);
    if (validationError != null) {
      _errorMessage = validationError;
      _infoMessage = null;
      notifyListeners();
      return;
    }

    await _runBusyAction(() async {
      await _repository.sendOtp(normalizedEmail);
      _email = normalizedEmail;
      _status = AuthStatus.otpSent;
      _errorMessage = null;
      _infoMessage = 'Codigo enviado. Revisa tu bandeja de entrada y spam.';
      _startResendCooldown();
    });
  }

  Future<void> resendOtp() async {
    if (_email.isEmpty || !canResendOtp) {
      return;
    }

    await sendOtp(_email);
  }

  Future<void> verifyOtp(String rawToken) async {
    final token = rawToken.trim();
    final validationError = _validateOtp(token);
    if (validationError != null) {
      _errorMessage = validationError;
      _infoMessage = null;
      notifyListeners();
      return;
    }

    await _runBusyAction(() async {
      final response = await _repository.verifyOtp(
        email: _email,
        token: token,
      );

      _currentUser =
          response.user ?? response.session?.user ?? _repository.currentUser;
      _status = response.session != null || _repository.currentSession != null
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated;
      _errorMessage = null;
      _infoMessage = 'Sesion iniciada correctamente.';
    });
  }

  void restartLogin() {
    _status = AuthStatus.unauthenticated;
    _email = '';
    _errorMessage = null;
    _infoMessage = null;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _runBusyAction(() async {
      await _repository.signOut();
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      _email = '';
      _errorMessage = null;
      _infoMessage = 'Sesion cerrada.';
    });
  }

  Future<void> _runBusyAction(Future<void> Function() action) async {
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
    } on AuthException catch (error) {
      _errorMessage = _readableError(error);
    } on Object catch (error) {
      _errorMessage = _readableError(error);
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  String? _validateEmail(String value) {
    if (value.isEmpty) {
      return 'Introduce tu email.';
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Introduce un email valido.';
    }

    return null;
  }

  String? _validateOtp(String value) {
    if (value.isEmpty) {
      return 'Introduce el codigo de 6 digitos.';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      return 'El codigo OTP debe tener 6 digitos.';
    }
    return null;
  }

  String _readableError(Object error) {
    final message = error.toString();
    if (message.contains('Token has expired')) {
      return 'El codigo ha caducado. Solicita uno nuevo.';
    }
    if (message.contains('invalid') || message.contains('Invalid')) {
      return 'El codigo o el email no son validos.';
    }
    if (message.contains('network') || message.contains('Network')) {
      return 'No se pudo conectar. Revisa tu conexion.';
    }
    return message.replaceFirst('Exception: ', '');
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    _resendAvailableAt = DateTime.now().add(resendCooldown);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendCooldownRemaining <= 0) {
        timer.cancel();
      }
      notifyListeners();
    });
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _resendTimer?.cancel();
    super.dispose();
  }
}
