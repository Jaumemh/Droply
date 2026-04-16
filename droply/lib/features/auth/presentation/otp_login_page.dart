import 'package:droply/features/auth/auth_controller.dart';
import 'package:droply/features/auth/auth_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OtpLoginPage extends StatefulWidget {
  const OtpLoginPage({
    super.key,
    required this.controller,
  });

  final AuthController controller;

  @override
  State<OtpLoginPage> createState() => _OtpLoginPageState();
}

class _OtpLoginPageState extends State<OtpLoginPage> {
  late final TextEditingController _emailController;
  late final TextEditingController _otpController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.controller.email);
    _otpController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final theme = Theme.of(context);

    if (_emailController.text != controller.email) {
      _emailController.value = TextEditingValue(
        text: controller.email,
        selection: TextSelection.collapsed(offset: controller.email.length),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: AnimatedBuilder(
                    animation: controller,
                    builder: (context, _) {
                      final currentIsOtpStep =
                          controller.status == AuthStatus.otpSent;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Entra en Droply',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            currentIsOtpStep
                                ? 'Paso 2 de 2. Introduce el codigo de 6 digitos que hemos enviado a ${controller.email}.'
                                : 'Paso 1 de 2. Introduce tu email para recibir un codigo OTP.',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (!currentIsOtpStep) ...[
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              enabled: !controller.isBusy,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                hintText: 'tu@email.com',
                                border: OutlineInputBorder(),
                              ),
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) =>
                                  controller.sendOtp(_emailController.text),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: controller.isBusy
                                    ? null
                                    : () => controller.sendOtp(_emailController.text),
                                child: Text(
                                  controller.isBusy ? 'Enviando...' : 'Enviar codigo',
                                ),
                              ),
                            ),
                          ] else ...[
                            TextField(
                              controller: _emailController,
                              enabled: false,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              enabled: !controller.isBusy,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Codigo OTP',
                                hintText: '123456',
                                border: OutlineInputBorder(),
                              ),
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) =>
                                  controller.verifyOtp(_otpController.text),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: controller.isBusy
                                    ? null
                                    : () => controller.verifyOtp(_otpController.text),
                                child: Text(
                                  controller.isBusy ? 'Verificando...' : 'Verificar codigo',
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: controller.isBusy ? null : controller.restartLogin,
                                  child: const Text('Cambiar email'),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: controller.canResendOtp
                                      ? () => controller.resendOtp()
                                      : null,
                                  child: Text(
                                    controller.canResendOtp
                                        ? 'Reenviar codigo'
                                        : 'Reenviar en ${controller.resendCooldownRemaining}s',
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (controller.errorMessage != null) ...[
                            const SizedBox(height: 16),
                            _MessageBanner(
                              backgroundColor: const Color(0xFFFEE2E2),
                              foregroundColor: const Color(0xFF991B1B),
                              message: controller.errorMessage!,
                            ),
                          ],
                          if (controller.infoMessage != null) ...[
                            const SizedBox(height: 12),
                            _MessageBanner(
                              backgroundColor: const Color(0xFFDBEAFE),
                              foregroundColor: const Color(0xFF1D4ED8),
                              message: controller.infoMessage!,
                            ),
                          ],
                          const SizedBox(height: 16),
                          Text(
                            'Objetivo UX: completar el acceso en menos de 30 segundos. Si no ves el email, revisa spam o promociones.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.message,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
