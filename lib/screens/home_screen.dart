import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/connection_state_step.dart';
import '../providers/app_state_provider.dart';
import '../providers/signal_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/hero_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/waveform_chart.dart';
import 'terms_conditions_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showProfileModal(BuildContext context) {
    final appState = context.read<AppStateProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.primarySurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.bottomSheet)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryAccent, width: 2),
                ),
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.softBlue,
                  child: const Icon(Icons.person, size: 40, color: AppColors.primaryAccent),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                appState.researcherName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryText),
              ),
              const SizedBox(height: 2),
              Text(
                appState.researcherRole,
                style: const TextStyle(fontSize: 13, color: AppColors.secondaryBlue, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                appState.institution,
                style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondarySurface,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _ProfileStatItem(title: 'Active Engine', value: appState.activeEngine.name.toUpperCase()),
                    const _VerticalDivider(),
                    _ProfileStatItem(title: 'Channels', value: '${appState.eegConfig.channelCount} CH'),
                    const _VerticalDivider(),
                    _ProfileStatItem(title: 'Sampling', value: '${appState.eegConfig.samplingRate} Hz'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryText,
                        side: const BorderSide(color: AppColors.cardBorder),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.button),
                        ),
                      ),
                      icon: const Icon(Icons.gavel_outlined, size: 16),
                      label: const Text('Terms & Safety', style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TermsConditionsScreen(showAcceptButton: false),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.button),
                        ),
                      ),
                      icon: const Icon(Icons.logout, size: 16, color: AppColors.error),
                      label: const Text('Sign Out', style: TextStyle(fontSize: 12, color: AppColors.error)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        appState.logout();
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
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
    final isBroadcasting = signalProvider.isStreamingSignal || step == ConnectionStateStep.streaming;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          children: [
            GestureDetector(
              onTap: () => _showProfileModal(context),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isBroadcasting ? AppColors.success : AppColors.cardBorder,
                    width: 1.5,
                  ),
                ),
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.softBlue,
                  child: const Icon(Icons.person, size: 20, color: AppColors.primaryAccent),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appState.researcherName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryText),
                  ),
                  Text(
                    appState.institution,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.sensors,
              color: isBroadcasting ? AppColors.success : AppColors.secondaryText,
            ),
            tooltip: 'Wireless Telemetry Broadcast',
            onPressed: () => Navigator.pushNamed(context, '/connection'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Primary Telemetry Flow Control Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: isBroadcasting ? AppColors.success.withValues(alpha: 0.5) : AppColors.cardBorder,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isBroadcasting ? AppColors.success.withValues(alpha: 0.08) : Colors.transparent,
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: isBroadcasting ? AppColors.success : AppColors.mutedText,
                            shape: BoxShape.circle,
                            boxShadow: isBroadcasting
                                ? [
                                    BoxShadow(
                                      color: AppColors.success.withValues(alpha: 0.6),
                                      blurRadius: 6,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          step.displayLabel.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            letterSpacing: 0.5,
                            color: isBroadcasting ? AppColors.success : AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.secondarySurface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Text(
                        signalProvider.isBleConnected ? 'BLE CONNECTED' : 'BLE ADVERTISING',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isBroadcasting ? AppColors.primarySurface : AppColors.primaryAccent,
                      foregroundColor: Colors.white,
                      side: isBroadcasting ? const BorderSide(color: AppColors.success, width: 1.5) : BorderSide.none,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    icon: Icon(
                      isBroadcasting ? Icons.radio_button_checked : Icons.sensors,
                      color: isBroadcasting ? AppColors.success : Colors.white,
                      size: 18,
                    ),
                    label: Text(
                      isBroadcasting ? 'ACTIVE WIRELESS BROADCAST • CONFIGURE' : 'START WIRELESS TELEMETRY',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: isBroadcasting ? AppColors.success : Colors.white,
                      ),
                    ),
                    onPressed: () => Navigator.pushNamed(context, '/connection'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          HeroCard(
            title: 'WEEKLY RESEARCH TARGET',
            progressPercent: '84%',
            subtitle: 'of weekly EEG/VEP signal simulation target completed',
            highlightText: '14 validation sessions completed',
            onAction: () => Navigator.pushNamed(context, '/simulations'),
          ),
          const SizedBox(height: 18),

          // High-Contrast System Telemetry Dashboard
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'SYSTEM TELEMETRY SUMMARY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.secondaryBlue,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.secondarySurface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'REAL-TIME',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.mutedText),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _CompactMetric(title: 'Signal Engine', value: appState.activeEngine.name.toUpperCase()),
                    _CompactMetric(title: 'Sampling', value: '${diag.configuredSamplingRate} Hz'),
                    _CompactMetric(title: 'Channels', value: '${signalProvider.channelCount} CH'),
                    _CompactMetric(title: 'Transports', value: 'BLE + Wi-Fi'),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: AppColors.cardBorder),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _CompactMetric(
                      title: 'Link State',
                      value: signalProvider.isVerifiedConnected ? 'Connected' : 'Advertising',
                      valueColor: signalProvider.isVerifiedConnected ? AppColors.success : AppColors.secondaryText,
                    ),
                    _CompactMetric(
                      title: 'Streaming',
                      value: signalProvider.isStreamingSignal ? 'Active' : 'Idle',
                      valueColor: signalProvider.isStreamingSignal ? AppColors.success : AppColors.secondaryText,
                    ),
                    _CompactMetric(title: 'Packets Sent', value: '${diag.framesSent}'),
                    _CompactMetric(title: 'Live Rate', value: '${diag.actualTransmissionRate.toStringAsFixed(1)} Hz'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          const Text(
            'Biopotential Metrics',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primaryText),
          ),
          const SizedBox(height: 10),
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
                subtitle: 'Standard 10-20',
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
          const SizedBox(height: 18),

          // Medical Precision Live Oscilloscope
          Container(
            height: 220,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.show_chart, color: AppColors.waveformCyan, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'LIVE 4-CHANNEL NEURAL WAVEFORMS',
                          style: TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.secondarySurface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Fp1 • Fp2 • C3 • C4',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: AppColors.waveformCyan,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: WaveformChart(channelData: signalProvider.waveformBuffer),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      color: AppColors.cardBorder,
    );
  }
}

class _CompactMetric extends StatelessWidget {
  final String title;
  final String value;
  final Color? valueColor;

  const _CompactMetric({
    required this.title,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.mutedText,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppColors.primaryText,
          ),
        ),
      ],
    );
  }
}