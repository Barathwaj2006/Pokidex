import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/erp_config.dart';
import '../providers/app_state_provider.dart';

class ErpConfigScreen extends StatelessWidget {
  const ErpConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final config = appState.erpConfig;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ERP / VEP Config'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info banner
          Card(
            color: Colors.amber.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.amber),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'ERP waveforms are simulated as Gaussian pulses added onto low-amplitude background EEG.',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.amber.shade200),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // VEP Components (N75, P100, N145)
          _ComponentCard(
            title: 'N75 COMPONENT',
            color: Colors.lightBlueAccent,
            component: config.n75,
            onChanged: (c) => appState.updateErpConfig(config.copyWith(n75: c)),
          ),
          const SizedBox(height: 12),

          _ComponentCard(
            title: 'P100 COMPONENT (Primary VEP)',
            color: Colors.amberAccent,
            component: config.p100,
            onChanged: (c) => appState.updateErpConfig(config.copyWith(p100: c)),
          ),
          const SizedBox(height: 12),

          _ComponentCard(
            title: 'N145 COMPONENT',
            color: Colors.purpleAccent,
            component: config.n145,
            onChanged: (c) => appState.updateErpConfig(config.copyWith(n145: c)),
          ),
          const SizedBox(height: 16),

          // Trial-to-trial Jitter
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TRIAL-TO-TRIAL JITTER',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        '${config.jitterPercent.toStringAsFixed(1)} %',
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                  Slider(
                    value: config.jitterPercent,
                    min: 0,
                    max: 30,
                    divisions: 30,
                    onChanged: (v) => appState.updateErpConfig(
                      config.copyWith(jitterPercent: v),
                    ),
                  ),
                  Text(
                    'Randomized latency variation per trial (Gaussian distribution)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Trigger Settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TRIGGER MODE',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RadioListTile<TriggerMode>(
                    title: const Text('Manual Button'),
                    subtitle: const Text('Trigger trials on-demand from home dashboard'),
                    value: TriggerMode.manual,
                    groupValue: config.triggerMode,
                    onChanged: (mode) {
                      if (mode != null) {
                        appState.updateErpConfig(config.copyWith(triggerMode: mode));
                      }
                    },
                  ),
                  RadioListTile<TriggerMode>(
                    title: const Text('Fixed Inter-Stimulus Interval (ISI)'),
                    value: TriggerMode.fixedISI,
                    groupValue: config.triggerMode,
                    onChanged: (mode) {
                      if (mode != null) {
                        appState.updateErpConfig(config.copyWith(triggerMode: mode));
                      }
                    },
                  ),
                  if (config.triggerMode == TriggerMode.fixedISI)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          const Text('ISI Duration (ms):'),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Slider(
                              value: config.fixedIsiMs,
                              min: 500,
                              max: 3000,
                              divisions: 25,
                              label: '${config.fixedIsiMs.round()} ms',
                              onChanged: (v) => appState.updateErpConfig(
                                config.copyWith(fixedIsiMs: v),
                              ),
                            ),
                          ),
                          Text('${config.fixedIsiMs.round()} ms'),
                        ],
                      ),
                    ),
                  RadioListTile<TriggerMode>(
                    title: const Text('Random ISI Range'),
                    value: TriggerMode.randomISI,
                    groupValue: config.triggerMode,
                    onChanged: (mode) {
                      if (mode != null) {
                        appState.updateErpConfig(config.copyWith(triggerMode: mode));
                      }
                    },
                  ),
                  if (config.triggerMode == TriggerMode.randomISI)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Text('Min ISI:'),
                              Expanded(
                                child: Slider(
                                  value: config.minIsiMs,
                                  min: 300,
                                  max: 1500,
                                  onChanged: (v) => appState.updateErpConfig(
                                    config.copyWith(minIsiMs: v),
                                  ),
                                ),
                              ),
                              Text('${config.minIsiMs.round()} ms'),
                            ],
                          ),
                          Row(
                            children: [
                              const Text('Max ISI:'),
                              Expanded(
                                child: Slider(
                                  value: config.maxIsiMs,
                                  min: 1000,
                                  max: 4000,
                                  onChanged: (v) => appState.updateErpConfig(
                                    config.copyWith(maxIsiMs: v),
                                  ),
                                ),
                              ),
                              Text('${config.maxIsiMs.round()} ms'),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComponentCard extends StatelessWidget {
  final String title;
  final Color color;
  final ErpComponentConfig component;
  final ValueChanged<ErpComponentConfig> onChanged;

  const _ComponentCard({
    required this.title,
    required this.color,
    required this.component,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(width: 80, child: Text('Latency')),
                Expanded(
                  child: Slider(
                    value: component.latencyMs,
                    min: 30,
                    max: 250,
                    activeColor: color,
                    onChanged: (v) => onChanged(component.copyWith(latencyMs: v)),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text('${component.latencyMs.toStringAsFixed(1)} ms', textAlign: TextAlign.right),
                ),
              ],
            ),
            Row(
              children: [
                const SizedBox(width: 80, child: Text('Amplitude')),
                Expanded(
                  child: Slider(
                    value: component.amplitudeUv,
                    min: -20,
                    max: 20,
                    activeColor: color,
                    onChanged: (v) => onChanged(component.copyWith(amplitudeUv: v)),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text('${component.amplitudeUv.toStringAsFixed(1)} uV', textAlign: TextAlign.right),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}