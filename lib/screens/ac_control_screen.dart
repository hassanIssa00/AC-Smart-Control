import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/sensor_data.dart';
import '../services/bluetooth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import '../widgets/interactive_climate_widgets.dart';

class AcControlScreen extends StatelessWidget {
  final bool isEmbedded;
  const AcControlScreen({super.key, this.isEmbedded = false});

  @override
  Widget build(BuildContext context) {
    final sensor = context.watch<SensorData>();
    final bt = context.read<BluetoothService>();
    final canControl = sensor.canControlAC;
    final canPop = !isEmbedded && Navigator.canPop(context);

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
                        'AC CLIMATE CONTROL',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Direct Hardware Relay Switch',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  StatusChip(
                    label: sensor.acOn ? 'RUNNING' : 'STANDBY',
                    color: sensor.acOn ? AppTheme.success : AppTheme.textSecondary,
                    icon: sensor.acOn
                        ? Icons.check_circle_rounded
                        : Icons.power_settings_new_rounded,
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Connection / Safety Status Warning
                    if (!sensor.isConnected)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFE2E8F0),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.bluetooth_disabled_rounded,
                                  color: AppTheme.textSecondary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'HARDWARE OFFLINE',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Connect Bluetooth to engage relay and control AC compressor.',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (sensor.waterLevel == WaterLevel.critical)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: AppTheme.dangerLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.danger.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.danger.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.lock_rounded,
                                  color: AppTheme.danger, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AC COMPRESSOR LOCKED',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: AppTheme.danger,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Critical condensate leakage detected. Power cut off automatically to protect unit.',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: AppTheme.textPrimary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn().shake(hz: 3, offset: const Offset(4, 0)),

                    // Realistic Interactive Split AC Unit Visualizer
                    RealisticSplitAcUnit(
                      isOn: sensor.acOn,
                      canControl: canControl,
                      temperature: sensor.temperature,
                      onTogglePower: () {
                        if (canControl) {
                          if (sensor.acOn) {
                            sensor.turnACOff();
                            bt.sendCommand('AC:OFF');
                          } else {
                            sensor.turnACOn();
                            bt.sendCommand('AC:ON');
                          }
                        }
                      },
                    ).animate().fadeIn(delay: 150.ms),

                    const SizedBox(height: 24),

                    // Primary Start / Stop Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: canControl && !sensor.acOn
                                  ? const LinearGradient(
                                      colors: [Color(0xFF059669), Color(0xFF10B981)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: canControl && !sensor.acOn ? null : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: canControl && !sensor.acOn
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.35),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: ElevatedButton.icon(
                              onPressed: canControl && !sensor.acOn
                                  ? () {
                                      sensor.turnACOn();
                                      bt.sendCommand('AC:ON');
                                    }
                                  : null,
                              icon: const Icon(Icons.power_settings_new_rounded, size: 20),
                              label: Text(
                                'TURN ON AC',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.transparent,
                                disabledForegroundColor: const Color(0xFF94A3B8),
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: sensor.acOn
                                  ? const LinearGradient(
                                      colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: sensor.acOn ? null : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: sensor.acOn
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: ElevatedButton.icon(
                              onPressed: sensor.acOn
                                  ? () {
                                      sensor.turnACOff();
                                      bt.sendCommand('AC:OFF');
                                    }
                                  : null,
                              icon: const Icon(Icons.power_off_rounded, size: 20),
                              label: Text(
                                'TURN OFF AC',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.transparent,
                                disabledForegroundColor: const Color(0xFF94A3B8),
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),

                    const SizedBox(height: 20),

                    // Relay & Safety Status
                    Row(
                      children: [
                        Expanded(
                          child: _DetailTile(
                            icon: Icons.electric_bolt_rounded,
                            iconColor: sensor.relayOn ? AppTheme.success : AppTheme.textMuted,
                            iconBg: sensor.relayOn ? AppTheme.successLight : const Color(0xFFF1F5F9),
                            title: 'Relay Pin (GPIO2)',
                            value: sensor.relayOn ? 'CLOSED (ON)' : 'OPEN (OFF)',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DetailTile(
                            icon: Icons.shield_rounded,
                            iconColor: canControl ? AppTheme.success : AppTheme.danger,
                            iconBg: canControl ? AppTheme.successLight : AppTheme.dangerLight,
                            title: 'Hardware Interlock',
                            value: canControl ? 'SAFE / READY' : 'LOCK ENGAGED',
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 300.ms),

                    const SizedBox(height: 16),

                    // System Telemetry Console
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.border),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info_outline_rounded,
                                  color: AppTheme.primary, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'SYSTEM STATUS LOG',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppTheme.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            sensor.systemStatus,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
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
}

// ─── Detail Tile ─────────────────────────────────────────────────────────────

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String value;

  const _DetailTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
