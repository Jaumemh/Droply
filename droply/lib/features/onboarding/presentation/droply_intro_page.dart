import 'dart:math' as math;

import 'package:flutter/material.dart';

class DroplyIntroPage extends StatefulWidget {
  const DroplyIntroPage({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<DroplyIntroPage> createState() => _DroplyIntroPageState();
}

class _DroplyIntroPageState extends State<DroplyIntroPage> {
  static const _slides = [
    _IntroSlide(
      eyebrow: 'Nube personal',
      title: 'Droply',
      body:
          'Guarda tus documentos, imagenes y PDFs en un espacio claro, listo para encontrarlos cuando los necesites.',
      metric: '3 toques',
      metricLabel: 'para compartir',
      icon: Icons.cloud_upload_rounded,
      accent: Color(0xFF00B8D9),
      softAccent: Color(0xFFE0F8FC),
      highlights: ['Multiplataforma', 'Vista limpia', 'Archivos seguros'],
    ),
    _IntroSlide(
      eyebrow: 'Compartir facil',
      title: 'Envia archivos sin friccion',
      body:
          'Crea enlaces de acceso y decide que archivo llega a cada persona, sin adjuntos pesados ni reenvios interminables.',
      metric: 'link',
      metricLabel: 'por archivo',
      icon: Icons.ios_share_rounded,
      accent: Color(0xFF0EA5E9),
      softAccent: Color(0xFFE7F5FF),
      highlights: ['Enlaces compartidos', 'Acceso sencillo', 'Menos pasos'],
    ),
    _IntroSlide(
      eyebrow: 'Control y confianza',
      title: 'Gestiona quien accede',
      body:
          'Revisa actividad, controla permisos y mantente al tanto de cada movimiento importante dentro de tu espacio.',
      metric: '24/7',
      metricLabel: 'actividad visible',
      icon: Icons.verified_user_rounded,
      accent: Color(0xFF14B8A6),
      softAccent: Color(0xFFE6FFFA),
      highlights: ['Permisos', 'Historial', 'Previsualizacion'],
    ),
    _IntroSlide(
      eyebrow: 'Acceso rapido',
      title: 'Listo para entrar',
      body:
          'Inicia sesion con tu email y un codigo OTP para abrir tu espacio Droply de forma rapida y segura.',
      metric: 'OTP',
      metricLabel: 'sin contrasenas',
      icon: Icons.lock_open_rounded,
      accent: Color(0xFF2563EB),
      softAccent: Color(0xFFEFF6FF),
      highlights: ['Login por email', 'Codigo seguro', 'Panel personal'],
    ),
  ];

  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentPage];

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8FDFF), Color(0xFFEAF8FF), Color(0xFFF7FBFF)],
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(
              child: CustomPaint(painter: _DroplyBackgroundPainter()),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 860;
                  final horizontalPadding = isWide ? 64.0 : 24.0;

                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          20,
                          horizontalPadding,
                          24,
                        ),
                        child: Column(
                          children: [
                            _IntroHeader(
                              page: _currentPage,
                              total: _slides.length,
                            ),
                            const SizedBox(height: 20),
                            Expanded(
                              child: PageView.builder(
                                controller: _pageController,
                                itemCount: _slides.length,
                                onPageChanged: (index) {
                                  setState(() {
                                    _currentPage = index;
                                  });
                                },
                                itemBuilder: (context, index) {
                                  return _IntroSlideView(
                                    slide: _slides[index],
                                    isWide: isWide,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 18),
                            _IntroFooter(
                              slides: _slides,
                              currentPage: _currentPage,
                              accent: slide.accent,
                              onBack: _currentPage == 0 ? null : _goBack,
                              onNext: _goNext,
                              onIndicatorTap: _animateToPage,
                            ),
                          ],
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

  void _goBack() {
    _animateToPage(_currentPage - 1);
  }

  void _goNext() {
    if (_currentPage == _slides.length - 1) {
      widget.onFinished();
      return;
    }

    _animateToPage(_currentPage + 1);
  }

  void _animateToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }
}

class _IntroHeader extends StatelessWidget {
  const _IntroHeader({required this.page, required this.total});

  final int page;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 42,
          height: 42,
          child: CustomPaint(painter: _DroplyLogoPainter()),
        ),
        const SizedBox(width: 12),
        Text(
          'Droply',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFD9ECF7)),
          ),
          child: Text(
            '${page + 1} / $total',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: const Color(0xFF0369A1),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _IntroSlideView extends StatelessWidget {
  const _IntroSlideView({required this.slide, required this.isWide});

  final _IntroSlide slide;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final visual = _DroplyVisual(slide: slide);
    final copy = _SlideCopy(slide: slide);

    if (isWide) {
      return Row(
        children: [
          Expanded(flex: 11, child: visual),
          const SizedBox(width: 42),
          Expanded(flex: 9, child: copy),
        ],
      );
    }

    return Column(
      children: [
        Expanded(flex: 7, child: visual),
        const SizedBox(height: 22),
        Expanded(flex: 6, child: copy),
      ],
    );
  }
}

class _DroplyVisual extends StatelessWidget {
  const _DroplyVisual({required this.slide});

  final _IntroSlide slide;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFFD4EEF8)),
            boxShadow: [
              BoxShadow(
                color: slide.accent.withValues(alpha: 0.16),
                blurRadius: 40,
                offset: const Offset(0, 24),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: CustomPaint(
                    painter: _DroplyGridPainter(accent: slide.accent),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: FractionallySizedBox(
                  widthFactor: 0.58,
                  heightFactor: 0.58,
                  child: CustomPaint(
                    painter: _DroplyLogoPainter(accent: slide.accent),
                  ),
                ),
              ),
              Positioned(
                left: 26,
                top: 26,
                child: _FeaturePill(
                  icon: slide.icon,
                  text: slide.eyebrow,
                  accent: slide.accent,
                ),
              ),
              Positioned(
                right: 26,
                bottom: 28,
                child: _MetricBadge(slide: slide),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideCopy extends StatelessWidget {
  const _SlideCopy({required this.slide});

  final _IntroSlide slide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: slide.softAccent,
                  borderRadius: BorderRadius.circular(999),
                  border:
                      Border.all(color: slide.accent.withValues(alpha: 0.18)),
                ),
                child: Text(
                  slide.eyebrow,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: slide.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                slide.title,
                style: theme.textTheme.displaySmall?.copyWith(
                  color: const Color(0xFF0F172A),
                  fontWeight: FontWeight.w900,
                  height: 1.02,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                slide.body,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF475569),
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 26),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final item in slide.highlights)
                    _HighlightChip(text: item, accent: slide.accent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroFooter extends StatelessWidget {
  const _IntroFooter({
    required this.slides,
    required this.currentPage,
    required this.accent,
    required this.onNext,
    required this.onIndicatorTap,
    this.onBack,
  });

  final List<_IntroSlide> slides;
  final int currentPage;
  final Color accent;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final ValueChanged<int> onIndicatorTap;

  @override
  Widget build(BuildContext context) {
    final isLast = currentPage == slides.length - 1;

    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Anterior',
        ),
        const Spacer(),
        Row(
          children: [
            for (var index = 0; index < slides.length; index++)
              _PageDot(
                isActive: currentPage == index,
                color: slides[index].accent,
                onTap: () => onIndicatorTap(index),
              ),
          ],
        ),
        const Spacer(),
        FilledButton.icon(
          onPressed: onNext,
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          icon: Icon(
            isLast ? Icons.login_rounded : Icons.arrow_forward_rounded,
          ),
          label: Text(isLast ? 'Ir al login' : 'Siguiente'),
        ),
      ],
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({
    required this.icon,
    required this.text,
    required this.accent,
  });

  final IconData icon;
  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(width: 8),
          Text(
            text,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: const Color(0xFF0F172A),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricBadge extends StatelessWidget {
  const _MetricBadge({required this.slide});

  final _IntroSlide slide;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            slide.metric,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            slide.metricLabel,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: const Color(0xFFB6E7F5),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightChip extends StatelessWidget {
  const _HighlightChip({required this.text, required this.accent});

  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD6EAF5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 18, color: accent),
          const SizedBox(width: 7),
          Text(
            text,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: const Color(0xFF334155),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PageDot extends StatelessWidget {
  const _PageDot({
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: isActive ? 34 : 10,
        height: 10,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isActive ? color : const Color(0xFFBBDDEE),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _DroplyLogoPainter extends CustomPainter {
  const _DroplyLogoPainter({this.accent = const Color(0xFF00B8D9)});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final strokeWidth = size.shortestSide * 0.078;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [accent, const Color(0xFF0877D9)],
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
  bool shouldRepaint(covariant _DroplyLogoPainter oldDelegate) {
    return oldDelegate.accent != accent;
  }
}

class _DroplyBackgroundPainter extends CustomPainter {
  const _DroplyBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final wavePaint = Paint()
      ..color = const Color(0xFF0EA5E9).withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var i = 0; i < 4; i++) {
      final y = size.height * (0.22 + i * 0.17);
      final path = Path()..moveTo(-40, y);
      for (var x = -40.0; x <= size.width + 40; x += 36) {
        path.lineTo(x, y + math.sin((x / 86) + i) * (12 + i * 2));
      }
      canvas.drawPath(path, wavePaint);
    }

    final bottomPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [Color(0x3322D3EE), Color(0x000EA5E9)],
      ).createShader(Offset.zero & size);

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.78)
      ..cubicTo(
        size.width * 0.26,
        size.height * 0.66,
        size.width * 0.62,
        size.height * 0.96,
        size.width,
        size.height * 0.73,
      )
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, bottomPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DroplyGridPainter extends CustomPainter {
  const _DroplyGridPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF94A3B8).withValues(alpha: 0.13)
      ..strokeWidth = 1;

    const step = 24.0;
    for (var x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final washPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.1, -0.15),
        radius: 0.82,
        colors: [
          accent.withValues(alpha: 0.16),
          Colors.white.withValues(alpha: 0),
        ],
      ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, washPaint);
  }

  @override
  bool shouldRepaint(covariant _DroplyGridPainter oldDelegate) {
    return oldDelegate.accent != accent;
  }
}

class _IntroSlide {
  const _IntroSlide({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.metric,
    required this.metricLabel,
    required this.icon,
    required this.accent,
    required this.softAccent,
    required this.highlights,
  });

  final String eyebrow;
  final String title;
  final String body;
  final String metric;
  final String metricLabel;
  final IconData icon;
  final Color accent;
  final Color softAccent;
  final List<String> highlights;
}
