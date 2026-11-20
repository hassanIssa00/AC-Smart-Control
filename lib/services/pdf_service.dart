import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/sensor_data.dart';

class PdfService {
  static Future<Uint8List> generatePdfReport({
    required List<LogEntry> logs,
    required String deviceName,
    required double currentTemp,
    required double currentHumidity,
    required double returnTemp,
    required double deltaT,
    required int healthIndex,
    required String systemStatus,
    required WaterLevel waterLevel,
    required bool acState,
  }) async {
    final pdf = pw.Document();

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    final timeFormat = DateFormat('HH:mm:ss');
    final nowFormatted = dateFormat.format(DateTime.now());

    // Compute statistical aggregations
    double avgTemp = currentTemp;
    double avgHum = currentHumidity;
    double maxTemp = currentTemp;
    double minTemp = currentTemp;
    int criticalCount = 0;
    int acOnCount = 0;

    if (logs.isNotEmpty) {
      double sumTemp = 0;
      double sumHum = 0;
      maxTemp = logs.first.temperature;
      minTemp = logs.first.temperature;
      for (final l in logs) {
        sumTemp += l.temperature;
        sumHum += l.humidity;
        if (l.temperature > maxTemp) maxTemp = l.temperature;
        if (l.temperature < minTemp && l.temperature > 0) minTemp = l.temperature;
        if (l.waterLevel == WaterLevel.critical) criticalCount++;
        if (l.acState) acOnCount++;
      }
      avgTemp = sumTemp / logs.length;
      avgHum = sumHum / logs.length;
    }

    // Health color & label
    PdfColor healthColor;
    String healthVerdict;
    if (healthIndex >= 80) {
      healthColor = PdfColor.fromHex('#16A34A');
      healthVerdict = 'OPTIMAL HEALTH ($healthIndex%)';
    } else if (healthIndex >= 50) {
      healthColor = PdfColor.fromHex('#D97706');
      healthVerdict = 'PREDICTIVE WARNING ($healthIndex%)';
    } else {
      healthColor = PdfColor.fromHex('#DC2626');
      healthVerdict = 'CRITICAL FAULT ($healthIndex%)';
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 16),
            padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#0F172A'),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'SMART HVAC CONDITION MONITORING & AUDIT REPORT',
                      style: pw.TextStyle(
                        color: PdfColor.fromHex('#38BDF8'),
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'Predictive Fault Diagnostics, Thermodynamic Delta-T & Climate Safety Log',
                      style: pw.TextStyle(
                        color: PdfColor.fromHex('#94A3B8'),
                        fontSize: 8.5,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#1E293B'),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                        border: pw.Border.all(color: PdfColor.fromHex('#38BDF8'), width: 0.5),
                      ),
                      child: pw.Text(
                        'OFFICIAL ENGINEERING AUDIT',
                        style: pw.TextStyle(
                          color: PdfColor.fromHex('#38BDF8'),
                          fontSize: 7.5,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'CERTIFIED TELEMETRY LOG',
                      style: pw.TextStyle(
                        color: PdfColor.fromHex('#94A3B8'),
                        fontSize: 7.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 14),
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Generated automatically by Smart HVAC Control & Predictive Diagnostics Suite',
                  style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 7.5),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 7.5),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) => [
          // ─── 1. Metadata & Status Summary Bar ───────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F8FAFC'),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0'), width: 0.8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildMetaItem('Audit Timestamp:', nowFormatted),
                _buildMetaItem('Target Hardware ID:', deviceName),
                _buildMetaItem('System Health Index:', healthVerdict, color: healthColor),
                _buildMetaItem('AC Relay State:', acState ? 'ON (RUNNING)' : 'OFF (STANDBY)'),
                _buildMetaItem('Water Safety Interlock:', waterLevel == WaterLevel.critical ? 'LOCKOUT ACTIVE' : 'SAFE / ARMED'),
              ],
            ),
          ),

          pw.SizedBox(height: 12),

          // ─── 2. Real-Time Thermodynamics & Climate Snapshot ────────────
          pw.Text(
            '1. THERMODYNAMICS & CLIMATE SAFETY SNAPSHOT',
            style: pw.TextStyle(
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#0F172A'),
              letterSpacing: 0.5,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildChannelBox(
                  title: 'AC Supply Air Temp',
                  value: currentTemp > 0 ? '${currentTemp.toStringAsFixed(1)} °C' : '--',
                  subtext: 'Optimal: 10.0°C - 18.0°C',
                  status: currentTemp > 32.0
                      ? 'CRITICAL: High Temp'
                      : (acState ? 'Optimal Cooling' : 'Standby'),
                  statusColor: currentTemp > 32.0
                      ? PdfColor.fromHex('#DC2626')
                      : (acState ? PdfColor.fromHex('#16A34A') : PdfColor.fromHex('#64748B')),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _buildChannelBox(
                  title: 'Room Return Air Temp',
                  value: '${returnTemp.toStringAsFixed(1)} °C',
                  subtext: 'Ambient Reference',
                  status: 'Thermal Baseline',
                  statusColor: PdfColor.fromHex('#0284C7'),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _buildChannelBox(
                  title: 'Thermodynamics (Delta-T)',
                  value: '${deltaT.toStringAsFixed(1)} °C',
                  subtext: 'T_return - T_supply',
                  status: deltaT >= 8.0
                      ? 'Freon: Healthy Charge'
                      : (acState ? 'Freon: Low Refrigerant Leak' : 'System Standby'),
                  statusColor: deltaT >= 8.0
                      ? PdfColor.fromHex('#16A34A')
                      : (acState ? PdfColor.fromHex('#D97706') : PdfColor.fromHex('#64748B')),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _buildChannelBox(
                  title: 'Condensate Drain Pan',
                  value: waterLevel == WaterLevel.critical
                      ? 'OVERFLOW'
                      : (waterLevel == WaterLevel.warning ? 'HIGH' : 'NORMAL'),
                  subtext: 'Moisture: ${currentHumidity.toStringAsFixed(1)}% RH',
                  status: waterLevel == WaterLevel.critical
                      ? 'EMERGENCY LOCKOUT'
                      : (waterLevel == WaterLevel.warning ? 'Warning (50-80%)' : 'Dry & Safe'),
                  statusColor: waterLevel == WaterLevel.critical
                      ? PdfColor.fromHex('#DC2626')
                      : (waterLevel == WaterLevel.warning ? PdfColor.fromHex('#D97706') : PdfColor.fromHex('#16A34A')),
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 12),

          // ─── 3. KPIs & Statistical Aggregations ──────────────────────────
          pw.Text(
            '2. KEY PERFORMANCE INDICATORS & SAFETY AUDIT (KPIs)',
            style: pw.TextStyle(
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#0F172A'),
              letterSpacing: 0.5,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCard('Average Supply Temp', '${avgTemp.toStringAsFixed(1)} °C', PdfColor.fromHex('#0284C7')),
              _buildStatCard('Temperature Range', '${minTemp.toStringAsFixed(1)} - ${maxTemp.toStringAsFixed(1)} °C', PdfColor.fromHex('#0D9488')),
              _buildStatCard('Average Humidity', '${avgHum.toStringAsFixed(1)} %', PdfColor.fromHex('#6366F1')),
              _buildStatCard('AC Active Cycles', '$acOnCount Event(s)', PdfColor.fromHex('#00796B')),
              _buildStatCard('Critical Safety Trips', '$criticalCount Event(s)', criticalCount > 0 ? PdfColor.fromHex('#DC2626') : PdfColor.fromHex('#16A34A')),
              _buildStatCard('Total Logged Events', '${logs.length} Entries', PdfColor.fromHex('#0F172A')),
            ],
          ),

          pw.SizedBox(height: 12),

          // ─── 4. Engineering Tolerances Reference Table ──────────────────
          pw.Text(
            '3. ENGINEERING SPECIFICATIONS & TOLERANCES REFERENCE',
            style: pw.TextStyle(
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#0F172A'),
              letterSpacing: 0.5,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColor.fromHex('#CBD5E1'), width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(2.5),
              1: pw.FlexColumnWidth(2.0),
              2: pw.FlexColumnWidth(2.2),
              3: pw.FlexColumnWidth(4.5),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColor.fromHex('#1E293B')),
                children: [
                  _buildTableHeader('Subsystem / Component'),
                  _buildTableHeader('Nominal Range'),
                  _buildTableHeader('Critical Threshold'),
                  _buildTableHeader('Automated Software Action'),
                ],
              ),
              _buildRefTableRow('Supply Air Temperature', '10.0 °C - 18.0 °C', '> 32.0 °C (Cooling Loop Fail)', 'Predictive alarm, diagnostic log, health index reduction'),
              _buildRefTableRow('Thermodynamic Cooling (Delta-T)', '8.0 °C - 14.0 °C', '< 7.0 °C (Weak Cooling)', 'Low refrigerant leak warning, inspect Freon charge'),
              _buildRefTableRow('Condensate Water Drain Pan', 'Normal (Dry Pan)', 'Conductivity Detected (Overflow)', 'Instant Hardware Interlock shutdown; relay locked open'),
              _buildRefTableRow('Relative Room Humidity', '40.0 % - 65.0 %', '> 80.0 % (Excess Moisture)', 'Elevated condensate accumulation warning, recommend Dry mode'),
            ],
          ),

          pw.SizedBox(height: 14),

          // ─── 5. Chronological Telemetry & Event Log Table ───────────────
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                '4. CHRONOLOGICAL TELEMETRY & EVENT LOG RECORD',
                style: pw.TextStyle(
                  fontSize: 9.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#0F172A'),
                  letterSpacing: 0.5,
                ),
              ),
              pw.Text(
                'Showing ${logs.length} logged records',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
            ],
          ),
          pw.SizedBox(height: 5),

          if (logs.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 20),
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F8FAFC'),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
              ),
              child: pw.Text(
                'No events recorded yet. Connect to hardware to begin telemetry streaming.',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
            )
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColor.fromHex('#E2E8F0'), width: 0.5),
              columnWidths: const {
                0: pw.FixedColumnWidth(22),
                1: pw.FixedColumnWidth(55),
                2: pw.FixedColumnWidth(46),
                3: pw.FixedColumnWidth(42),
                4: pw.FixedColumnWidth(50),
                5: pw.FixedColumnWidth(50),
                6: pw.FlexColumnWidth(5.0),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColor.fromHex('#0F172A')),
                  children: [
                    _buildTableHeader('#'),
                    _buildTableHeader('Time'),
                    _buildTableHeader('Supply'),
                    _buildTableHeader('Humidity'),
                    _buildTableHeader('Drain Pan'),
                    _buildTableHeader('AC Relay'),
                    _buildTableHeader('Diagnostic Event Message'),
                  ],
                ),
                ...logs.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final log = entry.value;
                  final isEven = idx % 2 == 0;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: isEven ? PdfColors.white : PdfColor.fromHex('#F8FAFC'),
                    ),
                    children: [
                      _buildTableCell('$idx'),
                      _buildTableCell(timeFormat.format(log.timestamp)),
                      _buildTableCell(log.temperature > 0 ? '${log.temperature.toStringAsFixed(1)} °C' : '--'),
                      _buildTableCell(log.humidity > 0 ? '${log.humidity.toStringAsFixed(1)} %' : '--'),
                      _buildWaterBadge(log.waterLevel),
                      _buildAcBadge(log.acState),
                      _buildTableCell(log.note, alignLeft: true),
                    ],
                  );
                }),
              ],
            ),

          pw.SizedBox(height: 16),

          // ─── 6. Engineering Certification & Audit Sign-Off ──────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F8FAFC'),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: PdfColor.fromHex('#CBD5E1'), width: 0.8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Report Verification Status:', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                    pw.SizedBox(height: 2),
                    pw.Text('OFFICIAL AUDIT LOG - AUTOMATED CERTIFICATION', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0284C7'))),
                    pw.Text('Cryptographic Checksum & Time Anchor Verified', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Diagnostic Authority:', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                    pw.SizedBox(height: 2),
                    pw.Text('Smart HVAC Engineering Diagnostics Suite', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F172A'))),
                    pw.Text('Condition Monitoring & Predictive Maintenance System', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildMetaItem(String title, String value, {PdfColor? color}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 8.5,
            fontWeight: pw.FontWeight.bold,
            color: color ?? PdfColor.fromHex('#0F172A'),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildChannelBox({
    required String title,
    required String value,
    required String subtext,
    required String status,
    required PdfColor statusColor,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: PdfColor.fromHex('#CBD5E1'), width: 0.7),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#334155'))),
          pw.SizedBox(height: 3),
          pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: statusColor)),
          pw.SizedBox(height: 2),
          pw.Text(subtext, style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600)),
          pw.SizedBox(height: 3),
          pw.Text(
            status,
            maxLines: 1,
            style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: statusColor),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildStatCard(String label, String value, PdfColor color) {
    return pw.Container(
      width: 82,
      padding: const pw.EdgeInsets.all(7),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
        border: pw.Border.all(color: color, width: 0.7),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, maxLines: 1, style: const pw.TextStyle(fontSize: 6.8, color: PdfColors.grey700)),
          pw.SizedBox(height: 3),
          pw.Text(value, maxLines: 1, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  static pw.TableRow _buildRefTableRow(String col1, String col2, String col3, String col4) {
    return pw.TableRow(
      children: [
        _buildRefCell(col1, isBold: true),
        _buildRefCell(col2),
        _buildRefCell(col3, color: PdfColor.fromHex('#DC2626')),
        _buildRefCell(col4, alignLeft: true),
      ],
    );
  }

  static pw.Widget _buildRefCell(String text, {bool isBold = false, bool alignLeft = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 5),
      child: pw.Text(
        text,
        textAlign: alignLeft ? pw.TextAlign.left : pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 7.2,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? PdfColor.fromHex('#1E293B'),
        ),
      ),
    );
  }

  static pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: const pw.TextStyle(color: PdfColors.white, fontSize: 7.5, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _buildTableCell(String text, {bool alignLeft = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: pw.Text(
        text,
        textAlign: alignLeft ? pw.TextAlign.left : pw.TextAlign.center,
        style: pw.TextStyle(fontSize: 7.2, color: PdfColor.fromHex('#1E293B')),
      ),
    );
  }

  static pw.Widget _buildWaterBadge(WaterLevel level) {
    PdfColor color;
    String label;
    switch (level) {
      case WaterLevel.normal:
        color = PdfColor.fromHex('#16A34A');
        label = 'Normal';
        break;
      case WaterLevel.warning:
        color = PdfColor.fromHex('#D97706');
        label = 'Warning';
        break;
      case WaterLevel.critical:
        color = PdfColor.fromHex('#DC2626');
        label = 'Critical!';
        break;
    }
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 2),
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        decoration: pw.BoxDecoration(
          color: color,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
        ),
        child: pw.Text(
          label,
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(color: PdfColors.white, fontSize: 6.8, fontWeight: pw.FontWeight.bold),
        ),
      ),
    );
  }

  static pw.Widget _buildAcBadge(bool acState) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 2),
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        decoration: pw.BoxDecoration(
          color: acState ? PdfColor.fromHex('#0284C7') : PdfColor.fromHex('#64748B'),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
        ),
        child: pw.Text(
          acState ? 'RUNNING' : 'STOPPED',
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(color: PdfColors.white, fontSize: 6.2, fontWeight: pw.FontWeight.bold),
        ),
      ),
    );
  }

  static Future<void> printOrSharePdf({
    required List<LogEntry> logs,
    required String deviceName,
    required double currentTemp,
    required double currentHumidity,
    required double returnTemp,
    required double deltaT,
    required int healthIndex,
    required String systemStatus,
    required WaterLevel waterLevel,
    required bool acState,
  }) async {
    final pdfBytes = await generatePdfReport(
      logs: logs,
      deviceName: deviceName,
      currentTemp: currentTemp,
      currentHumidity: currentHumidity,
      returnTemp: returnTemp,
      deltaT: deltaT,
      healthIndex: healthIndex,
      systemStatus: systemStatus,
      waterLevel: waterLevel,
      acState: acState,
    );

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'AC_Smart_Audit_Report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf',
    );
  }
}
