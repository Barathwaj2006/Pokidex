import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state_provider.dart';
import '../widgets/band_config_row.dart';

class EegConfigScreen extends StatelessWidget {
  const EegConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final config = appState.eegConfig;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('EEG Engine Config'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Channel Count & Sample Rate
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ACQUISITION SETTINGS',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Expanded(child: Text('Channels')),
                      DropdownButton<int>(
                        value: config.channelCount,
                        items: [1, 2, 4, 8].map((c) {
                          return DropdownMenuItem(
                            value: c,
                            child: Text('$c Channels'),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            appState.updateEegConfig(
                              config.copyWith(channelCount: v),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    children: [
                      const Expanded(child: Text('Sampling Rate')),
                      DropdownButton<int>(
                        value: config.samplingRate,
                        items: [250, 500, 1000].map((r) {
                          return DropdownMenuItem(
                            value: r,
                            child: Text('$r Hz'),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            appState.updateEegConfig(
                              config.copyWith(samplingRate: v),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Band Configurations
          Text(
            'FREQUENCY BANDS',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),

          BandConfigRow(
            bandName: 'DELTA',
            bandColor: const Color(0xFF4FC3F7),
            amplitude: config.delta.amplitude,
            frequency: config.delta.frequency,
            minFreq: 0.5,
            maxFreq: 4.0,
            onAmplitudeChanged: (v) => appState.updateEegConfig(
              config.copyWith(delta: config.delta.copyWith(amplitude: v)),
            ),
            onFrequencyChanged: (v) => appState.updateEegConfig(
              config.copyWith(delta: config.delta.copyWith(frequency: v)),
            ),
          ),

          BandConfigRow(
            bandName: 'THETA',
            bandColor: const Color(0xFF81C784),
            amplitude: config.theta.amplitude,
            frequency: config.theta.frequency,
            minFreq: 4.0,
            maxFreq: 8.0,
            onAmplitudeChanged: (v) => appState.updateEegConfig(
              config.copyWith(theta: config.theta.copyWith(amplitude: v)),
            ),
            onFrequencyChanged: (v) => appState.updateEegConfig(
              config.copyWith(theta: config.theta.copyWith(frequency: v)),
            ),
          ),

          BandConfigRow(
            bandName: 'ALPHA',
            bandColor: const Color(0xFFFFB74D),
            amplitude: config.alpha.amplitude,
            frequency: config.alpha.frequency,
            minFreq: 8.0,
            maxFreq: 13.0,
            onAmplitudeChanged: (v) => appState.updateEegConfig(
              config.copyWith(alpha: config.alpha.copyWith(amplitude: v)),
            ),
            onFrequencyChanged: (v) => appState.updateEegConfig(
              config.copyWith(alpha: config.alpha.copyWith(frequency: v)),
            ),
          ),

          BandConfigRow(
            bandName: 'BETA',
            bandColor: const Color(0xFFBA68C8),
            amplitude: config.beta.amplitude,
            frequency: config.beta.frequency,
            minFreq: 13.0,
            maxFreq: 30.0,
            onAmplitudeChanged: (v) => appState.updateEegConfig(
              config.copyWith(beta: config.beta.copyWith(amplitude: v)),
            ),
            onFrequencyChanged: (v) => appState.updateEegConfig(
              config.copyWith(beta: config.beta.copyWith(frequency: v)),
            ),
          ),

          BandConfigRow(
            bandName: 'GAMMA',
            bandColor: const Color(0xFFFF8A65),
            amplitude: config.gamma.amplitude,
            frequency: config.gamma.frequency,
            minFreq: 30.0,
            maxFreq: 45.0,
            onAmplitudeChanged: (v) => appState.updateEegConfig(
              config.copyWith(gamma: config.gamma.copyWith(amplitude: v)),
            ),
            onFrequencyChanged: (v) => appState.updateEegConfig(
              config.copyWith(gamma: config.gamma.copyWith(frequency: v)),
            ),
          ),

          const SizedBox(height: 16),

          // Noise %
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
                        'NOISE LEVEL',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        '${config.noisePercent.toStringAsFixed(1)} %',
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                  Slider(
                    value: config.noisePercent,
                    min: 0,
                    max: 30,
                    divisions: 30,
                    onChanged: (v) => appState.updateEegConfig(
                      config.copyWith(noisePercent: v),
                    ),
                  ),
                  Text(
                    'Includes 50% pink (1/f) noise + 50% white noise',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Artifact Toggles
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ARTIFACT INJECTION',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Eye Blink Artifacts'),
                    subtitle: const Text('Random ~80uV frontal deflections'),
                    value: config.artifacts.eyeBlink,
                    onChanged: (v) => appState.updateEegConfig(
                      config.copyWith(
                        artifacts: config.artifacts.copyWith(eyeBlink: v),
                      ),
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Muscle (EMG) Noise'),
                    subtitle: const Text('High-frequency noise bursts'),
                    value: config.artifacts.emg,
                    onChanged: (v) => appState.updateEegConfig(
                      config.copyWith(
                        artifacts: config.artifacts.copyWith(emg: v),
                      ),
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Power Line Noise'),
                    subtitle: Text('${config.artifacts.lineNoiseFreq.toInt()} Hz sinusoidal artifact'),
                    value: config.artifacts.lineNoise,
                    onChanged: (v) => appState.updateEegConfig(
                      config.copyWith(
                        artifacts: config.artifacts.copyWith(lineNoise: v),
                      ),
                    ),
                  ),
                  if (config.artifacts.lineNoise)
                    Row(
                      children: [
                        const SizedBox(width: 16),
                        const Text('Line Frequency:'),
                        const SizedBox(width: 16),
                        ChoiceChip(
                          label: const Text('50 Hz'),
                          selected: config.artifacts.lineNoiseFreq == 50.0,
                          onSelected: (sel) {
                            if (sel) {
                              appState.updateEegConfig(
                                config.copyWith(
                                  artifacts: config.artifacts.copyWith(lineNoiseFreq: 50.0),
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('60 Hz'),
                          selected: config.artifacts.lineNoiseFreq == 60.0,
                          onSelected: (sel) {
                            if (sel) {
                              appState.updateEegConfig(
                                config.copyWith(
                                  artifacts: config.artifacts.copyWith(lineNoiseFreq: 60.0),
                                ),
                              );
                            }
                          },
                        ),
                      ],
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