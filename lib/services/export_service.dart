// ignore_for_file: deprecated_member_use
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../models/habit.dart';
import '../models/habit_log.dart';
import '../utils/habit_utils.dart';
import '../utils/date_time_utils.dart';
import '../utils/chart_render_utils.dart';
import '../models/user_settings.dart';

class ExportService {
  static String generateCsvString(List<HabitLog> logs, List<Habit> habits) {
    final habitMap = {for (var h in habits) h.id.toString(): h.name};

    final buffer = StringBuffer();
    buffer.writeln('Habit Name,Date,Status,Backfilled');

    for (var log in logs) {
      final habitName = habitMap[log.habitId] ?? 'Unknown Habit';
      final dateStr = DateFormat('yyyy-MM-dd').format(log.date);
      final statusStr = log.status.name;
      final backfilledStr = log.isBackfilled ? 'Yes' : 'No';
      
      final safeName = '"${habitName.replaceAll('"', '""')}"';
      
      buffer.writeln('$safeName,$dateStr,$statusStr,$backfilledStr');
    }
    return buffer.toString();
  }

  static Future<bool> exportCsv(Isar isar) async {
    try {
      final logs = await isar.habitLogs.where().sortByDateDesc().findAll();
      final habits = await isar.habits.where().findAll();

      final csvString = generateCsvString(logs, habits);

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/forge_export_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csvString);

      final result = await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Forge CSV Export',
      );

      return result.status == ShareResultStatus.success;
    } catch (e) {
      debugPrint('CSV Export failed: $e');
      return false;
    }
  }

  static Future<bool> exportPdf(Isar isar) async {
    try {
      final pdf = pw.Document();

      final habits = await isar.habits.where().findAll();
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text('Forge Consistency Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 20),
            ];
          },
        ),
      );

      // We render each habit as a separate chunk to allow async image loading
      for (var habit in habits) {
        final logs = await isar.habitLogs.filter().habitIdEqualTo(habit.id.toString()).findAll();
        final today = DateTimeUtils.resolveAppToday(DateTime.now(), UserSettings().dayStartTime);
        final historyMap = HabitUtils.computeConsistencyScoreHistory(habit, logs, today);

        final sortedScores = historyMap.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
        final currentScore = sortedScores.isNotEmpty ? sortedScores.last.value : 0.0;
        final description = _getConsistencyDescription(currentScore);

        pw.Widget? chartWidget;
        if (historyMap.isNotEmpty) {
           final imageBytes = await ChartRenderUtils.renderChartToImage(historyMap);
           if (imageBytes != null) {
              chartWidget = pw.Image(pw.MemoryImage(imageBytes));
           }
        }

        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            build: (pw.Context context) {
              return [
                pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 20),
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(habit.name, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 8),
                      pw.Text('Current Score: ${(currentScore * 100).toStringAsFixed(1)}/100'),
                      pw.Text('Consistency: $description'),
                      pw.SizedBox(height: 12),
                      if (chartWidget != null) 
                        pw.Container(
                           height: 150,
                           child: chartWidget,
                        ),
                    ],
                  ),
                )
              ];
            }
          )
        );
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/forge_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());

      final result = await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Forge PDF Report',
      );

      return result.status == ShareResultStatus.success;
    } catch (e) {
      debugPrint('PDF Export failed: $e');
      return false;
    }
  }

  static String _getConsistencyDescription(double score) {
    if (score >= 0.9) return "Excellent";
    if (score >= 0.75) return "Strong";
    if (score >= 0.5) return "Building";
    if (score >= 0.25) return "Starting out";
    return "Needs attention";
  }
}
