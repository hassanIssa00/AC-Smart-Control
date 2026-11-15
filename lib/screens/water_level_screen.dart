import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/sensor_data.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class WaterLevelScreen extends StatelessWidget {
  final bool isEmbedded;
  const WaterLevelScreen({super.key, this.isEmbedded = false});

  @override
  Widget build(BuildContext context) {
    final sensor = context.watch<SensorData>();
    final level = sensor.waterLevel;
    final canPop = !isEmbedded && Navigator.canPop(context);

    final levelColor = level == WaterLevel.critical
        ? AppTheme.danger
        : level == WaterLevel.warning
            ? AppTheme.warning
            : AppTheme.success;

    final levelLabel = level == WaterLevel.critical
        ? 'CRITICAL LEAK'
        : level == WaterLevel.warning
            ? 'WARNING'
            : 'NORMAL SAFE';

    final fillPercent = level == WaterLevel.critical
        ? 0.90
        : level == WaterLevel.warning
            ? 0.60
            : 0.25;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  if (canPop) ...[
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppTheme.textPrimary,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                  ],
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WATER LEAKAGE & TANK',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Condensate Reservoir & Leak Sensor',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  StatusChip(
                    label: levelLabel,
                    color: levelColor,
                    icon: level == WaterLevel.critical
                        ? Icons.warning_rounded
                        : level == WaterLevel.warning
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle_rounded,
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Main Reservoir Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: AppTheme.border),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Column(
                        children: [
                          Text(
                            'CONDENSATE TANK LEVEL',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Center Reservoir Widget
                          WaterTankWidget(
                            fillPercent: fillPercent,
                            color: levelColor,
                            label: 'Active Reservoir (${(fillPercent * 100).round()}%)',
                          ),

                          const SizedBox(height: 20),

                          // Status capsule
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: levelColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: levelColor.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  level == WaterLevel.critical
                                      ? Icons.error_rounded
                                      : (level == WaterLevel.warning
                                          ? Icons.warning_amber_rounded
                                          : Icons.check_circle_rounded),
                                  color: levelColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    level == WaterLevel.critical
                                        ? 'High Leakage: AC Disabled'
                                        : (level == WaterLevel.warning
                                            ? 'Moderate: Prepare to drain'
                                            : 'Normal: Condensate safe'),
                                    style: GoogleFonts.plusJakartaSans(
                                      color: levelColor,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 150.ms),

                    const SizedBox(height: 20),

                    // Three States Reference
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.border),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LEAKAGE PROTOCOL THRESHOLDS',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 14),

                          _ThresholdRow(
                            title: 'Normal Operation (0% - 40%)',
                            subtitle: 'Condensate flowing normally. Full AC control available.',
                            color: AppTheme.success,
                            isActive: level == WaterLevel.normal,
                          ),
                          const SizedBox(height: 10),
                          _ThresholdRow(
                            title: 'Tank Warning (40% - 75%)',
                            subtitle: 'Reservoir filling up. System alert issued.',
                            color: AppTheme.warning,
                            isActive: level == WaterLevel.warning,
                          ),
                          const SizedBox(height: 10),
                          _ThresholdRow(
                            title: 'Critical Leakage (75% - 100%)',
                            subtitle: 'AC compressor killed automatically. Safety lock engaged.',
                            color: AppTheme.danger,
                            isActive: level == WaterLevel.critical,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 250.ms),

                    const SizedBox(height: 20),

                    // Hardware Telemetry & Pin Diagnostics
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.border),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'HARDWARE SENSOR TELEMETRY',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'ESP32 embedded pin configuration & fail-safe link:',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildHardwarePinRow(
                            pin: 'GPIO 34',
                            label: 'Analog Probe',
                            status: sensor.isConnected ? 'Receiving Real ADC' : 'Waiting for BT',
                            color: sensor.isConnected ? AppTheme.primary : AppTheme.textMuted,
                          ),
                          const SizedBox(height: 8),
                          _buildHardwarePinRow(
                            pin: 'GPIO 2',
                            label: 'Compressor Relay',
                            status: sensor.acOn ? 'RELAY CLOSED (ON)' : 'RELAY OPEN (OFF)',
                            color: sensor.acOn ? AppTheme.success : AppTheme.textSecondary,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 350.ms),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHardwarePinRow({
    required String pin,
    required String label,
    required String status,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              pin,
              style: GoogleFonts.jetBrainsMono(
                color: AppTheme.primaryDark,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            status,
            style: GoogleFonts.plusJakartaSans(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThresholdRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final bool isActive;

  const _ThresholdRow({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.08) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? color.withValues(alpha: 0.4) : AppTheme.border,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    color: isActive ? color : AppTheme.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textSecondary,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          if (isActive)
            Icon(Icons.check_circle_rounded, color: color, size: 18),
        ],
      ),
    );
  }
}
