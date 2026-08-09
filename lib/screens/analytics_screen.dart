import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedPeriod = 1; // 0: DAY, 1: WEEK, 2: MONTH

  List<FlSpot> _getChartData() {
    if (_selectedPeriod == 0) {
      return const [
        FlSpot(0, 10),
        FlSpot(4, 15),
        FlSpot(8, 22),
        FlSpot(12, 35),
        FlSpot(16, 28),
        FlSpot(20, 18),
        FlSpot(24, 12),
      ];
    } else if (_selectedPeriod == 1) {
      return const [
        FlSpot(0, 12),
        FlSpot(1, 18),
        FlSpot(2, 14),
        FlSpot(3, 28),
        FlSpot(4, 22),
        FlSpot(5, 34),
        FlSpot(6, 30),
      ];
    } else {
      return const [
        FlSpot(0, 8),
        FlSpot(1, 22),
        FlSpot(2, 38),
        FlSpot(3, 45),
      ];
    }
  }

  String _getAveragePower() {
    if (_selectedPeriod == 0) return '20.4 µV²/Hz';
    if (_selectedPeriod == 1) return '23.1 µV²/Hz';
    return '28.2 µV²/Hz';
  }

  String _getChangeText() {
    if (_selectedPeriod == 0) return '+1.8%';
    if (_selectedPeriod == 1) return '+4.2%';
    return '+9.5%';
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Activity'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Segmented Control: DAY | WEEK | MONTH
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.secondaryBackground,
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: Row(
              children: [
                _PeriodTab(
                  label: 'DAY',
                  isSelected: _selectedPeriod == 0,
                  onTap: () => setState(() => _selectedPeriod = 0),
                ),
                _PeriodTab(
                  label: 'WEEK',
                  isSelected: _selectedPeriod == 1,
                  onTap: () => setState(() => _selectedPeriod = 1),
                ),
                _PeriodTab(
                  label: 'MONTH',
                  isSelected: _selectedPeriod == 2,
                  onTap: () => setState(() => _selectedPeriod = 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Primary Dynamic Activity Chart Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Spectral Power Density',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.secondaryText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getAveragePower(),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryText,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.softBlue,
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.trending_up, size: 14, color: AppColors.primaryAccent),
                          const SizedBox(width: 4),
                          Text(
                            _getChangeText(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 180,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 10,
                        getDrawingHorizontalLine: (val) => FlLine(
                          color: AppColors.border,
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) {
                              if (_selectedPeriod == 0) {
                                final hour = val.toInt();
                                if (hour % 4 == 0) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      '$hour:00',
                                      style: const TextStyle(fontSize: 10, color: AppColors.mutedText),
                                    ),
                                  );
                                }
                              } else if (_selectedPeriod == 1) {
                                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                final idx = val.toInt();
                                if (idx >= 0 && idx < days.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      days[idx],
                                      style: const TextStyle(fontSize: 11, color: AppColors.mutedText),
                                    ),
                                  );
                                }
                              } else {
                                final wk = val.toInt() + 1;
                                if (wk <= 4) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      'Wk $wk',
                                      style: const TextStyle(fontSize: 11, color: AppColors.mutedText),
                                    ),
                                  );
                                }
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _getChartData(),
                          isCurved: true,
                          color: AppColors.primaryAccent,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.primaryAccent.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Dynamic Key Metrics Grid
          const Text(
            'Key Metrics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.15,
            children: [
              StatCard(
                icon: Icons.waves,
                label: 'Alpha Power',
                value: appState.eegConfig.alpha.amplitude.toStringAsFixed(1),
                unit: 'µV',
                subtitle: '${appState.eegConfig.alpha.frequency} Hz',
              ),
              StatCard(
                icon: Icons.timer_outlined,
                label: 'P100 Latency',
                value: appState.erpConfig.p100.latencyMs.toStringAsFixed(1),
                unit: 'ms',
                subtitle: '±${appState.erpConfig.jitterPercent.toInt()}% jitter',
                iconColor: AppColors.secondaryBlue,
              ),
              StatCard(
                icon: Icons.graphic_eq,
                label: 'Signal Noise',
                value: appState.eegConfig.noisePercent.toStringAsFixed(1),
                unit: '%',
                subtitle: appState.eegConfig.noisePercent < 8.0 ? 'Clean' : 'Noisy',
                iconColor: AppColors.success,
              ),
              StatCard(
                icon: Icons.memory,
                label: 'Channel Density',
                value: '${appState.eegConfig.channelCount}',
                unit: 'CH',
                subtitle: '${appState.eegConfig.samplingRate} Hz',
                iconColor: AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Activity & Interactive Sessions List
          const Text(
            'Recent Sessions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 12),

          _SessionRow(
            title: 'Eyes-Closed Rest Simulation',
            time: '09:00 AM – 09:15 AM',
            engine: 'EEG Engine',
            isCompleted: true,
            onTap: () {
              Navigator.pushNamed(context, '/eeg-config');
            },
          ),
          const SizedBox(height: 8),
          _SessionRow(
            title: 'Visual Evoked Potential Trial #14',
            time: '10:30 AM – 10:45 AM',
            engine: 'ERP / VEP Engine',
            isCompleted: true,
            onTap: () {
              Navigator.pushNamed(context, '/erp-config');
            },
          ),
          const SizedBox(height: 8),
          _SessionRow(
            title: 'Cognitive Load & Patient Preset',
            time: '02:00 PM – 02:30 PM',
            engine: 'Patient Presets',
            isCompleted: false,
            onTap: () {
              Navigator.pushNamed(context, '/patient-presets');
            },
          ),
        ],
      ),
    );
  }
}

class _PeriodTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primarySurface : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.button - 2),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primaryText : AppColors.secondaryText,
            ),
          ),
        ),
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  final String title;
  final String time;
  final String engine;
  final bool isCompleted;
  final VoidCallback onTap;

  const _SessionRow({
    required this.title,
    required this.time,
    required this.engine,
    required this.isCompleted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.softBlue
                    : AppColors.secondaryBackground,
                borderRadius: BorderRadius.circular(AppRadius.chip),
              ),
              child: Icon(
                isCompleted ? Icons.check_circle : Icons.hourglass_top,
                size: 20,
                color: isCompleted ? AppColors.primaryAccent : AppColors.mutedText,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$time • $engine',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.mutedText,
            ),
          ],
        ),
      ),
    );
  }
}