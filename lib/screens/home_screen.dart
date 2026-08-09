import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/connection_state_step.dart';
import '../providers/app_state_provider.dart';
import '../providers/signal_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/hero_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/waveform_chart.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showProfileModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.primarySurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.softBlue,
                child: const Icon(Icons.person, size: 48, color: AppColors.primaryAccent),
              ),
              const SizedBox(height: 12),
              const Text(
                'Barathwaj R.',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryText),
              ),
              const Text('Biomedical Signal Engineer', style: TextStyle(fontSize: 13, color: AppColors.secondaryText)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondaryBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    _ProfileStatItem(title: 'Signal Engine', value: 'EEG / VEP'),
                    _ProfileStatItem(title: 'Channels', value: '4 CH (250 Hz)'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.settings),
                  label: const Text('Manage Connectivity'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushNamed(context, '/connection');
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final signalProvider = context.watch<SignalProvider>();
    final step = signalProvider.connectionStep;
    final diag = signalProvider.diagnostics;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          children: [
            GestureDetector(
              onTap: () => _showProfileModal(context),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.softBlue,
                child: const Icon(Icons.person, size: 20, color: AppColors.primaryAccent),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Good morning, Researcher', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryText)),
                  Text('Pokidex Neural Platform', style: TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Connect via QR Scanner',
            onPressed: () => Navigator.pushNamed(context, '/connection'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Primary Connection Flow Button Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: step == ConnectionStateStep.streaming
                            ? Colors.tealAccent
                            : (signalProvider.isVerifiedConnected ? Colors.greenAccent : Colors.grey),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      step.displayLabel,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('CONNECT TO PYROSYNC', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => Navigator.pushNamed(context, '/connection'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          HeroCard(
            title: 'WEEKLY RESEARCH TARGET',
            progressPercent: '84%',
            subtitle: 'of weekly EEG/VEP signal simulation target completed',
            highlightText: '14 validation sessions completed',
            onAction: () => Navigator.pushNamed(context, '/simulations'),
          ),
          const SizedBox(height: 20),

          // Compact Clean Signal Quality UI Dashboard (Req #17)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SYSTEM TELEMETRY SUMMARY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _CompactMetric(title: 'Signal Engine', value: appState.activeEngine.name.toUpperCase()),
                    _CompactMetric(title: 'Sampling', value: '${diag.configuredSamplingRate} Hz'),
                    _CompactMetric(title: 'Channels', value: '${signalProvider.channelCount} CH'),
                    _CompactMetric(title: 'Output', value: 'Wi-Fi'),
                  ],
                ),
                const Divider(height: 20, color: Colors.white10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _CompactMetric(title: 'Connection', value: signalProvider.isVerifiedConnected ? '● Connected' : '● Disconnected'),
                    _CompactMetric(title: 'Transmission', value: signalProvider.isStreamingSignal ? '● Streaming' : '● Idle'),
                    _CompactMetric(title: 'Packets', value: '${diag.framesSent}'),
                    _CompactMetric(title: 'Rate', value: '${diag.actualTransmissionRate.toStringAsFixed(1)} Hz'),
                    _CompactMetric(title: 'Queue', value: '${diag.sendQueueDepth}'),
                    _CompactMetric(title: 'Errors', value: '${diag.errorCount}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text('Current Metrics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primaryText)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.15,
            children: [
              StatCard(icon: Icons.memory, label: 'Sampling Rate', value: '${appState.eegConfig.samplingRate}', unit: 'Hz', subtitle: 'Real-time'),
              StatCard(icon: Icons.graphic_eq, label: 'Noise Percent', value: appState.eegConfig.noisePercent.toStringAsFixed(1), unit: '%', subtitle: 'Pink+White', iconColor: AppColors.warning),
              StatCard(icon: Icons.alt_route, label: 'Channel Density', value: '${appState.eegConfig.channelCount}', unit: 'CH', subtitle: 'Standard', iconColor: AppColors.secondaryBlue),
              StatCard(icon: Icons.hub, label: 'Active Transports', value: 'Dual', subtitle: 'Wi-Fi + BLE', iconColor: AppColors.success),
            ],
          ),
          const SizedBox(height: 20),

          Container(
            height: 210,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(AppRadius.card)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(children: [Icon(Icons.show_chart, color: Colors.cyanAccent, size: 18), SizedBox(width: 8), Text('LIVE WAVEFORM MONITOR', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8))]),
                    Text('${appState.eegConfig.channelCount} CH', style: const TextStyle(fontFamily: 'monospace', color: Colors.white60, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8)),
                    child: WaveformChart(channelData: signalProvider.waveformBuffer),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStatItem extends StatelessWidget {
  final String title;
  final String value;
  const _ProfileStatItem({required this.title, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 11, color: AppColors.secondaryText)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
      ],
    );
  }
}

class _CompactMetric extends StatelessWidget {
  final String title;
  final String value;
  const _CompactMetric({required this.title, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 9, color: Colors.white54)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }
}