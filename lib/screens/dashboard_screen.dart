import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/sensor_data.dart';
import '../services/bluetooth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import '../widgets/interactive_climate_widgets.dart';
import 'water_level_screen.dart';
import 'ac_control_screen.dart';
import 'bluetooth_screen.dart';
import 'archive_screen.dart';
import 'diagnostics_screen.dart';

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

              // System Status Capsule
              _SystemStatusCard(status: sensor.systemStatus, sensor: sensor)
                  .animate()
                  .fadeIn(delay: 100.ms),

              const SizedBox(height: 20),

              // ── Interactive Climate Telemetry Row (Temperature & Humidity) ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: InteractiveTemperatureCard(
                      temperature: sensor.temperature,
                      isConnected: sensor.isConnected,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: InteractiveHumidityCard(
                      humidity: sensor.humidity,
                      isConnected: sensor.isConnected,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.08),

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
                      value: sensor.hasRealTelemetry
                          ? '${_heatIndex(sensor.temperature, sensor.humidity)}°C'
                          : '--',
                      subtitle: sensor.hasRealTelemetry ? 'Real feel in room' : 'Awaiting sensors',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.shield_rounded,
                      iconBg: !sensor.isConnected
                          ? const Color(0xFFF1F5F9)
                          : (sensor.waterLevel == WaterLevel.critical
                              ? AppTheme.dangerLight
                              : (sensor.waterLevel == WaterLevel.warning
                                  ? AppTheme.warningLight
                                  : AppTheme.successLight)),
                      iconColor: !sensor.isConnected
                          ? AppTheme.textMuted
                          : (sensor.waterLevel == WaterLevel.critical
                              ? AppTheme.danger
                              : (sensor.waterLevel == WaterLevel.warning
                                  ? AppTheme.warning
                                  : AppTheme.success)),
                      title: 'Leak Status',
                      value: !sensor.isConnected
                          ? 'STANDBY'
                          : (sensor.waterLevel == WaterLevel.critical
                              ? 'CRITICAL'
                              : (sensor.waterLevel == WaterLevel.warning
                                  ? 'WARNING'
                                  : 'NORMAL')),
                      subtitle: !sensor.isConnected
                          ? 'Connect Bluetooth'
                          : (sensor.waterLevel == WaterLevel.critical
                              ? 'Auto Cutoff Active'
                              : 'Sensors Safe'),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 20),

              // ── Master AC Power Control Tile (Direct ON/OFF) ──────────────
              _MasterAcControlCard(sensor: sensor, bt: bt)
                  .animate()
                  .fadeIn(delay: 300.ms)
                  .slideY(begin: 0.1),

              const SizedBox(height: 24),

              // ── Featured HVAC Fault & Power Diagnostics Banner ───────────
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DiagnosticsScreen()),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.analytics_rounded, color: Color(0xFF00E5FF), size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'AI HEALTH & DIAGNOSTICS',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${sensor.systemHealthIndex}%',
                                    style: GoogleFonts.orbitron(
                                      color: const Color(0xFF00E5FF),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Current Sensors • Freon Health • Predictive Faults',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF94A3B8),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF94A3B8), size: 14),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 320.ms),

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
    final isCritical = sensor.waterLevel == WaterLevel.critical;

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
                    !sensor.isConnected
                        ? 'Hardware Offline • Relay Disengaged'
                        : (isOn ? 'Compressor Active • Relay Closed' : 'Standby Mode • Relay Open'),
                    style: GoogleFonts.plusJakartaSans(
                      color: !sensor.isConnected
                          ? AppTheme.textMuted
                          : (isOn ? AppTheme.success : AppTheme.textSecondary),
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
                  color: !sensor.isConnected
                      ? const Color(0xFFF1F5F9)
                      : (isOn ? AppTheme.successLight : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: !sensor.isConnected
                        ? AppTheme.border
                        : (isOn ? AppTheme.success.withValues(alpha: 0.3) : AppTheme.border),
                  ),
                ),
                child: Text(
                  !sensor.isConnected ? 'OFFLINE' : (isOn ? 'RUNNING' : 'STOPPED'),
                  style: GoogleFonts.plusJakartaSans(
                    color: !sensor.isConnected
                        ? AppTheme.textMuted
                        : (isOn ? const Color(0xFF065F46) : AppTheme.textSecondary),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          if (!sensor.isConnected) ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BluetoothScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bluetooth_disabled_rounded, color: AppTheme.textSecondary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Bluetooth Offline: Connect to ESP32 to control AC compressor relay.',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.textSecondary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.textMuted),
                  ],
                ),
              ),
            ),
          ] else if (isCritical) ...[
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

          const SizedBox(height: 16),

          // Realistic Interactive Split AC Indoor Unit
          RealisticSplitAcUnit(
            isOn: isOn,
            canControl: canControl,
            temperature: sensor.temperature,
            onTogglePower: () {
              if (canControl) {
                if (isOn) {
                  sensor.turnACOff();
                  bt.sendCommand('AC:OFF');
                } else {
                  sensor.turnACOn();
                  bt.sendCommand('AC:ON');
                }
              }
            },
          ),

          const SizedBox(height: 16),

          // Two Modern Action Pills: Turn ON & Turn OFF
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: canControl && !isOn
                        ? const LinearGradient(
                            colors: [Color(0xFF059669), Color(0xFF10B981)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: canControl && !isOn ? null : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: canControl && !isOn
                        ? [
                            BoxShadow(
                              color: const Color(0xFF10B981).withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: ElevatedButton.icon(
                    onPressed: canControl && !isOn
                        ? () {
                            sensor.turnACOn();
                            bt.sendCommand('AC:ON');
                          }
                        : null,
                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                    label: Text(
                      'START AC',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.transparent,
                      disabledForegroundColor: const Color(0xFF94A3B8),
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: isOn
                        ? const LinearGradient(
                            colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isOn ? null : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isOn
                        ? [
                            BoxShadow(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: ElevatedButton.icon(
                    onPressed: isOn
                        ? () {
                            sensor.turnACOff();
                            bt.sendCommand('AC:OFF');
                          }
                        : null,
                    icon: const Icon(Icons.stop_rounded, size: 20),
                    label: Text(
                      'STOP AC',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.transparent,
                      disabledForegroundColor: const Color(0xFF94A3B8),
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
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
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
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

// ─── Status Capsule ──────────────────────────────────────────────────────────

class _SystemStatusCard extends StatelessWidget {
  final String status;
  final SensorData sensor;

  const _SystemStatusCard({required this.status, required this.sensor});

  @override
  Widget build(BuildContext context) {
    final isCritical = sensor.waterLevel == WaterLevel.critical;
    final color = !sensor.isConnected
        ? const Color(0xFF64748B)
        : (isCritical ? AppTheme.danger : AppTheme.success);
    final bg = !sensor.isConnected
        ? const Color(0xFFF1F5F9)
        : (isCritical ? AppTheme.dangerLight : AppTheme.successLight);
    final icon = !sensor.isConnected
        ? Icons.bluetooth_disabled_rounded
        : (isCritical ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded);

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
            icon,
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
