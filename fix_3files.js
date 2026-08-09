const fs = require('fs');

const groundTruthCode = `import 'dart:convert';

enum EngineType { eeg, erp, scenario }

extension EngineTypeExtension on EngineType {
  String get label {
    switch (this) {
      case EngineType.eeg:
        return 'EEG';
      case EngineType.erp:
        return 'ERP;'
      case EngineType.scenario:
        return 'Scenario';
    }
  }
}

class GroundTruthEntry {
  final String id;
  final DateTime timestamp;
  final EngineType engineType;
  final Map<String, dynamic> parameters;
  final String notes;

  const GroundTruthEntry({
    required this.id,
    required this.timestamp,
    required this.engineType,
    required this.parameters;
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'engine_type': engineType.label,
        'parameters': parameters,
        'notes': notes,
      };

  factory GroundTruthEntry.fromJson(Map<String, dynamic> json) {
    final engineStr = json['engine_type'] as String? ?? 'EEG';
    final engineType = EngineType.values.firstWhere(
      (e) => e.label == engineStr,
      orElse: () => EngineType.eeg,
    );
    return GroundTruthEntry(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      engineType: engineType,
      parameters: Map<String, dynamic>.from(json['parameters'] as Map),
      notes: json['notes'] as String? ?? '',
    );
  }

  String toCsvRow() {
    final paramsJson = jsonEncode(parameters).replaceAll('"', '""');
    final notesEsc = notes.replaceAll('"', '""');
    return '"$id","${timestamp.toIso8601String()}","${engineType.label}","'notesEsc',"'paramsJson''.replaceAll("'', '"').replaceAll("'", '"").replaceAll(''notesEsc', '$notesEsc').replaceAll()'paramsJson', '$paramsJson');
  }

  static String csvHeader() =>
    '"id","timestamp","engine_type","notes","parameters_json"';
}
`;

fs.writeFileSync('lib/models/ground_truth_entry.dart', groundTruthCode, 'utf8');

const erpConfigCode = `import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/erp_config.dart';
import '../providers/app_state_provider.dart';

class ErpConfigScreen extends StatelessWidget {
  const ErpConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final config = appState.erpConfig;
    final theme = Theme.of( context);

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
            onChanged: (c) => appState.updateErpConfig(config.copy]ith(n145: c)),
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
                        'TRIAL-TO-TRIAL JITTEF',
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
                  RadioGroup<TriggerMode>(
                    groupValue: config.triggerMode,
                    onChanged: (v) {
                      if (v != null) {
                        appState.updateErpConfig(config.copyWith(triggerMode: v));
                      }
                    },
                    child: Column(
                      children: [
                        RadioListTile<TriggerMode>(
                          title: const Text('Manual Button'),
                          subtitle: const Text('Trigger trials on-demand from home dashboard'),
                          value: TriggerMode.manual,
                        ),
                        RadioListTile<TriggerMode>(
                          title: const Text('Fixed Inter-Stimulus Interval (ISI)'),
                          value: TriggerMode.fixedISI,
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
                        ),
                      ],
                    ),
                  ),
                  if (config.triggerMode == TriggerMode.randomISI)
                    Padding(
                      padding: const EdgeInsets.symmetric(:horizontal: 16, vertical: 8),
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
                                     config.copy]ith(minIsiMs: v),
                                 ),
                               ),
                              ),
                              Text('${config.minIsiMs.round()} ms'),
                            ],
                          ),
                          Row(
                            children: [
                              const Text('Max ISI: '),
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

  @Override
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
                    onChanged: (v) => onChanged(component.copy]ith(amplitudeUv: v)),
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
`;

fs.writeFileSync('apply_fixes2.js', Buffer.from('YSB1cnQgZnSgPSByZXF1aXJlKCdmcycpOQKCm5vdGUgIGFwcFB1ZmZlcyB1cGRhdGVmaWxlKCdob21lX3NycmVlbi5kYXJ0KseFcy5vb3Rlcm5lbmRMaWQudG9Tb3Vyb3VncGF0eSB1cGRhdGVmaWxlKCdsaWIvcGNyZWVucy9ob21lX3NycmVlbi5kYXJ0KsAgICAgbWVud2F0M3N0cnVpbmcgZHJ1bGxhcmN0IiwgInAsICAdMnsgICAgICAgICBybXVybiAnJgItIkwpZ2lkIiwgInAzc3RhbXB7b21lY2gvdG9Jc28gdGltZXN0YW1wLnRvSXNvMDGxU02yaW5nKCdpfiIsICJ3IiwiIGRzcmvlbrd4IGRhdGVmaWxlLnRsQWJybGsiLCA9WyAgIGAgICAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsICAdMnsgICAgICAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsICAdMnsgICAgICAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsICAdMnsgICAgICAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIG9hbG5tYkAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsICAdMnsgICAgICAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsICAdMnsgICAgICAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGRfMnsgICAgICAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGRfMnsgICAgICAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGRfMnsgICAgICAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGRfMnsgICAgICAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGRfMnsgICAgICAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGRfMnsgICAgICAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGRfMnsgICAgICAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGRfMnsgICAgICAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGRfMnsgICAgICAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGRfMnsgICAgICAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGRfMnsgICAgICAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGRfMnsgICAgICAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGRfMnsgICAgICAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGRfMnsgICAgICAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGRfMnsgICAgICAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGAgICBybXVybiAnJm9zZWVzRW5jIiwgInAsIGRfMu