import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/scenario.dart';
import '../providers/app_state_provider.dart';
import '../providers/signal_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/waveform_chart.dart';

class SimulationsScreen extends StatelessWidget {
  const SimulationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final signalProvider = context.watch<SignalProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulations & Signal Inputs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.medication_liquid, color: Colors.tealAccent),
            tooltip: '20 Patient Conditions',
            onPressed: () => Navigator.pushNamed(context, '/patient-presets'),
          ),
          IconButton(
            icon: const Icon(Icons.dashboard_customize_outlined),
            tooltip: 'Scenario Presets',
            onPressed: () => Navigator.pushNamed(context, '/scenarios'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Banner for Pyromatix & NeuroSync
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.indigo.shade900.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.indigo.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.settings_input_component, color: Colors.cyanAccent, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'PYROMATIX & NEUROSYNC INPUT CONTROLLER',
                        style: TextStyle(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        'Tune band amplitudes, frequencies, or apply 20 pre-configured patient conditions directly.',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  child: const Text('20 PRESETS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  onPressed: () => Navigator.pushNamed(context, '/patient-presets'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Engine Selector
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.secondaryBackground,
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (!appState.isStreaming) {
                        appState.setActiveEngine(ActiveEngine.eeg);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: appState.activeEngine == ActiveEngine.eeg
                            ? AppColors.primarySurface
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.button - 2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.waves,
                            size: 16,
                            color: appState.activeEngine == ActiveEngine.eeg
                                ? AppColors.primaryAccent
                                : AppColors.secondaryText,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'EEG Engine',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: appState.activeEngine == ActiveEngine.eeg
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: appState.activeEngine == ActiveEngine.eeg
                                  ? AppColors.primaryText
                                  : AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (!appState.isStreaming) {
                        appState.setActiveEngine(ActiveEngine.erp);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: appState.activeEngine == ActiveEngine.erp
                            ? AppColors.primarySurface
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.button - 2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.flash_on,
                            size: 16,
                            color: appState.activeEngine == ActiveEngine.erp
                                ? AppColors.primaryAccent
                                : AppColors.secondaryText,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ERP / VEP Engine',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: appState.activeEngine == ActiveEngine.erp
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: appState.activeEngine == ActiveEngine.erp
                                  ? AppColors.primaryText
                                  : AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Live Signal Monitor Card
          Container(
            height: 220,
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
                          'LIVE SIGNAL MONITOR',
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
                      '${appState.eegConfig.channelCount} CH • ${appState.eegConfig.samplingRate} Hz',
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

          // Configuration Cards Navigation
          _ConfigOptionTile(
            icon: Icons.personal_injury,
            title: '20 Patient Condition Presets',
            subtitle: 'Epilepsy, ADHD, Alzheimer\'s, Sleep Stages, Depression, etc.',
            onTap: () => Navigator.pushNamed(context, '/patient-presets'),
          ),
          const SizedBox(height: 12),
          _ConfigOptionTile(
            icon: Icons.tune,
            title: 'Manual Signal & Noise Tuning',
            subtitle: 'Directly edit Delta, Theta, Alpha, Beta, Gamma & Artifacts',
            onTap: () => Navigator.pushNamed(context, '/eeg-config'),
          ),
          const SizedBox(height: 12),
          _ConfigOptionTile(
            icon: Icons.bolt,
            title: 'ERP / VEP Parameters',
            subtitle: 'Configure N75, P100, N145 latency, amplitude & jitter',
            onTap: () => Navigator.pushNamed(context, '/erp-config'),
          ),
        ],
      ),
    );
  }
}

class _ConfigOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ConfigOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.softBlue,
            borderRadius: BorderRadius.circular(AppRadius.chip),
          ),
          child: Icon(icon, color: AppColors.primaryAccent),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.secondaryText,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.mutedText),
      ),
    );
  }
}