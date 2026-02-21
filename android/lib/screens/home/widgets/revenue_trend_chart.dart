import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';

/// Revenue Trend Chart - 7-day revenue trend line chart
class RevenueTrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final bool isLoading;
  final String? error;

  const RevenueTrendChart({
    super.key,
    required this.data,
    this.isLoading = false,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 250,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (error != null) {
      return Container(
        height: 250,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.errorRed.withOpacity(0.3)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: AppTheme.errorRed,
              ),
              const SizedBox(height: 12),
              Text(
                error!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.errorRed,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (data.isEmpty) {
      return Container(
        height: 250,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.trending_up_outlined,
                size: 48,
                color: AppTheme.mediumGray,
              ),
              const SizedBox(height: 12),
              Text(
                'No revenue data available',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Revenue Trend',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Last 7 days',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppTheme.chartGridColor,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < data.length) {
                          final date = DateTime.parse(data[index]['date']);
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 8,
                            child: Text(
                              DateFormat('E').format(date),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                color: AppTheme.chartAxisColor,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 4,
                          child: Text(
                            value.toInt() == 0 ? '0' : 'Rs${value.toInt()}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              color: AppTheme.chartAxisColor,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: AppTheme.chartGridColor, width: 1),
                    left: BorderSide(color: AppTheme.chartGridColor, width: 1),
                    right: const BorderSide(color: Colors.transparent),
                    top: const BorderSide(color: Colors.transparent),
                  ),
                ),
                minX: 0,
                maxX: (data.length - 1).toDouble(),
                minY: 0,
                maxY: _calculateMaxY(),
                lineBarsData: [
                  LineChartBarData(
                    spots: data.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        (entry.value['revenue'] as num).toDouble(),
                      );
                    }).toList(),
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryBlue.withOpacity(0.8),
                        AppTheme.primaryBlue,
                      ],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppTheme.white,
                          strokeWidth: 2,
                          strokeColor: AppTheme.primaryBlue,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryBlue.withOpacity(0.1),
                          AppTheme.primaryBlue.withOpacity(0.05),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: AppTheme.darkGray,
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.x.toInt();
                        if (index >= 0 && index < data.length) {
                          final date = DateTime.parse(data[index]['date']);
                          final revenue = data[index]['revenue'] as num;
                          return LineTooltipItem(
                            '${DateFormat('MMM d').format(date)}\nRs.${revenue.toStringAsFixed(0)}',
                            const TextStyle(
                              color: AppTheme.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        }
                        return null;
                      }).toList();
                    },
                  ),
                  handleBuiltInTouches: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateMaxY() {
    if (data.isEmpty) return 100;
    final maxRevenue = data
        .map((item) => (item['revenue'] as num).toDouble())
        .reduce((a, b) => a > b ? a : b);
    // Add 20% padding to the top
    return (maxRevenue * 1.2).ceilToDouble();
  }
}