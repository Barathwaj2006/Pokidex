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
        title: const Text('Simulations'),
        actions: [
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
                        boxShadow: appState.activeEngine == ActiveEngine.eeg
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
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
                        boxShadow: appState.activeEngine == ActiveEngine.erp
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
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

          // Quick Presets Horizontal Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Simulation Presets',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/scenarios'),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _PresetChip(
                  label: 'REST',
                  scenario: Scenario.rest,
                  isSelected: appState.currentScenario == Scenario.rest,
                  onSelect: () => appState.applyScenario(Scenario.rest),
                ),
                _PresetChip(
                  label: 'RELAXED',
                  scenario: Scenario.relaxed,
                  isSelected: appState.currentScenario == Scenario.relaxed,
                  onSelect: () => appState.applyScenario(Scenario.relaxed),
                ),
                _PresetChip(
                  label: 'HIGH LOAD',
                  scenario: Scenario.highLoad,
                  isSelected: appState.currentScenario == Scenario.highLoad,
                  onSelect: () => appState.applyScenario(Scenario.highLoad),
                ),
                _PresetChip(
                  label: 'FATIGUE',
                  scenario: Scenario.fatigue,
                  isSelected: appState.currentScenario == Scenario.fatigue,
                  onSelect: () => appState.applyScenario(Scenario.fatigue),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Configuration Cards Navigation
          _ConfigOptionTile(
            icon: Icons.tune,
            title: 'EEG Band & Noise Settings',
            subtitle: 'Adjust Delta, Theta, Alpha, Beta, Gamma & Artifacts',
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

class _PresetChip extends StatelessWidget {
  final String label;
  final Scenario scenario;
  final bool isSelected;
  final VoidCallback onSelect;

  const _PresetChip({
    required this.label,
    required this.scenario,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryAccent : AppColors.primarySurface,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border.all(
            color: isSelected ? AppColors.primaryAccent : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.primaryText,
          ),
        ),
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