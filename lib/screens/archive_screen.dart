import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/sensor_data.dart';
import '../services/pdf_service.dart';
import '../theme/app_theme.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  bool _isExporting = false;

  final DateFormat _timeFormat = DateFormat('hh:mm:ss a');
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');

  @override
  Widget build(BuildContext context) {
    final sensor = context.watch<SensorData>();
    final allLogs = sensor.logs;

    final filteredLogs = allLogs.where((log) {
      if (_selectedFilter == 'Alerts') {
        if (log.waterLevel == WaterLevel.normal) return false;
      } else if (_selectedFilter == 'AC Control') {
        if (!log.note.toLowerCase().contains('ac') &&
            !log.note.toLowerCase().contains('relay')) {
          return false;
        }
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return log.note.toLowerCase().contains(q) ||
            log.id.toLowerCase().contains(q) ||
            log.waterLevelLabel.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.history_edu_rounded,
                      color: AppTheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TELEMETRY ARCHIVE',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Historical Audit & PDF Reports',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _confirmClear(context, sensor),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: const Icon(
                        Icons.delete_sweep_outlined,
                        color: AppTheme.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 16),

            // ─── PDF Export Banner ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.picture_as_pdf_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Engineering PDF Report',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Certified Diagnostics & Telemetry Audit',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _isExporting ? null : () => _exportPdf(sensor),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryDark,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isExporting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primary,
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.download_rounded, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'Export',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 150.ms),

            const SizedBox(height: 14),

            // ─── Stat Counters ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildStatChip(
                    label: 'TOTAL LOGS',
                    value: '${allLogs.length}',
                    color: AppTheme.primary,
                    bg: AppTheme.primaryLight,
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    label: 'ALERTS',
                    value:
                        '${allLogs.where((l) => l.waterLevel != WaterLevel.normal).length}',
                    color: AppTheme.warning,
                    bg: AppTheme.warningLight,
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    label: 'AC EVENTS',
                    value: '${allLogs.where((l) => l.acState).length}',
                    color: AppTheme.success,
                    bg: AppTheme.successLight,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 12),

            // ─── Search Bar ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search logs, events, levels...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppTheme.textMuted,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ─── Filter Tabs ───────────────────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: ['All', 'Alerts', 'AC Control'].map((filter) {
                  final isSel = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: isSel,
                      onSelected: (_) =>
                          setState(() => _selectedFilter = filter),
                      selectedColor: AppTheme.primaryLight,
                      backgroundColor: Colors.white,
                      labelStyle: GoogleFonts.plusJakartaSans(
                        color:
                            isSel ? AppTheme.primary : AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight:
                            isSel ? FontWeight.w700 : FontWeight.w500,
                      ),
                      side: BorderSide(
                        color: isSel ? AppTheme.primary : AppTheme.border,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 10),

            // ─── Timeline List ─────────────────────────────────────────────
            Expanded(
              child: filteredLogs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.feed_outlined,
                            size: 48,
                            color: AppTheme.textMuted.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'No logs found',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Telemetry data will record here in real-time',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
                      itemCount: filteredLogs.length,
                      itemBuilder: (ctx, idx) {
                        final log = filteredLogs[idx];
                        return _LightLogItemCard(
                          log: log,
                          dateFormat: _dateFormat,
                          timeFormat: _timeFormat,
                        ).animate().fadeIn(delay: (idx * 30).ms);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required String label,
    required String value,
    required Color color,
    required Color bg,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.5,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportPdf(SensorData sensor) async {
    setState(() => _isExporting = true);
    try {
      await PdfService.printOrSharePdf(
        logs: sensor.logs,
        deviceName: sensor.connectedDevice.isNotEmpty
            ? sensor.connectedDevice
            : 'ESP32_AC_SMART',
        currentTemp: sensor.temperature,
        currentHumidity: sensor.humidity,
        returnTemp: sensor.returnTemperature,
        deltaT: sensor.deltaT,
        healthIndex: sensor.systemHealthIndex,
        systemStatus: sensor.systemStatus,
        waterLevel: sensor.waterLevel,
        acState: sensor.acOn,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _confirmClear(BuildContext context, SensorData sensor) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Clear Archive?',
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'This will wipe all currently recorded log entries. This action cannot be undone.',
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.textSecondary,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              sensor.clearLogs();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

class _LightLogItemCard extends StatelessWidget {
  final LogEntry log;
  final DateFormat dateFormat;
  final DateFormat timeFormat;

  const _LightLogItemCard({
    required this.log,
    required this.dateFormat,
    required this.timeFormat,
  });

  @override
  Widget build(BuildContext context) {
    Color waterColor = AppTheme.success;
    Color waterBg = AppTheme.successLight;
    if (log.waterLevel == WaterLevel.warning) {
      waterColor = AppTheme.warning;
      waterBg = AppTheme.warningLight;
    }
    if (log.waterLevel == WaterLevel.critical) {
      waterColor = AppTheme.danger;
      waterBg = AppTheme.dangerLight;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: log.waterLevel == WaterLevel.critical
              ? AppTheme.danger.withValues(alpha: 0.4)
              : AppTheme.border,
          width: log.waterLevel == WaterLevel.critical ? 1.5 : 1,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  log.id,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${timeFormat.format(log.timestamp)} • ${dateFormat.format(log.timestamp)}',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: log.acState ? AppTheme.successLight : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: log.acState
                        ? AppTheme.success.withValues(alpha: 0.3)
                        : AppTheme.border,
                  ),
                ),
                child: Text(
                  log.acState ? 'AC ON' : 'AC OFF',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: log.acState ? const Color(0xFF065F46) : AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Text(
            log.note,
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              _buildMetricBadge(
                icon: Icons.thermostat_rounded,
                label: '${log.temperature.toStringAsFixed(1)}°C',
                color: const Color(0xFF0284C7),
                bg: const Color(0xFFE0F2FE),
              ),
              const SizedBox(width: 8),
              _buildMetricBadge(
                icon: Icons.water_drop_rounded,
                label: '${log.humidity.toStringAsFixed(1)}%',
                color: const Color(0xFF6366F1),
                bg: const Color(0xFFEEF2FF),
              ),
              const SizedBox(width: 8),
              _buildMetricBadge(
                icon: Icons.water_damage_rounded,
                label: 'Leak: ${log.waterLevelLabel}',
                color: waterColor,
                bg: waterBg,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBadge({
    required IconData icon,
    required String label,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
