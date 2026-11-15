import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Modern Minimalist Climate Gauge (Apple Home / Nest Style)
class GlowGauge extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final String label;
  final String unit;
  final Color color;
  final double size;
  final String? displayValue;

  const GlowGauge({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.label,
    required this.unit,
    this.color = AppTheme.primary,
    this.size = 150,
    this.displayValue,
  });

  @override
  Widget build(BuildContext context) {
    final progress = ((value - min) / (max - min)).clamp(0.0, 1.0);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _ModernGaugePainter(progress: progress, color: color),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: size * 0.085,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMuted,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayValue ?? value.toStringAsFixed(1),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: size * 0.22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: -1,
                    ),
                  ),
                  if (displayValue == null || displayValue != '--')
                    Text(
                      unit,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: size * 0.11,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
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

class _ModernGaugePainter extends CustomPainter {
  final double progress;
  final Color color;

  _ModernGaugePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 14;
    const startAngle = pi * 0.75;
    const sweepAngle = pi * 1.5;

    // Background track (subtle light grey)
    final bgPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // Active arc with smooth gradient
    final arcPaint = Paint()
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle * progress,
        colors: [color.withValues(alpha: 0.6), color],
        tileMode: TileMode.clamp,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * progress,
        false,
        arcPaint,
      );

      // Clean tip indicator dot
      final angle = startAngle + sweepAngle * progress;
      final dotPos = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      canvas.drawCircle(dotPos, 6, Paint()..color = Colors.white);
      canvas.drawCircle(dotPos, 4, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_ModernGaugePainter old) =>
      old.progress != progress || old.color != color;
}

/// Luxury Architectural 3D Acrylic Water Reservoir Widget
class WaterTankWidget extends StatelessWidget {
  final double fillPercent; // 0.0 to 1.0
  final Color color;
  final String label;

  const WaterTankWidget({
    super.key,
    required this.fillPercent,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (fillPercent.clamp(0.0, 1.0) * 100).round();

    return Column(
      children: [
        Container(
          width: 90,
          height: 170,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: color.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Water fill with calm luminous gradient
                AnimatedContainer(
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  height: 170 * fillPercent.clamp(0.02, 1.0),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        color.withValues(alpha: 0.85),
                        color,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                ),

                // Luminous Water Meniscus Surface Line
                Positioned(
                  bottom: (170 * fillPercent.clamp(0.02, 1.0)) - 1.5,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.9),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),

                // Left Glass Specular Glare (Reflective Acrylic Bevel)
                Positioned(
                  top: 10,
                  left: 6,
                  bottom: 10,
                  child: Container(
                    width: 3.5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Precision Laser-Etched Level Markers (25%, 50%, 75%)
                ...List.generate(3, (i) {
                  final y = 42.5 * (i + 1);
                  final markText = ['25%', '50%', '75%'][i];
                  return Positioned(
                    bottom: y,
                    left: 14,
                    right: 8,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 22,
                          height: 1.2,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        Text(
                          markText,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 7.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.85),
                            shadows: [
                              Shadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 2),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                // Floating Dynamic Percentage Badge at Top
                Positioned(
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '$pct%',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Refined Pill Status Chip (Light Theme)
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Modern Tactile Power Button
class PowerButton extends StatelessWidget {
  final bool isOn;
  final bool enabled;
  final VoidCallback onPressed;
  final Color onColor;
  final Color offColor;

  const PowerButton({
    super.key,
    required this.isOn,
    required this.onPressed,
    this.enabled = true,
    this.onColor = AppTheme.success,
    this.offColor = const Color(0xFF94A3B8),
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isOn ? onColor : offColor;

    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isOn ? activeColor : Colors.white,
          border: Border.all(
            color: isOn ? activeColor : const Color(0xFFE2E8F0),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isOn
                  ? activeColor.withValues(alpha: 0.35)
                  : const Color(0xFF0F172A).withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(
          Icons.power_settings_new_rounded,
          size: 36,
          color: isOn ? Colors.white : activeColor,
        ),
      ),
    );
  }
}
