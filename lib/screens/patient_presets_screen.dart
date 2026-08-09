import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/patient_preset.dart';
import '../providers/app_state_provider.dart';
import '../widgets/waveform_chart.dart';

class PatientPresetsScreen extends StatefulWidget {
  const PatientPresetsScreen({super.key});

  @override
  State<PatientPresetsScreen> createState() => _PatientPresetsScreenState();
}

class _PatientPresetsScreenState extends State<PatientPresetsScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';

  List<String> get _categories {
    final cats = kPatientPresets.map((p) => p.category).toSet().toList();
    cats.sort();
    return ['All', ...cats];
  }

  // Pre-generated sample waveform data for signal visualization preview
  List<List<double>> _generatePreviewWaveform(PatientConditionPreset preset) {
    final List<double> ch1 = [];
    final List<double> ch2 = [];

    final alphaAmp = preset.eegConfig.alpha.amplitude;
    final thetaAmp = preset.eegConfig.theta.amplitude;
    final betaAmp = preset.eegConfig.beta.amplitude;

    for (int i = 0; i < 100; i++) {
      final t = i * 0.05;
      final val1 = alphaAmp * 0.4 * (i % 8 < 4 ? 1.0 : -1.0) +
          thetaAmp * 0.3 * (i % 14 < 7 ? 0.8 : -0.8) +
          betaAmp * 0.2 * (i % 4 < 2 ? 0.5 : -0.5);
      final val2 = val1 * 0.85 + (i % 6 < 3 ? 2.0 : -2.0);

      ch1.add(val1);
      ch2.add(val2);
    }
    return [ch1, ch2];
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();

    final filteredPresets = kPatientPresets.where((p) {
      final matchesCat = _selectedCategory == 'All' || p.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          p.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.medicalDescription.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCat && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('20 Patient Condition Presets'),
      ),
      body: Column(
        children: [
          // Banner Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.indigo.shade900.withValues(alpha: 0.9),
            child: Row(
              children: const [
                Icon(Icons.psychology, color: Colors.cyanAccent, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BIOMEDICAL SIGNAL SIMULATIONS',
                        style: TextStyle(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Tap "USE THIS SIMULATION" to immediately feed any patient waveform into Pokidex.',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Search & Category Filter Chips
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search conditions (e.g., Epilepsy, ADHD, Alzheimer\'s)...',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              _selectedCategory = cat;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Presets List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              itemCount: filteredPresets.length,
              itemBuilder: (context, index) {
                final preset = filteredPresets[index];
                final isCurrent = appState.eegConfig.noisePercent == preset.eegConfig.noisePercent &&
                    appState.eegConfig.alpha.amplitude == preset.eegConfig.alpha.amplitude &&
                    appState.eegConfig.theta.amplitude == preset.eegConfig.theta.amplitude;

                final previewBuffer = _generatePreviewWaveform(preset);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: isCurrent ? 4 : 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isCurrent ? Colors.tealAccent : Colors.grey.shade800,
                      width: isCurrent ? 2 : 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blueGrey.shade800,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                preset.category.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.cyanAccent,
                                ),
                              ),
                            ),
                            if (isCurrent)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.tealAccent.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'ACTIVE SIMULATION',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.tealAccent,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          preset.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          preset.medicalDescription,
                          style: const TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                        const SizedBox(height: 10),

                        // Signal Waveform Visual Representation
                        Container(
                          height: 70,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Stack(
                            children: [
                              WaveformChart(channelData: previewBuffer),
                              Positioned(
                                top: 4,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'SIGNAL PATTERN PREVIEW',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 8,
                                      color: Colors.cyanAccent,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.analytics_outlined, size: 14, color: Colors.amberAccent),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Signature: ${preset.clinicalSignature}',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    color: Colors.amberAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isCurrent ? Colors.tealAccent : Colors.indigoAccent,
                              foregroundColor: isCurrent ? Colors.black : Colors.white,
                            ),
                            icon: Icon(isCurrent ? Icons.check_circle : Icons.play_arrow),
                            label: Text(
                              isCurrent ? 'ACTIVE SIMULATION LOADED' : 'USE THIS SIMULATION',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            onPressed: () {
                              appState.updateEegConfig(preset.eegConfig);
                              appState.updateErpConfig(preset.erpConfig);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Switched active simulation to "${preset.title}"!'),
                                  backgroundColor: Colors.teal,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}