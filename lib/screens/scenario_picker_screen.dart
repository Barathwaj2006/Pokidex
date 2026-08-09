import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/scenario.dart';
import '../providers/app_state_provider.dart';

class ScenarioPickerScreen extends StatelessWidget {
  const ScenarioPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulation Scenarios'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Explicit Ground Truth Disclaimer Banner
          Card(
            color: Colors.blueGrey.shade900,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.science, color: Colors.cyanAccent),
                      const SizedBox(width: 8),
                      Text(
                        'SIMULATION PRESETS NOTICE',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'These scenarios are configurable parameter presets for research testing. '
                    'They represent synthetic parameter maps, not validated physiological ground truth.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          RadioGroup<Scenario>(
            groupValue: appState.currentScenario,
            onChanged: (scenario) {
              if (scenario != null) {
                appState.applyScenario(scenario);
                Navigator.pop(context);
              }
            },
            child: Column(
              children: [
                ...Scenario.values.map((scenario) {
            final isSelected = appState.currentScenario == scenario;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Card(
                elevation: isSelected ? 4 : 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? Colors.cyanAccent : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    appState.applyScenario(scenario);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Applied scenario: ${scenario.label}'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Radio<Scenario>(
                          value: scenario,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    scenario.label,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      scenario.paramSummary,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontFamily: 'monospace',
                                        color: Colors.cyanAccent.shade100,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                scenario.description,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    ),
        ],
      ),
    );
  }
}