import 'dart:math';
import 'package:flutter/material.dart';

/// Анимированная сфера Леи — дышит в покое, пульсирует при активности.
/// Чистый CustomPainter, никаких внешних пакетов.
class LeaSphere extends StatefulWidget {
  final bool isActive;
  final double size;

  const LeaSphere({super.key, this.isActive = false, this.size = 80});

  @override
  State<LeaSphere> createState() => _LeaSphereState();
}

class _LeaSphereState extends State<LeaSphere> with TickerProviderStateMixin {
  late AnimationController _breathCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _rotateCtrl;

  late Animation<double> _breathAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _rotateAnim;

  @override
  void initState() {
    super.initState();

    _breathCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _breathAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _breathCtrl, curve: Curves.easeInOut));

    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600));
    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _rotateCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 8000),
    )..repeat();
    _rotateAnim = Tween<double>(begin: 0.0, end: 2 * pi).animate(_rotateCtrl);

    if (widget.isActive) _pulseCtrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(LeaSphere old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!widget.isActive && old.isActive) {
      _pulseCtrl.stop();
      _pulseCtrl.reset();
    }
  }

  @override
  void dispose() {
    _breathCtrl.dispose();
    _pulseCtrl.dispose();
    _rotateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_breathAnim, _pulseAnim, _rotateAnim]),
      builder: (context, child) {
        final breath = _breathAnim.value;
        final pulse = widget.isActive ? _pulseAnim.value : 0.0;
        final rotate = _rotateAnim.value;
        final scale = 1.0 + (breath * 0.06) + (pulse * 0.12);

        return SizedBox(
          width: widget.size * 1.5,
          height: widget.size * 1.5,
          child: CustomPaint(
            painter: _SpherePainter(
              breath: breath, pulse: pulse,
              rotate: rotate, scale: scale, size: widget.size,
            ),
          ),
        );
      },
    );
  }
}

class _SpherePainter extends CustomPainter {
  final double breath;
  final double pulse;
  final double rotate;
  final double scale;
  final double size;

  const _SpherePainter({
    required this.breath, required this.pulse,
    required this.rotate, required this.scale, required this.size,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final radius = (size / 2) * scale;

    _drawRing(canvas, center, radius + 14, 0.06 + breath * 0.04);
    _drawRing(canvas, center, radius + 26, 0.04 + breath * 0.02);

    final gradientOffset = Offset(
      center.dx + cos(rotate) * radius * 0.3,
      center.dy + sin(rotate) * radius * 0.3,
    );

    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment(cos(rotate) * 0.4, sin(rotate) * 0.4),
        radius: 1.0,
        colors: [
          Color.lerp(const Color(0xFFAFA9EC), const Color(0xFF7F77DD), 0.3 + breath * 0.3)!,
          const Color(0xFF4a4480),
          const Color(0xFF0d0d1a),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: gradientOffset, radius: radius));

    canvas.drawCircle(center, radius, paint);

    final highlightPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.4, -0.5),
        radius: 0.7,
        colors: [
          Colors.white.withValues(alpha: 0.18 + breath * 0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, highlightPaint);

    if (pulse > 0.01) {
      final glowPaint = Paint()
        ..color = const Color(0xFF7F77DD).withValues(alpha: pulse * 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
      canvas.drawCircle(center, radius + 8, glowPaint);
    }
  }

  void _drawRing(Canvas canvas, Offset center, double r, double opacity) {
    final paint = Paint()
      ..color = const Color(0xFF7F77DD).withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(center, r, paint);
  }

  @override
  bool shouldRepaint(_SpherePainter old) => true;
}
