import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';

import '../theme/app_theme.dart';

class ChartRenderUtils {
  static Future<Uint8List?> renderChartToImage(Map<DateTime, double> historicalScores) async {
    if (historicalScores.isEmpty) return null;
    
    // Sort by date just to be safe
    final sortedEntries = historicalScores.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final minX = sortedEntries.first.key.millisecondsSinceEpoch.toDouble();
    final maxX = sortedEntries.last.key.millisecondsSinceEpoch.toDouble();
    final spots = sortedEntries.map((e) => FlSpot(e.key.millisecondsSinceEpoch.toDouble(), e.value)).toList();

    final chartWidget = Container(
      width: 600,
      height: 300,
      color: AppTheme.bgSurfaceRaised,
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: LineChart(
        LineChartData(
          minX: minX,
          maxX: maxX,
          minY: 0,
          maxY: 100,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppTheme.borderDefault,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 25,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      value.toInt().toString(),
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                      textAlign: TextAlign.right,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                  if (value == minX || value == maxX) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat.Md().format(date),
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppTheme.accentGrowthFill,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
        duration: Duration.zero,
      ),
    );

    final repaintBoundary = RenderRepaintBoundary();
    final logicalSize = const Size(600, 300);
    
    // We handle ViewConfiguration differently depending on Flutter version to avoid the 'size' named param error.
    // However, since we are directly accessing flutter SDK ViewConfiguration, we can use the latest.
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final renderView = RenderView(
      view: view,
      child: RenderPositionedBox(alignment: Alignment.center, child: repaintBoundary),
      configuration: ViewConfiguration(
        logicalConstraints: BoxConstraints.tight(logicalSize),
        devicePixelRatio: 2.0,
      ),
    );

    final pipelineOwner = PipelineOwner();
    final buildOwner = BuildOwner(focusManager: FocusManager());

    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: Directionality(
        textDirection: ui.TextDirection.ltr,
        child: Material(
          child: chartWidget,
        ),
      ),
    ).attachToRenderTree(buildOwner);

    buildOwner.buildScope(rootElement);
    buildOwner.finalizeTree();

    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    final image = await repaintBoundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }
}
