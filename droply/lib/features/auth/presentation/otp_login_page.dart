import 'dart:math' as math;

import 'package:droply/features/auth/auth_controller.dart';
import 'package:droply/features/auth/auth_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OtpLoginPage extends StatefulWidget {
  const OtpLoginPage({super.key, required this.controller});

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

    if (_emailController.text != controller.email) {
      _emailController.value = TextEditingValue(
        text: controller.email,
        selection: TextSelection.collapsed(offset: controller.email.length),
      );
    }

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8FDFF), Color(0xFFE8F7FF), Color(0xFFF6FBFF)],
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(
              child: CustomPaint(painter: _LoginBackgroundPainter()),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 920;
                  final padding = isWide ? 56.0 : 20.0;

                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(padding, 20, padding, 28),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 48,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1120),
                          child: Column(
                            children: [
                              const _LoginTopBar(),
                              SizedBox(height: isWide ? 48 : 26),
                              AnimatedBuilder(
                                animation: controller,
                                builder: (context, _) {
                                  final currentIsOtpStep =
                                      controller.status == AuthStatus.otpSent;

                                  if (isWide) {
                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          flex: 10,
                                          child: _LoginBrandPanel(
                                            currentIsOtpStep: currentIsOtpStep,
                                          ),
                                        ),
                                        const SizedBox(width: 44),
                                        Expanded(
                                          flex: 9,
                                          child: _LoginFormPanel(
                                            controller: controller,
                                            emailController: _emailController,
                                            otpController: _otpController,
                                            currentIsOtpStep: currentIsOtpStep,
                                          ),
                                        ),
                                      ],
                                    );
                                  }

                                  return Column(
                                    children: [
                                      _LoginBrandPanel(
                                        currentIsOtpStep: currentIsOtpStep,
                                        compact: true,
                                      ),
                                      const SizedBox(height: 22),
                                      _LoginFormPanel(
                                        controller: controller,
                                        emailController: _emailController,
                                        otpController: _otpController,
                                        currentIsOtpStep: currentIsOtpStep,
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginTopBar extends StatelessWidget {
  const _LoginTopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 44,
          height: 44,
          child: CustomPaint(painter: _DroplyLogoPainter()),
        ),
        const SizedBox(width: 12),
        Text(
          'Droply',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.74),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFD6EAF5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.shield_rounded,
                color: Color(0xFF0EA5E9),
                size: 18,
              ),
              const SizedBox(width: 7),
              Text(
                'Acceso seguro',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF0369A1),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoginBrandPanel extends StatelessWidget {
  const _LoginBrandPanel({
    required this.currentIsOtpStep,
    this.compact = false,
  });

  final bool currentIsOtpStep;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: compact ? 280 : 520),
      padding: EdgeInsets.all(compact ? 24 : 34),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.66),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFD2ECF8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.12),
            blurRadius: 36,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: const CustomPaint(painter: _LoginGridPainter()),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _StepBadge(
                          text: currentIsOtpStep
                              ? 'Paso 2 de 2'
                              : 'Paso 1 de 2',
                        ),
                        const SizedBox(height: 18),
                        Text(
                          currentIsOtpStep
                              ? 'Verifica tu codigo'
                              : 'Entra a tu espacio Droply',
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: const Color(0xFF0F172A),
                            fontWeight: FontWeight.w900,
                            height: 1.02,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          currentIsOtpStep
                              ? 'Confirma el codigo enviado a tu email y abre tu panel personal.'
                              : 'Accede con tu email para gestionar, previsualizar y compartir tus archivos.',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: const Color(0xFF475569),
                            height: 1.45,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(width: 28),
                    const SizedBox(
                      width: 150,
                      height: 150,
                      child: CustomPaint(painter: _DroplyLogoPainter()),
                    ),
                  ],
                ],
              ),
              if (compact) ...[
                const SizedBox(height: 24),
                const Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: 150,
                    height: 150,
                    child: CustomPaint(painter: _DroplyLogoPainter()),
                  ),
                ),
              ],
              SizedBox(height: compact ? 28 : 96),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: const [
                  _FeatureChip(
                    icon: Icons.cloud_done_rounded,
                    label: 'Archivos en la nube',
                  ),
                  _FeatureChip(
                    icon: Icons.link_rounded,
                    label: 'Enlaces compartidos',
                  ),
                  _FeatureChip(
                    icon: Icons.visibility_rounded,
                    label: 'Vista previa',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoginFormPanel extends StatelessWidget {
  const _LoginFormPanel({
    required this.controller,
    required this.emailController,
    required this.otpController,
    required this.currentIsOtpStep,
  });

  final AuthController controller;
  final TextEditingController emailController;
  final TextEditingController otpController;
  final bool currentIsOtpStep;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFDCECF5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.10),
            blurRadius: 34,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: AutofillGroup(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F8FC),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    currentIsOtpStep
                        ? Icons.mark_email_read_rounded
                        : Icons.mail_lock_rounded,
                    color: const Color(0xFF0EA5E9),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentIsOtpStep ? 'Codigo OTP' : 'Iniciar sesion',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: const Color(0xFF0F172A),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentIsOtpStep
                            ? 'Email confirmado: ${controller.email}'
                            : 'Recibiras un codigo de un solo uso.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: currentIsOtpStep
                  ? _OtpStep(
                      key: const ValueKey('otp-step'),
                      controller: controller,
                      emailController: emailController,
                      otpController: otpController,
                    )
                  : _EmailStep(
                      key: const ValueKey('email-step'),
                      controller: controller,
                      emailController: emailController,
                    ),
            ),
            if (controller.errorMessage != null) ...[
              const SizedBox(height: 18),
              _MessageBanner(
                icon: Icons.error_rounded,
                backgroundColor: const Color(0xFFFFE8E8),
                foregroundColor: const Color(0xFFB42318),
                message: controller.errorMessage!,
              ),
            ],
            if (controller.infoMessage != null) ...[
              const SizedBox(height: 14),
              _MessageBanner(
                icon: Icons.check_circle_rounded,
                backgroundColor: const Color(0xFFE7F8FE),
                foregroundColor: const Color(0xFF0369A1),
                message: controller.infoMessage!,
              ),
            ],
            const SizedBox(height: 20),
            const _LoginTrustRow(),
          ],
        ),
      ),
    );
  }
}

class _EmailStep extends StatelessWidget {
  const _EmailStep({
    super.key,
    required this.controller,
    required this.emailController,
  });

  final AuthController controller;
  final TextEditingController emailController;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          enabled: !controller.isBusy,
          decoration: _inputDecoration(
            label: 'Email',
            hint: 'tu@email.com',
            icon: Icons.alternate_email_rounded,
          ),
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => controller.sendOtp(emailController.text),
        ),
        const SizedBox(height: 18),
        _PrimaryLoginButton(
          icon: Icons.arrow_forward_rounded,
          label: controller.isBusy ? 'Enviando...' : 'Enviar codigo',
          isBusy: controller.isBusy,
          onPressed: controller.isBusy
              ? null
              : () => controller.sendOtp(emailController.text),
        ),
      ],
    );
  }
}

class _OtpStep extends StatelessWidget {
  const _OtpStep({
    super.key,
    required this.controller,
    required this.emailController,
    required this.otpController,
  });

  final AuthController controller;
  final TextEditingController emailController;
  final TextEditingController otpController;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: emailController,
          enabled: false,
          decoration: _inputDecoration(
            label: 'Email',
            hint: '',
            icon: Icons.alternate_email_rounded,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: otpController,
          keyboardType: TextInputType.number,
          enabled: !controller.isBusy,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          decoration: _inputDecoration(
            label: 'Codigo OTP',
            hint: '123456',
            icon: Icons.password_rounded,
          ),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => controller.verifyOtp(otpController.text),
        ),
        const SizedBox(height: 18),
        _PrimaryLoginButton(
          icon: Icons.login_rounded,
          label: controller.isBusy ? 'Verificando...' : 'Verificar codigo',
          isBusy: controller.isBusy,
          onPressed: controller.isBusy
              ? null
              : () => controller.verifyOtp(otpController.text),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            TextButton.icon(
              onPressed: controller.isBusy ? null : controller.restartLogin,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Cambiar email'),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: controller.canResendOtp
                  ? () => controller.resendOtp()
                  : null,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                controller.canResendOtp
                    ? 'Reenviar'
                    : '${controller.resendCooldownRemaining}s',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PrimaryLoginButton extends StatelessWidget {
  const _PrimaryLoginButton({
    required this.icon,
    required this.label,
    required this.isBusy,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool isBusy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF0EA5E9),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFB7DDF0),
          disabledForegroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        icon: isBusy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.3,
                  color: Colors.white,
                ),
              )
            : Icon(icon),
        label: Text(label),
      ),
    );
  }
}

class _LoginTrustRow extends StatelessWidget {
  const _LoginTrustRow();

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: const Color(0xFF64748B),
      fontWeight: FontWeight.w700,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2EDF4)),
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 8,
        children: [
          _MiniTrustItem(
            icon: Icons.key_rounded,
            text: 'OTP',
            textStyle: textStyle,
          ),
          _MiniTrustItem(
            icon: Icons.timer_rounded,
            text: 'Acceso rapido',
            textStyle: textStyle,
          ),
          _MiniTrustItem(
            icon: Icons.verified_user_rounded,
            text: 'Sesion protegida',
            textStyle: textStyle,
          ),
        ],
      ),
    );
  }
}

class _MiniTrustItem extends StatelessWidget {
  const _MiniTrustItem({
    required this.icon,
    required this.text,
    required this.textStyle,
  });

  final IconData icon;
  final String text;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: const Color(0xFF14B8A6)),
        const SizedBox(width: 6),
        Text(text, style: textStyle),
      ],
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F8FC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFB8EEF8)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: const Color(0xFF0369A1),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD6EAF5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF0EA5E9)),
          const SizedBox(width: 7),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: const Color(0xFF334155),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.message,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foregroundColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration({
  required String label,
  required String hint,
  required IconData icon,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: Icon(icon),
    filled: true,
    fillColor: const Color(0xFFF8FBFD),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFDCECF5)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFDCECF5)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 1.6),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFE2EDF4)),
    ),
  );
}

class _DroplyLogoPainter extends CustomPainter {
  const _DroplyLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final strokeWidth = size.shortestSide * 0.078;
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF00B8D9), Color(0xFF0877D9)],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final drop = Path()
      ..moveTo(size.width * 0.5, size.height * 0.09)
      ..cubicTo(
        size.width * 0.68,
        size.height * 0.33,
        size.width * 0.83,
        size.height * 0.42,
        size.width * 0.86,
        size.height * 0.63,
      )
      ..cubicTo(
        size.width * 0.90,
        size.height * 0.86,
        size.width * 0.70,
        size.height * 0.96,
        size.width * 0.50,
        size.height * 0.96,
      )
      ..cubicTo(
        size.width * 0.30,
        size.height * 0.96,
        size.width * 0.10,
        size.height * 0.86,
        size.width * 0.14,
        size.height * 0.63,
      )
      ..cubicTo(
        size.width * 0.17,
        size.height * 0.42,
        size.width * 0.32,
        size.height * 0.33,
        size.width * 0.5,
        size.height * 0.09,
      );

    final arrow = Path()
      ..moveTo(size.width * 0.50, size.height * 0.31)
      ..lineTo(size.width * 0.50, size.height * 0.73)
      ..moveTo(size.width * 0.30, size.height * 0.58)
      ..lineTo(size.width * 0.50, size.height * 0.78)
      ..lineTo(size.width * 0.70, size.height * 0.58);

    final arrowHead = Path()
      ..moveTo(size.width * 0.50, size.height * 0.31)
      ..lineTo(size.width * 0.59, size.height * 0.43)
      ..lineTo(size.width * 0.59, size.height * 0.62)
      ..moveTo(size.width * 0.50, size.height * 0.31)
      ..lineTo(size.width * 0.41, size.height * 0.43)
      ..lineTo(size.width * 0.41, size.height * 0.62);

    canvas.drawPath(drop, paint);
    canvas.drawPath(arrow, paint);
    canvas.drawPath(arrowHead, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LoginBackgroundPainter extends CustomPainter {
  const _LoginBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final wavePaint = Paint()
      ..color = const Color(0xFF0EA5E9).withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var i = 0; i < 5; i++) {
      final y = size.height * (0.16 + i * 0.16);
      final path = Path()..moveTo(-40, y);
      for (var x = -40.0; x <= size.width + 40; x += 32) {
        path.lineTo(x, y + math.sin((x / 82) + i) * (10 + i));
      }
      canvas.drawPath(path, wavePaint);
    }

    final washPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [Color(0x3322D3EE), Color(0x0014B8A6)],
      ).createShader(Offset.zero & size);

    final bottom = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.74)
      ..cubicTo(
        size.width * 0.24,
        size.height * 0.62,
        size.width * 0.60,
        size.height * 0.96,
        size.width,
        size.height * 0.70,
      )
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(bottom, washPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LoginGridPainter extends CustomPainter {
  const _LoginGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF94A3B8).withValues(alpha: 0.12)
      ..strokeWidth = 1;

    const step = 24.0;
    for (var x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.12, -0.15),
        radius: 0.82,
        colors: [
          const Color(0xFF22D3EE).withValues(alpha: 0.20),
          Colors.white.withValues(alpha: 0),
        ],
      ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
