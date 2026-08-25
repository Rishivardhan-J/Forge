import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../providers/habit_provider.dart';
import '../../providers/insights_provider.dart';
import '../../theme/app_theme.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  String? _selectedHabitId; // null means aggregate

  @override
  Widget build(BuildContext context) {
    final habits = ref.watch(habitListProvider).value ?? [];
    final chartDataAsync = ref.watch(insightsChartProvider(_selectedHabitId));
    final frictionReportAsync = ref.watch(frictionReportProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      appBar: AppBar(
        title: const Text('Insights'),
        backgroundColor: AppTheme.bgBase,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
                child: Row(
                  children: [
                    _buildChip('All Habits', null),
                    const SizedBox(width: AppTheme.spacingSm),
                    ...habits.map((h) => Padding(
                          padding: const EdgeInsets.only(right: AppTheme.spacingSm),
                          child: _buildChip(h.name, h.id.toString()),
                        )),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: chartDataAsync.when(
              data: (data) => _buildChartSection(context, data),
              loading: () => const Padding(
                padding: EdgeInsets.all(AppTheme.spacingXl),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, st) => Padding(
                padding: const EdgeInsets.all(AppTheme.spacingXl),
                child: Center(child: Text('Error: $e')),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: Text(
                'Weekly Friction Report',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          frictionReportAsync.when(
            data: (report) => _buildFrictionReport(context, report),
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, st) => SliverToBoxAdapter(
              child: Center(child: Text('Error: $e')),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppTheme.spacingXl)),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String? habitId) {
    final isSelected = _selectedHabitId == habitId;
    return ChoiceChip(
      key: ValueKey(habitId ?? 'all'),
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedHabitId = habitId);
        }
      },
      selectedColor: AppTheme.bgSurfaceRaised,
      backgroundColor: AppTheme.bgBase,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.borderDefault : Colors.transparent,
      ),
    );
  }

  Widget _buildChartSection(BuildContext context, ChartData data) {
    if (data.historical.isEmpty) {
      return Container(
        height: 250,
        margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
        decoration: BoxDecoration(
          color: AppTheme.bgSurfaceRaised,
          borderRadius: AppTheme.radiusCard,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(double.infinity, 250),
              painter: _BaselineCurvePainter(),
            ),
            Text(
              'Habits take time to build.\nYour data will appear here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    // Prepare chart spots
    final allPoints = [...data.historical, ...data.projected];
    final minX = allPoints.first.date.millisecondsSinceEpoch.toDouble();
    final maxX = allPoints.last.date.millisecondsSinceEpoch.toDouble();

    final historicalSpots = data.historical.map((p) => FlSpot(p.date.millisecondsSinceEpoch.toDouble(), p.score)).toList();
    final projectedSpots = data.projected.isNotEmpty 
        ? [historicalSpots.last, ...data.projected.map((p) => FlSpot(p.date.millisecondsSinceEpoch.toDouble(), p.score))] 
        : <FlSpot>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 250,
          margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
          padding: const EdgeInsets.only(right: AppTheme.spacingLg, top: AppTheme.spacingLg, bottom: AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: AppTheme.bgSurfaceRaised,
            borderRadius: AppTheme.radiusCard,
          ),
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
                      // Only show a few labels
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
                  spots: historicalSpots,
                  isCurved: true,
                  color: AppTheme.accentGrowthFill,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                ),
                if (projectedSpots.isNotEmpty)
                  LineChartBarData(
                    spots: projectedSpots,
                    isCurved: true,
                    color: AppTheme.accentGrowthFill.withValues(alpha: 0.5),
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dashArray: [5, 5],
                    dotData: const FlDotData(show: false),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
          child: Text(
            data.notEnoughHistory
                ? "Not enough history yet to project forward."
                : "This is an illustrative projection based on your recent pattern — not a promise.",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildFrictionReport(BuildContext context, List<FrictionReportEntry> report) {
    if (report.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            decoration: BoxDecoration(
              color: AppTheme.bgSurfaceRaised,
              borderRadius: AppTheme.radiusCard,
            ),
            child: Text(
              "Not enough data yet — when you mark a habit missed, let us know if your environment was ready to start spotting patterns here.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final entry = report[index];
          return Padding(
            padding: const EdgeInsets.only(
                left: AppTheme.spacingLg, right: AppTheme.spacingLg, bottom: AppTheme.spacingMd),
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              decoration: BoxDecoration(
                color: AppTheme.bgSurfaceRaised,
                borderRadius: AppTheme.radiusCard,
              ),
              child: RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                  children: [
                    const TextSpan(text: 'You missed '),
                    TextSpan(
                      text: entry.habitName,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    TextSpan(text: ' ${entry.missedCount}× this week — '),
                    TextSpan(
                      text: '${entry.unreadyCount}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const TextSpan(text: ' of those had an unready environment.'),
                  ],
                ),
              ),
            ),
          );
        },
        childCount: report.length,
      ),
    );
  }
}

class _BaselineCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.borderStrong.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    path.moveTo(0, size.height * 0.8);

    // Draw a subtle logarithmic-style curve that flattens out
    path.quadraticBezierTo(
      size.width * 0.3, size.height * 0.7,
      size.width * 0.5, size.height * 0.4,
    );
    path.quadraticBezierTo(
      size.width * 0.8, size.height * 0.1,
      size.width, size.height * 0.05,
    );

    canvas.drawPath(path, paint);

    final paint2 = Paint()
      ..color = AppTheme.borderStrong.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path2 = Path();
    path2.moveTo(0, size.height * 0.9);
    path2.quadraticBezierTo(
      size.width * 0.4, size.height * 0.8,
      size.width * 0.7, size.height * 0.5,
    );
    path2.quadraticBezierTo(
      size.width * 0.9, size.height * 0.3,
      size.width, size.height * 0.2,
    );

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
