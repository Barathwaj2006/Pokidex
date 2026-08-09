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

  List<List<double>> _generatePreviewWaveform(PatientConditionPreset preset) {
    final List<double> ch1 = [];
    final List<double> ch2 = [];

    final alphaAmp = preset.eegConfig.alpha.amplitude;
    final thetaAmp = preset.eegConfig.theta.amplitude;
    final betaAmp = preset.eegConfig.beta.amplitude;

    for (int i = 0; i < 80; i++) {
      final val1 = alphaAmp * 0.3 * (i % 8 < 4 ? 1.0 : -1.0) +
          thetaAmp * 0.25 * (i % 14 < 7 ? 0.8 : -0.8) +
          betaAmp * 0.15 * (i % 4 < 2 ? 0.5 : -0.5);
      final val2 = val1 * 0.85 + (i % 6 < 3 ? 1.5 : -1.5);

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
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('20 Patient Condition Presets'),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Cyber Header Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade900, const Color(0xFF1E1B4B)],
              ),
              border: const Border(bottom: BorderSide(color: Colors.indigoAccent, width: 0.5)),
            ),
            child: Row(
              children: const [
                Icon(Icons.psychology, color: Colors.cyanAccent, size: 22),
                SizedBox(width: 10),
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
                          letterSpacing: 0.8,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Tap play button to load physiological condition waveforms into Pokidex.',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Search & Category Chips
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search condition (e.g., Epilepsy, ADHD, Sleep)...',
                    hintStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                    prefixIcon: const Icon(Icons.search, color: Colors.cyanAccent, size: 20),
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
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
                          label: Text(cat, style: TextStyle(fontSize: 11, color: isSelected ? Colors.black : Colors.white)),
                          selected: isSelected,
                          selectedColor: Colors.cyanAccent,
                          backgroundColor: const Color(0xFF1E293B),
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

          // High Contrast Single Line Compact Presets List
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

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isCurrent ? Colors.tealAccent : Colors.white12,
                      width: isCurrent ? 1.5 : 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title Row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.indigo.shade900,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                preset.category.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.cyanAccent,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                preset.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (isCurrent)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.tealAccent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'ACTIVE',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Waveform Preview Bar & Play Button in a Single Compact Bar
                        Row(
                          children: [
                            // Mini Waveform Box
                            Expanded(
                              child: Container(
                                height: 40,
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: WaveformChart(channelData: previewBuffer),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Single Line Compact Action Button
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isCurrent ? Colors.tealAccent : const Color(0xFF3B82F6),
                                foregroundColor: isCurrent ? Colors.black : Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              icon: Icon(
                                isCurrent ? Icons.check_circle : Icons.play_arrow,
                                size: 16,
                                color: isCurrent ? Colors.black : Colors.white,
                              ),
                              label: Text(
                                isCurrent ? 'SIMULATION LOADED' : 'USE SIMULATION',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isCurrent ? Colors.black : Colors.white,
                                ),
                              ),
                              onPressed: () {
                                appState.updateEegConfig(preset.eegConfig);
                                appState.updateErpConfig(preset.erpConfig);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Loaded simulation: ${preset.title}'),
                                    backgroundColor: Colors.teal,
                                    duration: const Duration(milliseconds: 1000),
                                  ),
                                );
                              },
                            ),
                          ],
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