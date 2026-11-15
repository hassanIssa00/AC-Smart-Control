import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/sensor_data.dart';
import '../services/bluetooth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'water_level_screen.dart';
import 'ac_control_screen.dart';
import 'bluetooth_screen.dart';
import 'archive_screen.dart';

class DashboardScreen extends StatelessWidget {
  final bool isEmbedded;
  const DashboardScreen({super.key, this.isEmbedded = false});

  @override
  Widget build(BuildContext context) {
    final sensor = context.watch<SensorData>();
    final bt = context.watch<BluetoothService>();

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Standalone header if not embedded
              if (!isEmbedded) ...[
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AC DASHBOARD',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Intelligent Climate Monitor',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const BluetoothScreen()),
                      ),
                      child: StatusChip(
                        label: sensor.isConnected ? 'Connected' : 'Offline',
                        color: sensor.isConnected ? AppTheme.success : AppTheme.danger,
                        icon: sensor.isConnected
                            ? Icons.bluetooth_connected_rounded
                            : Icons.bluetooth_disabled_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Active Emergency Leakage Alert Banner
              if (sensor.hasActiveAlert)
                _EmergencyAlertBanner(sensor: sensor)
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: -0.1),

              // Simulation Demo Mode Toggle
              if (!sensor.isConnected)
                _SimModeBanner(sensor: sensor)
                    .animate()
                    .fadeIn(delay: 100.ms),

              // System Status Capsule
              _SystemStatusCard(status: sensor.systemStatus, sensor: sensor)
                  .animate()
                  .fadeIn(delay: 150.ms),

              const SizedBox(height: 20),

              // ── Gauges Row (Temperature & Humidity) ──────────────────────
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.border),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Column(
                        children: [
                          GlowGauge(
                            key: ValueKey('T-${sensor.temperature.toStringAsFixed(1)}'),
                            value: sensor.temperature,
                            min: 0,
                            max: 50,
                            label: 'TEMPERATURE',
                            unit: '°C',
                            color: _tempColor(sensor.temperature),
                            size: 136,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.thermostat_rounded, size: 16, color: _tempColor(sensor.temperature)),
                              const SizedBox(width: 4),
                              Text(
                                _tempStatusText(sensor.temperature),
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.border),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Column(
                        children: [
                          GlowGauge(
                            key: ValueKey('H-${sensor.humidity.toStringAsFixed(1)}'),
                            value: sensor.humidity,
                            min: 0,
                            max: 100,
                            label: 'HUMIDITY',
                            unit: '%',
                            color: AppTheme.primary,
                            size: 136,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.water_drop_rounded, size: 16, color: AppTheme.primary),
                              const SizedBox(width: 4),
                              Text(
                                _humidityStatusText(sensor.humidity),
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

              const SizedBox(height: 14),

              // ── Key Metrics Cards (Heat Index & Water Leakage) ────────────
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.device_thermostat_rounded,
                      iconBg: const Color(0xFFFFF7ED),
                      iconColor: const Color(0xFFEA580C),
                      title: 'Heat Index',
                      value: '${_heatIndex(sensor.temperature, sensor.humidity)}°C',
                      subtitle: 'Real feel in room',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.shield_rounded,
                      iconBg: sensor.waterLevel == WaterLevel.critical
                          ? AppTheme.dangerLight
                          : (sensor.waterLevel == WaterLevel.warning
                              ? AppTheme.warningLight
                              : AppTheme.successLight),
                      iconColor: sensor.waterLevel == WaterLevel.critical
                          ? AppTheme.danger
                          : (sensor.waterLevel == WaterLevel.warning
                              ? AppTheme.warning
                              : AppTheme.success),
                      title: 'Leak Status',
                      value: sensor.waterLevel == WaterLevel.critical
                          ? 'CRITICAL'
                          : (sensor.waterLevel == WaterLevel.warning
                              ? 'WARNING'
                              : 'NORMAL'),
                      subtitle: sensor.waterLevel == WaterLevel.critical
                          ? 'Auto AC Cutoff'
                          : 'Sensors Safe',
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 250.ms),

              const SizedBox(height: 20),

              // ── Master AC Power Control Tile (Direct ON/OFF) ──────────────
              _MasterAcControlCard(sensor: sensor, bt: bt)
                  .animate()
                  .fadeIn(delay: 300.ms)
                  .slideY(begin: 0.1),

              const SizedBox(height: 24),

              // ── Quick Navigation Section ──────────────────────────────────
              Text(
                'QUICK FEATURES',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.55,
                children: [
                  _FeatureCard(
                    icon: Icons.water_damage_rounded,
                    iconBg: const Color(0xFFEFF6FF),
                    iconColor: const Color(0xFF2563EB),
                    title: 'Water Leakage',
                    subtitle: sensor.waterLevel == WaterLevel.critical
                        ? 'High Leak Alert'
                        : 'Tank Reservoir',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const WaterLevelScreen()),
                    ),
                  ),
                  _FeatureCard(
                    icon: Icons.tune_rounded,
                    iconBg: const Color(0xFFECFDF5),
                    iconColor: const Color(0xFF059669),
                    title: 'AC Climate',
                    subtitle: sensor.acOn ? 'Cooling Active' : 'Idle Mode',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AcControlScreen()),
                    ),
                  ),
                  _FeatureCard(
                    icon: Icons.bluetooth_searching_rounded,
                    iconBg: const Color(0xFFF5F3FF),
                    iconColor: const Color(0xFF7C3AED),
                    title: 'Bluetooth',
                    subtitle: sensor.isConnected ? 'ESP32 Linked' : 'Connect Device',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BluetoothScreen()),
                    ),
                  ),
                  _FeatureCard(
                    icon: Icons.picture_as_pdf_rounded,
                    iconBg: const Color(0xFFFEF2F2),
                    iconColor: const Color(0xFFDC2626),
                    title: 'Archive & PDF',
                    subtitle: '${sensor.logs.length} entries • Export',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ArchiveScreen()),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 350.ms),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Color _tempColor(double temp) {
    if (temp < 21) return const Color(0xFF0284C7);
    if (temp < 28) return const Color(0xFF10B981);
    if (temp < 34) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String _tempStatusText(double temp) {
    if (temp < 21) return 'Cool Chill';
    if (temp < 28) return 'Comfort Zone';
    if (temp < 34) return 'Warm Room';
    return 'Hot Alert';
  }

  String _humidityStatusText(double hum) {
    if (hum < 40) return 'Dry Air';
    if (hum < 65) return 'Optimal Comfort';
    return 'Humid Moisture';
  }

  String _heatIndex(double t, double h) {
    final hi = -8.78469475556 +
        1.61139411 * t +
        2.33854883889 * h +
        -0.14611605 * t * h +
        -0.012308094 * t * t +
        -0.0164248277778 * h * h +
        0.002211732 * t * t * h +
        0.00072546 * t * h * h +
        -0.000003582 * t * t * h * h;
    return hi.toStringAsFixed(1);
  }
}

// ─── Emergency Alert Banner ──────────────────────────────────────────────────

class _EmergencyAlertBanner extends StatelessWidget {
  final SensorData sensor;
  const _EmergencyAlertBanner({required this.sensor});

  @override
  Widget build(BuildContext context) {
    final isCritical = sensor.waterLevel == WaterLevel.critical;
    final primaryColor = isCritical ? AppTheme.danger : AppTheme.warning;
    final bgColor = isCritical ? AppTheme.dangerLight : AppTheme.warningLight;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.warning_amber_rounded, color: primaryColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isCritical ? 'LEAKAGE EMERGENCY ALERT' : 'WATER TANK WARNING',
                  style: GoogleFonts.plusJakartaSans(
                    color: primaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => sensor.dismissAlert(),
                child: const Icon(Icons.close_rounded, color: AppTheme.textMuted, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            sensor.lastAlertMessage.isNotEmpty
                ? sensor.lastAlertMessage
                : 'Condensate water detected in AC unit. System auto-shutdown engaged.',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const WaterLevelScreen()),
                  );
                },
                child: Text(
                  'Inspect Tank',
                  style: GoogleFonts.plusJakartaSans(
                    color: primaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => sensor.dismissAlert(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  'Acknowledge',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Master AC Control Card on Dashboard ──────────────────────────────────────

class _MasterAcControlCard extends StatelessWidget {
  final SensorData sensor;
  final BluetoothService bt;

  const _MasterAcControlCard({required this.sensor, required this.bt});

  @override
  Widget build(BuildContext context) {
    final canControl = sensor.canControlAC;
    final isOn = sensor.acOn;

    return Container(
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isOn ? AppTheme.successLight : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.power_settings_new_rounded,
                  color: isOn ? AppTheme.success : AppTheme.textSecondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AC POWER MASTER',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    isOn ? 'Compressor Active • Relay Closed' : 'Standby Mode • Relay Open',
                    style: GoogleFonts.plusJakartaSans(
                      color: isOn ? AppTheme.success : AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: isOn ? AppTheme.successLight : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isOn ? AppTheme.success.withValues(alpha: 0.3) : AppTheme.border,
                  ),
                ),
                child: Text(
                  isOn ? 'RUNNING' : 'STOPPED',
                  style: GoogleFonts.plusJakartaSans(
                    color: isOn ? const Color(0xFF065F46) : AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          if (!canControl) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.dangerLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_rounded, color: AppTheme.danger, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'AC Locked: High water leak detected. Drain reservoir to enable power.',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.danger,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 18),

          // Two Modern Action Pills: Turn ON & Turn OFF
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: canControl && !isOn
                      ? () {
                          sensor.turnACOn();
                          bt.sendCommand('AC:ON');
                        }
                      : null,
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('START AC'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFF1F5F9),
                    disabledForegroundColor: const Color(0xFFCBD5E1),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isOn
                      ? () {
                          sensor.turnACOff();
                          bt.sendCommand('AC:OFF');
                        }
                      : null,
                  icon: const Icon(Icons.stop_rounded, size: 18),
                  label: const Text('STOP AC'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.danger,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFF1F5F9),
                    disabledForegroundColor: const Color(0xFFCBD5E1),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

// ─── Metric Card ─────────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String value;
  final String subtitle;

  const _MetricCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Feature Card ────────────────────────────────────────────────────────────

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.border),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Simulation Banner ───────────────────────────────────────────────────────

class _SimModeBanner extends StatelessWidget {
  final SensorData sensor;
  const _SimModeBanner({required this.sensor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.science_outlined, color: AppTheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Simulation Demo Mode',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  sensor.simulationMode ? 'Simulated sensors active' : 'Test app without hardware',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: sensor.simulationMode,
            onChanged: (_) => sensor.toggleSimulationMode(),
            activeThumbColor: AppTheme.primary,
            activeTrackColor: AppTheme.primaryLight,
          ),
        ],
      ),
    );
  }
}

// ─── Status Capsule ──────────────────────────────────────────────────────────

class _SystemStatusCard extends StatelessWidget {
  final String status;
  final SensorData sensor;

  const _SystemStatusCard({required this.status, required this.sensor});

  @override
  Widget build(BuildContext context) {
    final isCritical = sensor.waterLevel == WaterLevel.critical;
    final color = isCritical ? AppTheme.danger : AppTheme.primary;
    final bg = isCritical ? AppTheme.dangerLight : AppTheme.primaryLight;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            isCritical ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              status,
              style: GoogleFonts.plusJakartaSans(
                color: color,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
