import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

// ══════════════════════════════════════════════════════════════════════════════
// 1. REALISTIC INTERACTIVE SPLIT AC UNIT WIDGET
// ══════════════════════════════════════════════════════════════════════════════

class RealisticSplitAcUnit extends StatefulWidget {
  final bool isOn;
  final bool canControl;
  final double temperature;
  final VoidCallback? onTogglePower;

  const RealisticSplitAcUnit({
    super.key,
    required this.isOn,
    required this.canControl,
    required this.temperature,
    this.onTogglePower,
  });

  @override
  State<RealisticSplitAcUnit> createState() => _RealisticSplitAcUnitState();
}

class _RealisticSplitAcUnitState extends State<RealisticSplitAcUnit>
    with TickerProviderStateMixin {
  late AnimationController _louverController;
  late AnimationController _breezeController;
  late Animation<double> _louverAngle;
  bool _isAutoSwing = true;

  @override
  void initState() {
    super.initState();

    // Motorized louver flap opening animation
    _louverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _louverAngle = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _louverController, curve: Curves.easeInOutCubic),
    );

    // Continuous breeze wave animation
    _breezeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    if (widget.isOn) {
      _louverController.forward();
      _breezeController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant RealisticSplitAcUnit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOn != oldWidget.isOn) {
      if (widget.isOn) {
        _louverController.forward();
        _breezeController.repeat();
      } else {
        _louverController.reverse();
        _breezeController.stop();
      }
    }
  }

  @override
  void dispose() {
    _louverController.dispose();
    _breezeController.dispose();
    super.dispose();
  }

  void _handleUnitTap() {
    HapticFeedback.lightImpact();
    if (widget.onTogglePower != null && widget.canControl) {
      widget.onTogglePower!();
    } else {
      setState(() => _isAutoSwing = !_isAutoSwing);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayTemp = widget.temperature > 0.0
        ? '${widget.temperature.toStringAsFixed(0)}°'
        : (widget.isOn ? '24°' : '--');

    return GestureDetector(
      onTap: _handleUnitTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── The Split AC Indoor Unit Chassis ──────────────────────────────
          Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Chassis Outer Shell (Luxury Obsidian Piano Black Edition)
              Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF242E40), // Top bevel titanium reflection
                      Color(0xFF131824), // Sleek obsidian body
                      Color(0xFF090D16), // Deep midnight black base
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(22),
                    topRight: Radius.circular(22),
                    bottomLeft: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                  ),
                  border: Border.all(color: const Color(0xFF334155), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.30),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: widget.isOn
                          ? const Color(0xFF00E5FF).withValues(alpha: 0.22)
                          : Colors.transparent,
                      blurRadius: 36,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Top Air Intake Grille Lines
                    Positioned(
                      top: 10,
                      left: 30,
                      right: 30,
                      child: Column(
                        children: List.generate(
                          3,
                          (i) => Container(
                            margin: const EdgeInsets.only(bottom: 2.5),
                            height: 1.2,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Chrome Horizontal Trim Accent (Mirror Platinum Reflection)
                    Positioned(
                      top: 24,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 1.5,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Color(0xFF475569),
                              Color(0xFF94A3B8),
                              Color(0xFFF8FAFC),
                              Color(0xFF94A3B8),
                              Color(0xFF475569),
                              Colors.transparent,
                            ],
                            stops: [0.0, 0.15, 0.45, 0.5, 0.55, 0.85, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Brand Badge (Left Side)
                    Positioned(
                      left: 20,
                      bottom: 24,
                      child: Row(
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.isOn
                                  ? const Color(0xFF00E5FF)
                                  : const Color(0xFF334155),
                              boxShadow: widget.isOn
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Icon(
                              Icons.ac_unit_rounded,
                              size: 10,
                              color: widget.isOn ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CLIMASMART',
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFFF1F5F9),
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Text(
                                'BLACK EDITION DUAL-COOL',
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF94A3B8),
                                  fontSize: 6.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Embedded Concealed Digital LED Display (Right Side)
                    Positioned(
                      right: 24,
                      bottom: 20,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Status Pilot LED Light
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.isOn
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF334155),
                              boxShadow: widget.isOn
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF10B981)
                                            .withValues(alpha: 0.9),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Concealed LED Glow Screen (Smoked Glass Digital Display)
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 400),
                            opacity: widget.isOn ? 1.0 : 0.2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: widget.isOn
                                    ? const Color(0xFF00E5FF).withValues(alpha: 0.1)
                                    : const Color(0xFF1E293B).withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: widget.isOn
                                      ? const Color(0xFF00E5FF).withValues(alpha: 0.35)
                                      : Colors.transparent,
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayTemp,
                                    style: GoogleFonts.orbitron(
                                      color: widget.isOn
                                          ? const Color(0xFF00E5FF)
                                          : const Color(0xFF475569),
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -1,
                                      shadows: widget.isOn
                                          ? [
                                              Shadow(
                                                color: const Color(0xFF00E5FF).withValues(alpha: 0.7),
                                                blurRadius: 10,
                                              ),
                                            ]
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.air_rounded,
                                    size: 14,
                                    color: widget.isOn
                                        ? const Color(0xFF00E5FF)
                                        : const Color(0xFF475569),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bottom Vent Recess Shadow
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 0,
                      child: Container(
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Color(0xFF020617),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Animated Motorized Bottom Louver Flap (Black Edition)
              Positioned(
                left: 14,
                right: 14,
                bottom: -4,
                child: AnimatedBuilder(
                  animation: _louverAngle,
                  builder: (context, child) {
                    final openProgress = _louverAngle.value;
                    return Transform(
                      alignment: Alignment.topCenter,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.002)
                        ..rotateX(openProgress * 0.75), // Flap tilts down
                      child: Container(
                        height: 14,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF334155), Color(0xFF1E293B), Color(0xFF090D16)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF475569), width: 0.8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: openProgress * 0.4),
                              blurRadius: 8,
                              offset: Offset(0, openProgress * 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 40,
                            height: 1.5,
                            decoration: BoxDecoration(
                              color: const Color(0xFF64748B),
                              borderRadius: BorderRadius.circular(1),
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

          // ── Flowing Cool Airflow Breeze Waves ─────────────────────────────
          AnimatedBuilder(
            animation: _breezeController,
            builder: (context, child) {
              if (!widget.isOn && _louverAngle.value == 0) {
                return const SizedBox(height: 16);
              }
              return CustomPaint(
                size: const Size(double.infinity, 90),
                painter: _CoolBreezePainter(
                  progress: _breezeController.value,
                  opacity: _louverAngle.value,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Realistic Airflow Breeze Painter ─────────────────────────────────────────

class _CoolBreezePainter extends CustomPainter {
  final double progress;
  final double opacity;

  _CoolBreezePainter({required this.progress, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0.01) return;

    final centerX = size.width / 2;
    const waveCount = 5;

    for (int i = 0; i < waveCount; i++) {
      final waveOffset = (progress + (i / waveCount)) % 1.0;
      const startY = 4.0;
      final endY = size.height * (0.3 + waveOffset * 0.7);

      final spread = (i - 2) * (size.width * 0.16);
      final currentX = centerX + spread * (0.3 + waveOffset * 0.7);

      final wavePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = (2.2 * (1.0 - waveOffset)).clamp(1.0, 2.5)
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF00E5FF).withValues(alpha: 0.75 * opacity * (1.0 - waveOffset)),
            const Color(0xFF38BDF8).withValues(alpha: 0.5 * opacity * (1.0 - waveOffset)),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      final path = Path();
      path.moveTo(currentX - (10 * math.sin(waveOffset * math.pi * 2)), startY);

      // Smooth flowing bezier wave curves
      path.cubicTo(
        currentX + (18 * math.sin(waveOffset * math.pi * 3)),
        startY + (endY - startY) * 0.4,
        currentX - (14 * math.cos(waveOffset * math.pi * 2)),
        startY + (endY - startY) * 0.7,
        currentX + (8 * math.sin(waveOffset * math.pi * 4)),
        endY,
      );

      canvas.drawPath(path, wavePaint);

      // Ambient Cool Particles
      final particleY = startY + (endY - startY) * waveOffset;
      final particleX = currentX + (12 * math.sin(waveOffset * math.pi * 4));
      final particlePaint = Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.65 * opacity * (1.0 - waveOffset))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(particleX, particleY), 2.0 * (1.0 - waveOffset), particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CoolBreezePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.opacity != opacity;
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 2. INTERACTIVE HUMIDITY RIPPLE & DROPLET WIDGET
// ══════════════════════════════════════════════════════════════════════════════

class InteractiveHumidityCard extends StatefulWidget {
  final double humidity;
  final bool isConnected;

  const InteractiveHumidityCard({
    super.key,
    required this.humidity,
    required this.isConnected,
  });

  @override
  State<InteractiveHumidityCard> createState() => _InteractiveHumidityCardState();
}

class _InteractiveHumidityCardState extends State<InteractiveHumidityCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;
  int _rippleCount = 0;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  void _triggerRipple() {
    HapticFeedback.selectionClick();
    setState(() => _rippleCount++);
  }

  @override
  Widget build(BuildContext context) {
    final hasData = widget.isConnected && widget.humidity > 0.0;
    final level = hasData ? widget.humidity.clamp(0.0, 100.0) : 0.0;

    return GestureDetector(
      onTap: _triggerRipple,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.border),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top utility row: Icon + Interactive Ripple feedback
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.water_drop_rounded, color: Color(0xFF0284C7), size: 18),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.touch_app_rounded, size: 11, color: AppTheme.primary),
                      const SizedBox(width: 3),
                      Text(
                        'Ripple',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Full-width Headline: Never splits or wraps!
            Text(
              'HUMIDITY',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 2),
            Text(
              hasData ? _humidityVerdict(widget.humidity) : 'Awaiting Sensor',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 18),

            // Animated Liquid Capsule Visualizer
            SizedBox(
              height: 110,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Acrylic Vessel Glass
                  Container(
                    width: 76,
                    height: 110,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(38),
                      border: Border.all(color: const Color(0xFFBAE6FD), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        // Dynamic Wave Liquid Filling
                        Positioned.fill(
                          child: AnimatedBuilder(
                            animation: _waveController,
                            builder: (context, child) {
                              return CustomPaint(
                                painter: _DropletWavePainter(
                                  progress: _waveController.value,
                                  fillPercent: hasData ? (level / 100.0) : 0.08,
                                  rippleBonus: _rippleCount % 3,
                                ),
                              );
                            },
                          ),
                        ),

                        // Glass Glare Line
                        Positioned(
                          top: 14,
                          left: 8,
                          bottom: 14,
                          child: Container(
                            width: 3.5,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Big Center Percentage Display
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        hasData ? widget.humidity.toStringAsFixed(1) : '--',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (hasData)
                        Text(
                          '% RH',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF0284C7),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _humidityVerdict(double h) {
    if (h < 35) return 'Dry Air (Low)';
    if (h <= 60) return 'Optimal Comfort';
    if (h <= 75) return 'High Moisture';
    return 'Damp (Inspect Drain)';
  }
}

// ─── Droplet Liquid Wave Painter ──────────────────────────────────────────────

class _DropletWavePainter extends CustomPainter {
  final double progress;
  final double fillPercent;
  final int rippleBonus;

  _DropletWavePainter({
    required this.progress,
    required this.fillPercent,
    required this.rippleBonus,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fillHeight = size.height * fillPercent.clamp(0.04, 0.96);
    final waterSurfaceY = size.height - fillHeight;

    final liquidPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF38BDF8), Color(0xFF0284C7), Color(0xFF0369A1)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, waterSurfaceY, size.width, fillHeight));

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, waterSurfaceY);

    final waveAmplitude = 3.5 + rippleBonus * 2.0;
    for (double x = 0; x <= size.width; x += 1) {
      final y = waterSurfaceY +
          waveAmplitude *
              math.sin((x / size.width * 2 * math.pi) + (progress * 2 * math.pi));
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, liquidPaint);
  }

  @override
  bool shouldRepaint(covariant _DropletWavePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.fillPercent != fillPercent ||
        oldDelegate.rippleBonus != rippleBonus;
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 3. INTERACTIVE TEMPERATURE MERCURY THERMOMETER WIDGET
// ══════════════════════════════════════════════════════════════════════════════

class InteractiveTemperatureCard extends StatefulWidget {
  final double temperature;
  final bool isConnected;

  const InteractiveTemperatureCard({
    super.key,
    required this.temperature,
    required this.isConnected,
  });

  @override
  State<InteractiveTemperatureCard> createState() => _InteractiveTemperatureCardState();
}

class _InteractiveTemperatureCardState extends State<InteractiveTemperatureCard>
    with SingleTickerProviderStateMixin {
  bool _showFahrenheit = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleScale() {
    HapticFeedback.lightImpact();
    setState(() => _showFahrenheit = !_showFahrenheit);
  }

  @override
  Widget build(BuildContext context) {
    final hasData = widget.isConnected && widget.temperature > 0.0;
    final tempC = hasData ? widget.temperature : 0.0;
    final tempF = (tempC * 9 / 5) + 32;

    final displayVal = hasData
        ? (_showFahrenheit ? '${tempF.toStringAsFixed(1)}°F' : '${tempC.toStringAsFixed(1)}°C')
        : '--';

    final tempColor = _calcTempColor(tempC);

    return GestureDetector(
      onTap: _toggleScale,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.border),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top utility row: Icon + Interactive Scale Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: tempColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.thermostat_rounded, color: tempColor, size: 18),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _showFahrenheit ? '°F Scale' : '°C Scale',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Full-width Headline: Never splits or wraps!
            Text(
              'TEMPERATURE',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 2),
            Text(
              hasData ? _tempComfortVerdict(tempC) : 'Awaiting Sensor',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 18),

            // Precision Glass Thermometer Visualizer
            SizedBox(
              height: 110,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Physical Glass Thermometer Column
                  Container(
                    width: 22,
                    height: 110,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                    ),
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        // Mercury Level Column
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          width: 12,
                          height: hasData
                              ? ((tempC - 10) / (45 - 10) * 80).clamp(10.0, 95.0)
                              : 10.0,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [tempColor.withValues(alpha: 0.7), tempColor],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),

                        // Bottom Mercury Bulb
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            final pulse = _pulseController.value * 2;
                            return Container(
                              width: 18 + (hasData ? pulse : 0),
                              height: 18 + (hasData ? pulse : 0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: tempColor,
                                boxShadow: hasData
                                    ? [
                                        BoxShadow(
                                          color: tempColor.withValues(alpha: 0.4),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : null,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 18),

                  // Big Animated Number
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayVal,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                      ),
                      Text(
                        hasData ? 'Ambient Airflow' : 'Connect Bluetooth',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _calcTempColor(double t) {
    if (t <= 0) return AppTheme.textMuted;
    if (t < 21) return const Color(0xFF0284C7); // Cool blue
    if (t <= 26) return const Color(0xFF10B981); // Comfort green
    if (t <= 30) return const Color(0xFFF59E0B); // Warm amber
    return const Color(0xFFEF4444); // Hot red
  }

  String _tempComfortVerdict(double t) {
    if (t < 20) return 'Cool Room';
    if (t <= 25) return 'Ideal Comfort (24°C)';
    if (t <= 28) return 'Mild Warm';
    return 'High Ambient Heat';
  }
}
