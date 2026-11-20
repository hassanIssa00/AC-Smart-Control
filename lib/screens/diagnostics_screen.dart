import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/sensor_data.dart';
import '../theme/app_theme.dart';

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  @override
  Widget build(BuildContext context) {
    final sensor = context.watch<SensorData>();

    final healthScore = sensor.systemHealthIndex;
    final isCritical = healthScore < 50;
    final isWarning = healthScore >= 50 && healthScore < 80;

    final healthColor = isCritical
        ? AppTheme.danger
        : (isWarning ? AppTheme.warning : AppTheme.success);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'HVAC DIAGNOSTICS & SAFETY',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              'Thermodynamic Delta-T & Refrigerant Health',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Central System Health Score Banner ────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    healthColor.withValues(alpha: 0.12),
                    Colors.white,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: healthColor.withValues(alpha: 0.35), width: 1.5),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Row(
                children: [
                  // Circular Score Indicator
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 72,
                        height: 72,
                        child: CircularProgressIndicator(
                          value: healthScore / 100.0,
                          strokeWidth: 7,
                          backgroundColor: healthColor.withValues(alpha: 0.18),
                          color: healthColor,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$healthScore%',
                            style: GoogleFonts.orbitron(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'HEALTH',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.textSecondary,
                              fontSize: 7.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: healthColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isCritical
                                ? 'CRITICAL ATTENTION REQUIRED'
                                : (isWarning ? 'PREDICTIVE WARNING' : 'ALL SUBSYSTEMS OPTIMAL'),
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isCritical
                              ? 'Critical water leakage or temperature threshold triggered. Safety interlock engaged.'
                              : (isWarning
                                  ? 'Early thermodynamic anomaly detected: inspect refrigerant charge or check condensate drainage.'
                                  : 'Cooling loop, heat exchange, and safety interlocks operating within nominal engineering tolerances.'),
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 20),

            // ── 2. Freon Charge & Thermodynamic Cooling Differential ──────────
            Text(
              'REFRIGERANT CHARGE & DELTA-T EFFICIENCY',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppTheme.border),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _TempPill(
                        label: 'Room Return Air',
                        temp: '${sensor.returnTemperature.toStringAsFixed(1)}°C',
                        color: const Color(0xFF64748B),
                      ),
                      const Icon(Icons.arrow_forward_rounded, color: AppTheme.textMuted, size: 18),
                      _TempPill(
                        label: 'AC Supply Air',
                        temp: sensor.temperature > 0 ? '${sensor.temperature.toStringAsFixed(1)}°C' : '--',
                        color: const Color(0xFF0284C7),
                      ),
                      const Icon(Icons.drag_handle_rounded, color: AppTheme.textMuted, size: 18),
                      _TempPill(
                        label: 'Delta-T (ΔT)',
                        temp: '${sensor.deltaT.toStringAsFixed(1)}°C',
                        color: sensor.deltaT >= 8.0 ? AppTheme.success : AppTheme.warning,
                      ),
                    ],
                  ),
                  const Divider(height: 28),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _freonColor(sensor).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.propane_tank_rounded, color: _freonColor(sensor), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Refrigerant (Freon) Status',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _freonVerdictText(sensor),
                              style: GoogleFonts.plusJakartaSans(
                                color: _freonColor(sensor),
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 150.ms),

            const SizedBox(height: 20),

            // ── 3. Safety Interlock & Condensate Drain Pan ───────────────────
            Text(
              'SAFETY INTERLOCK & CONDENSATE WATER DRAIN',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppTheme.border),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: sensor.waterLevel == WaterLevel.critical
                              ? AppTheme.dangerLight
                              : AppTheme.successLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          sensor.waterLevel == WaterLevel.critical
                              ? Icons.water_damage_rounded
                              : Icons.water_drop_rounded,
                          color: sensor.waterLevel == WaterLevel.critical
                              ? AppTheme.danger
                              : AppTheme.success,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Condensate Water Reservoir',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.textSecondary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              sensor.waterLevel == WaterLevel.critical
                                  ? 'CRITICAL LEAKAGE DETECTED'
                                  : (sensor.waterLevel == WaterLevel.warning
                                      ? 'WARNING: Level at 50-80%'
                                      : 'Normal Operation (Safe)'),
                              style: GoogleFonts.plusJakartaSans(
                                color: sensor.waterLevel == WaterLevel.critical
                                    ? AppTheme.danger
                                    : (sensor.waterLevel == WaterLevel.warning
                                        ? AppTheme.warning
                                        : AppTheme.success),
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: !sensor.canControlAC
                              ? AppTheme.dangerLight
                              : (sensor.acOn ? AppTheme.successLight : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          !sensor.canControlAC
                              ? Icons.lock_rounded
                              : (sensor.acOn ? Icons.power_rounded : Icons.power_off_rounded),
                          color: !sensor.canControlAC
                              ? AppTheme.danger
                              : (sensor.acOn ? AppTheme.success : AppTheme.textMuted),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hardware Relay Interlock',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.textSecondary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              !sensor.canControlAC
                                  ? 'LOCKED — Emergency Power Cut Off'
                                  : (sensor.acOn ? 'ENERGIZED — AC Running' : 'STANDBY — Relay Disengaged'),
                              style: GoogleFonts.plusJakartaSans(
                                color: !sensor.canControlAC
                                    ? AppTheme.danger
                                    : (sensor.acOn ? AppTheme.success : AppTheme.textPrimary),
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  String _freonVerdictText(SensorData sensor) {
    switch (sensor.freonStatus) {
      case FreonStatus.optimal:
        return 'Healthy Charge (Cooling Efficient)';
      case FreonStatus.lowRefrigerant:
        return 'Low Refrigerant Warning (Leak Detected)';
      case FreonStatus.evaluating:
        return 'Stabilizing Thermodynamic Loop...';
      case FreonStatus.standby:
        return 'System Standby (Turn AC ON)';
    }
  }

  Color _freonColor(SensorData sensor) {
    switch (sensor.freonStatus) {
      case FreonStatus.optimal:
        return AppTheme.success;
      case FreonStatus.lowRefrigerant:
        return AppTheme.danger;
      case FreonStatus.evaluating:
        return AppTheme.warning;
      case FreonStatus.standby:
        return AppTheme.textMuted;
    }
  }
}

// ─── Temp Pill ───────────────────────────────────────────────────────────────

class _TempPill extends StatelessWidget {
  final String label;
  final String temp;
  final Color color;

  const _TempPill({
    required this.label,
    required this.temp,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.textMuted,
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            temp,
            style: GoogleFonts.orbitron(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
