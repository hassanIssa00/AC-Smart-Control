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
  void _simulateScenario(SensorData sensor, String scenario) {
    sensor.simulateDiagnosticScenario(scenario);
  }

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
              'HVAC DIAGNOSTICS & POWER',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              'Smart Current & Freon Health Monitoring',
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
                              ? 'Critical electrical or water leak threshold triggered. Power interlock engaged.'
                              : (isWarning
                                  ? 'Early anomaly detected: check refrigerant level or inspect condensate drainage.'
                                  : 'Compressor, fans, and thermodynamics operating within strict engineering tolerances.'),
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

            // ── 2. 3-Channel Current Sensors Telemetry ────────────────────────
            Text(
              'ELECTRICAL CURRENT MONITOR (3x SENSORS)',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            // Compressor Current Card
            _CurrentChannelCard(
              title: 'AC Compressor Current (I_comp)',
              icon: Icons.electric_bolt_rounded,
              currentAmps: sensor.compressorCurrent,
              ratedMin: 3.5,
              ratedMax: 7.5,
              criticalMax: 8.5,
              isActive: sensor.acOn,
              subVerdict: _compressorVerdictText(sensor),
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 12),

            // Dual Fan Channels Row
            Row(
              children: [
                Expanded(
                  child: _CurrentChannelCard(
                    title: 'Indoor Blower Fan',
                    icon: Icons.air_rounded,
                    currentAmps: sensor.indoorFanCurrent,
                    ratedMin: 0.20,
                    ratedMax: 0.55,
                    criticalMax: 0.80,
                    isActive: sensor.acOn,
                    isCompact: true,
                    subVerdict: sensor.indoorFanHealth == FanHealth.normal
                        ? 'Optimal Speed'
                        : (sensor.indoorFanHealth == FanHealth.overcurrent
                            ? 'Bearing Overload'
                            : 'Fan Stopped'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CurrentChannelCard(
                    title: 'Outdoor Condenser Fan',
                    icon: Icons.mode_fan_off_rounded,
                    currentAmps: sensor.outdoorFanCurrent,
                    ratedMin: 0.50,
                    ratedMax: 1.10,
                    criticalMax: 1.40,
                    isActive: sensor.acOn,
                    isCompact: true,
                    subVerdict: sensor.outdoorFanHealth == FanHealth.normal
                        ? 'Heat Dissipation OK'
                        : (sensor.outdoorFanHealth == FanHealth.overcurrent
                            ? 'Motor Overheat'
                            : 'Fan Stopped'),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 20),

            // ── 3. Freon Charge & Thermodynamic Cooling Differential ──────────
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
                        color: sensor.deltaT >= 9.0 ? AppTheme.success : AppTheme.warning,
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
            ).animate().fadeIn(delay: 250.ms),

            const SizedBox(height: 20),

            // ── 4. Defense & Testing Scenario Injector ────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.science_rounded, size: 18, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'DEMO & PRESENTATION INJECTOR',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.primaryDark,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Simulate sensor faults live to demonstrate AI rule-based diagnostic alerts during evaluations:',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 16),
                        label: const Text('Normal (5.4A)'),
                        onPressed: () => _simulateScenario(sensor, 'NORMAL'),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 16),
                        label: const Text('Low Freon (2.1A)'),
                        onPressed: () => _simulateScenario(sensor, 'LOW_FREON'),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.error_rounded, color: AppTheme.danger, size: 16),
                        label: const Text('Overload (9.6A)'),
                        onPressed: () => _simulateScenario(sensor, 'OVERLOAD'),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.mode_fan_off_rounded, color: Colors.purple, size: 16),
                        label: const Text('Fan Seizure'),
                        onPressed: () => _simulateScenario(sensor, 'FAN_FAULT'),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  String _compressorVerdictText(SensorData sensor) {
    if (!sensor.acOn) return 'Compressor Idle (Relay Open)';
    if (sensor.compressorCurrent > 8.0) return 'DANGER: Locked Rotor / High Amperage';
    if (sensor.compressorCurrent < 3.2 && sensor.compressorCurrent > 0.4) {
      return 'WARNING: Underload (Potential Freon Leak)';
    }
    return 'Optimal Compression (Load Balanced)';
  }

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

// ─── Current Channel Card ────────────────────────────────────────────────────

class _CurrentChannelCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final double currentAmps;
  final double ratedMin;
  final double ratedMax;
  final double criticalMax;
  final bool isActive;
  final String subVerdict;
  final bool isCompact;

  const _CurrentChannelCard({
    required this.title,
    required this.icon,
    required this.currentAmps,
    required this.ratedMin,
    required this.ratedMax,
    required this.criticalMax,
    required this.isActive,
    required this.subVerdict,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isOverload = currentAmps > criticalMax;
    final isUnderload = isActive && currentAmps > 0.1 && currentAmps < ratedMin;
    final statusColor = !isActive
        ? AppTheme.textMuted
        : (isOverload ? AppTheme.danger : (isUnderload ? AppTheme.warning : AppTheme.success));

    final progress = (currentAmps / (criticalMax * 1.2)).clamp(0.0, 1.0);

    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isOverload ? AppTheme.danger : AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: statusColor, size: 15),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      currentAmps.toStringAsFixed(2),
                      style: GoogleFonts.orbitron(
                        color: statusColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'A',
                      style: GoogleFonts.plusJakartaSans(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subVerdict,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Rated: ${ratedMin.toStringAsFixed(2)}-${ratedMax.toStringAsFixed(2)}A',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textMuted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(icon, color: statusColor, size: 18),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${currentAmps.toStringAsFixed(1)} A',
                      style: GoogleFonts.orbitron(
                        color: statusColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rated: ${ratedMin}A - ${ratedMax}A',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      subVerdict,
                      style: GoogleFonts.plusJakartaSans(
                        color: statusColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
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
