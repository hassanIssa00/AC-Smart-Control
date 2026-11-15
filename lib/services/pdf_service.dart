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
  }) async {
    final pdf = pw.Document();

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    final timeFormat = DateFormat('HH:mm:ss');
    final nowFormatted = dateFormat.format(DateTime.now());

    // Compute stats
    double avgTemp = 0;
    double avgHum = 0;
    double maxTemp = 0;
    int criticalCount = 0;
    int acOnCount = 0;

    if (logs.isNotEmpty) {
      double sumTemp = 0;
      double sumHum = 0;
      maxTemp = logs.first.temperature;
      for (final l in logs) {
        sumTemp += l.temperature;
        sumHum += l.humidity;
        if (l.temperature > maxTemp) maxTemp = l.temperature;
        if (l.waterLevel == WaterLevel.critical) criticalCount++;
        if (l.acState) acOnCount++;
      }
      avgTemp = sumTemp / logs.length;
      avgHum = sumHum / logs.length;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 20),
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
                      'AC SMART CONTROL SYSTEM',
                      style: pw.TextStyle(
                        color: PdfColor.fromHex('#38BDF8'),
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'ESP32 & Bluetooth Climate & Leakage Safety Audit Report',
                      style: pw.TextStyle(
                        color: PdfColor.fromHex('#94A3B8'),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'SUPERVISED BY',
                      style: pw.TextStyle(
                        color: PdfColor.fromHex('#94A3B8'),
                        fontSize: 8,
                        letterSpacing: 1.5,
                      ),
                    ),
                    pw.Text(
                      'Eng. Mahmoud Zayed',
                      style: pw.TextStyle(
                        color: PdfColor.fromHex('#FFFFFF'),
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
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
                  'Generated automatically by AC Smart Control • Developed by Eng. Mahmoud Zayed',
                  style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 8),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 8),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) => [
          // Meta info card
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F4F7FA'),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: PdfColor.fromHex('#D2D9E2'), width: 0.8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildMetaItem('Report Date', nowFormatted),
                _buildMetaItem('Hardware Unit', deviceName.isEmpty ? 'ESP32-BT' : deviceName),
                _buildMetaItem('Total Records', '${logs.length} Log Entries'),
                _buildMetaItem('Current Status', 'Live Synchronized'),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // KPI Stat Cards
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCard('Avg Temp', '${avgTemp.toStringAsFixed(1)} °C', PdfColor.fromHex('#0088AA')),
              _buildStatCard('Peak Temp', '${maxTemp.toStringAsFixed(1)} °C', PdfColor.fromHex('#E65100')),
              _buildStatCard('Avg Humidity', '${avgHum.toStringAsFixed(1)} %', PdfColor.fromHex('#5E35B1')),
              _buildStatCard('Critical Water Alerts', '$criticalCount Alert(s)', criticalCount > 0 ? PdfColor.fromHex('#C62828') : PdfColor.fromHex('#2E7D32')),
              _buildStatCard('AC Active Logs', '$acOnCount Event(s)', PdfColor.fromHex('#00796B')),
            ],
          ),
          pw.SizedBox(height: 20),

          // Table Title
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'RECORDED TELEMETRY LOGS',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#0D1B2A'),
                ),
              ),
              pw.Text(
                'Sorted by recent first',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              ),
            ],
          ),
          pw.SizedBox(height: 8),

          // Logs Table
          logs.isEmpty
              ? pw.Center(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.all(24),
                    child: pw.Text('No telemetry logs recorded yet.'),
                  ),
                )
              : pw.Table(
                  border: pw.TableBorder.all(color: PdfColor.fromHex('#E2E8F0'), width: 0.5),
                  columnWidths: {
                    0: const pw.FixedColumnWidth(45),
                    1: const pw.FixedColumnWidth(60),
                    2: const pw.FixedColumnWidth(60),
                    3: const pw.FixedColumnWidth(60),
                    4: const pw.FixedColumnWidth(70),
                    5: const pw.FixedColumnWidth(55),
                    6: const pw.FlexColumnWidth(2),
                  },
                  children: [
                    // Header Row
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColor.fromHex('#0D1B2A')),
                      children: [
                        _buildTableHeader('# ID'),
                        _buildTableHeader('Time'),
                        _buildTableHeader('Temp'),
                        _buildTableHeader('Humidity'),
                        _buildTableHeader('Water Level'),
                        _buildTableHeader('AC State'),
                        _buildTableHeader('Telemetry Event / Note'),
                      ],
                    ),
                    // Data Rows
                    ...logs.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final log = entry.value;
                      final isEven = idx % 2 == 0;
                      return pw.TableRow(
                        decoration: pw.BoxDecoration(
                          color: isEven ? PdfColors.white : PdfColor.fromHex('#F8FAFC'),
                        ),
                        children: [
                          _buildTableCell(log.id),
                          _buildTableCell(timeFormat.format(log.timestamp)),
                          _buildTableCell('${log.temperature.toStringAsFixed(1)}°C'),
                          _buildTableCell('${log.humidity.toStringAsFixed(1)}%'),
                          _buildWaterBadge(log.waterLevel),
                          _buildAcBadge(log.acState),
                          _buildTableCell(log.note, alignLeft: true),
                        ],
                      );
                    }),
                  ],
                ),

          pw.SizedBox(height: 24),

          // Engineering Signoff Section
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColor.fromHex('#CBD5E1')),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Report Verification Status:', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    pw.Text('OFFICIAL AUDIT LOG - CERTIFIED', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0088AA'))),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Project Lead Engineer:', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    pw.Text('Eng. Mahmoud Zayed', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0D1B2A'))),
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

  static pw.Widget _buildMetaItem(String title, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        pw.SizedBox(height: 2),
        pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0D1B2A'))),
      ],
    );
  }

  static pw.Widget _buildStatCard(String label, String value, PdfColor color) {
    return pw.Container(
      width: 95,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: color, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  static pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: const pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _buildTableCell(String text, {bool alignLeft = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      child: pw.Text(
        text,
        textAlign: alignLeft ? pw.TextAlign.left : pw.TextAlign.center,
        style: pw.TextStyle(fontSize: 7.5, color: PdfColor.fromHex('#1E293B')),
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
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        decoration: pw.BoxDecoration(
          color: color,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
        ),
        child: pw.Text(
          label,
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(color: PdfColors.white, fontSize: 7, fontWeight: pw.FontWeight.bold),
        ),
      ),
    );
  }

  static pw.Widget _buildAcBadge(bool acState) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        decoration: pw.BoxDecoration(
          color: acState ? PdfColor.fromHex('#0284C7') : PdfColor.fromHex('#64748B'),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
        ),
        child: pw.Text(
          acState ? 'RUNNING' : 'STOPPED',
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(color: PdfColors.white, fontSize: 6.5, fontWeight: pw.FontWeight.bold),
        ),
      ),
    );
  }

  static Future<void> printOrSharePdf({
    required List<LogEntry> logs,
    required String deviceName,
    required double currentTemp,
    required double currentHumidity,
  }) async {
    final pdfBytes = await generatePdfReport(
      logs: logs,
      deviceName: deviceName,
      currentTemp: currentTemp,
      currentHumidity: currentHumidity,
    );

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'AC_Smart_Report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf',
    );
  }
}

