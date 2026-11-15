import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import '../core/theme/app_colors.dart';

class FocusMeterGauge extends StatelessWidget {
  final int watched;
  final int limit;
  final bool isLimitReached;
  final double size;

  const FocusMeterGauge({
    super.key,
    required this.watched,
    required this.limit,
    required this.isLimitReached,
    this.size = 230,
  });

  @override
  Widget build(BuildContext context) {
    final double targetFraction = limit > 0 ? (watched / limit).clamp(0.0, 1.0) : 0.0;
    final int remaining = (limit - watched).clamp(0, 99999);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ambient glow (Neon Purple & Cyan or Neon Pink if reached)
          Container(
            width: size * 0.75,
            height: size * 0.75,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: isLimitReached
                      ? AppColors.neonPink.withValues(alpha: 0.3)
                      : AppColors.neonPurple.withValues(alpha: 0.22),
                  blurRadius: 48,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),

          // Animated Arc Painter
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: targetFraction),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return CustomPaint(
                size: Size(size, size),
                painter: _GaugePainter(
                  fraction: value,
                  isLimitReached: isLimitReached,
                ),
              );
            },
          ),

          // Central Metrics Display
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$watched',
                style: TextStyle(
                  fontSize: size * 0.23,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                  color: isLimitReached ? AppColors.neonPink : AppColors.textPrimary,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'OF $limit REELS',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isLimitReached
                      ? AppColors.neonPink.withValues(alpha: 0.15)
                      : AppColors.neonCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isLimitReached
                        ? AppColors.neonPink.withValues(alpha: 0.5)
                        : AppColors.neonCyan.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  isLimitReached ? 'LIMIT REACHED' : '$remaining REMAINING',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: isLimitReached ? AppColors.neonPink : AppColors.neonCyan,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double fraction;
  final bool isLimitReached;

  _GaugePainter({required this.fraction, required this.isLimitReached});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 24) / 2;
    const strokeWidth = 14.0;
    const startAngle = -math.pi * 0.75;
    const sweepTotal = math.pi * 1.5;

    // Background track
    final trackPaint = Paint()
      ..color = AppColors.surfaceElevated
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal,
      false,
      trackPaint,
    );

    // Active progress arc with Neon Purple -> Pink -> Cyan gradient
    if (fraction > 0.0) {
      final sweepAngle = sweepTotal * fraction;
      final progressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      if (isLimitReached) {
        progressPaint.color = AppColors.neonPink;
      } else {
        progressPaint.shader = const LinearGradient(
          colors: [
            AppColors.neonCyan,
            AppColors.neonPurple,
            AppColors.neonPink,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      }

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.fraction != fraction ||
        oldDelegate.isLimitReached != isLimitReached;
  }
}
