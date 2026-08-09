import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state_provider.dart';
import '../providers/signal_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/hero_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/status_chip.dart';
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
              Stack(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.softBlue,
                    child: const Icon(
                      Icons.person,
                      size: 48,
                      color: AppColors.primaryAccent,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.tealAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.verified, size: 16, color: Colors.black),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Barathwaj R.',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              const Text(
                'Lead Neural BCI Engineer',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.secondaryText,
                ),
              ),
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
                    _ProfileStatItem(title: 'Target Engine', value: 'Pyromatix & NeuroSync'),
                    _ProfileStatItem(title: 'Data Channels', value: '4 CH (EEG/VEP)'),
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
                  label: const Text('Manage Pyromatix & NeuroSync Node Settings'),
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
                child: const Icon(
                  Icons.person,
                  size: 20,
                  color: AppColors.primaryAccent,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Good morning, Researcher',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                  Text(
                    'Pokidex Neural Platform',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_ethernet),
            tooltip: 'Connection Settings',
            onPressed: () => Navigator.pushNamed(context, '/connection'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Contextual Headline
          const Text(
            'Discover your\nsignal progress',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText,
              height: 1.25,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),

          // Prominent Hero Card
          HeroCard(
            title: 'WEEKLY RESEARCH TARGET',
            progressPercent: '84%',
            subtitle: 'of weekly EEG/VEP signal simulation target completed',
            highlightText: '14 validation sessions completed',
            onAction: () => Navigator.pushNamed(context, '/simulations'),
          ),
          const SizedBox(height: 20),

          // Server Status Bar Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                StatusChip(
                  status: signalProvider.transportStatus,
                  connectedClients: signalProvider.connectedClientCount,
                ),
                const Spacer(),
                Text(
                  '${appState.packetsPerSecond} pkt/s',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.primaryAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBackground,
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  child: Text(
                    appState.activeEngine.name.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2-Column Metric Grid
          const Text(
            'Current Metrics',
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
                icon: Icons.memory,
                label: 'Sampling Rate',
                value: '${appState.eegConfig.samplingRate}',
                unit: 'Hz',
                subtitle: 'Real-time',
              ),
              StatCard(
                icon: Icons.graphic_eq,
                label: 'Noise Percent',
                value: appState.eegConfig.noisePercent.toStringAsFixed(1),
                unit: '%',
                subtitle: 'Pink+White',
                iconColor: AppColors.warning,
              ),
              StatCard(
                icon: Icons.alt_route,
                label: 'Channel Density',
                value: '${appState.eegConfig.channelCount}',
                unit: 'CH',
                subtitle: 'Standard',
                iconColor: AppColors.secondaryBlue,
              ),
              StatCard(
                icon: Icons.hub,
                label: 'Active Transports',
                value: 'Dual',
                subtitle: 'Wi-Fi + BLE',
                iconColor: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Live Waveform Monitor Card
          Container(
            height: 210,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.show_chart, color: Colors.cyanAccent, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'LIVE WAVEFORM MONITOR',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${appState.eegConfig.channelCount} CH',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: WaveformChart(
                      channelData: signalProvider.waveformBuffer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Manual Trigger Button if ERP mode
          if (appState.activeEngine == ActiveEngine.erp &&
              appState.isStreaming) ...[
            ElevatedButton.icon(
              onPressed: () {
                signalProvider.fireManualTrigger();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('VEP Trigger Fired!'),
                    duration: Duration(milliseconds: 600),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.touch_app),
              label: const Text(
                'MANUAL VEP TRIGGER',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: ElevatedButton.icon(
          onPressed: () async {
            if (appState.isStreaming) {
              await signalProvider.stopStreaming();
            } else {
              if (!signalProvider.isServerRunning) {
                await signalProvider.startServer();
              }
              await signalProvider.startStreaming();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: appState.isStreaming
                ? AppColors.error
                : AppColors.primaryAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
          ),
          icon: Icon(appState.isStreaming ? Icons.stop : Icons.play_arrow),
          label: Text(
            appState.isStreaming ? 'STOP STREAMING' : 'START DUAL STREAMING',
            style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
        ),
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
        Text(
          title,
          style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryText),
        ),
      ],
    );
  }
}