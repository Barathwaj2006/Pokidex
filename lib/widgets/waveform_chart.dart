import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class WaveformChart extends StatelessWidget {
  final List<List<double>> channelData;
  final int maxSamples;
  final double channelOffset;

  static const List<Color> kChannelColors = [
    Color(0xFF4FC3F7),
    Color(0xFF81C784),
    Color(0xFFFFB74D),
    Color(0xFFBA68C8),
    Color(0xFFFF8A65),
    Color(0xFF4DB6AC),
    Color(0xFFF06292),
    Color(0xFFAED581),
  ];

  const WaveformChart({
    super.key,
    required this.channelData,
    this.maxSamples = 250,
    this.channelOffset = 60.0,
  });

  @override
  Widget build(BuildContext context) {
    if (channelData.isEmpty || channelData.every((ch) => ch.isEmpty)) {
      return _buildEmpty(context);
    }

    final lineBarsData = <LineChartBarData>[];

    for (int ch = 0; ch < channelData.length; ch++) {
      final buf = channelData[ch];
      if (buf.isEmpty) continue;

      final start = buf.length > maxSamples ? buf.length - maxSamples : 0;
      final spots = <FlSpot>[];
      for (int i = start; i < buf.length; i++) {
        final x = (i - start).toDouble();
        final y = buf[i] + ch * channelOffset;
        spots.add(FlSpot(x, y));
      }

      lineBarsData.add(LineChartBarData(
        spots: spots,
        isCurved: false,
        color: kChannelColors[ch % kChannelColors.length],
        barWidth: 1.2,
        isStrokeCapRound: false,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
      ));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: channelOffset,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.white.withValues(alpha: 0.05),
            strokeWidth: 1,
          ),
        ),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: lineBarsData,
        minX: 0,
        maxX: maxSamples.toDouble(),
        clipData: const FlClipData.all(),
        backgroundColor: Colors.transparent,
      ),
      duration: Duration.zero,
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.show_chart,
            size: 40,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 8),
          Text(
            'Start streaming to view waveform',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}