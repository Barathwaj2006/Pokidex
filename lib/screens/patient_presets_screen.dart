import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/patient_preset.dart';
import '../providers/app_state_provider.dart';
import '../providers/signal_provider.dart';
import '../theme/app_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final signalProvider = context.watch<SignalProvider>();

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
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.amberAccent),
            tooltip: 'Pyromatix & NeuroSync Dedicated Mode',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Target Suite: Optimized for Pyromatix & NeuroSync BCI Data Channels'),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner for Pyromatix & NeuroSync BCI integration
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.indigo.shade900.withValues(alpha: 0.8),
            child: Row(
              children: const [
                Icon(Icons.psychology, color: Colors.cyanAccent, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PYROMATIX & NEUROSYNC PATIENT SUITE',
                        style: TextStyle(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Select from 20 clinically accurate biopotential waveforms for BCI evaluation.',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Search & Category Filter
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

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
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
                                  'ACTIVE INPUT',
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
                              isCurrent
                                  ? 'LOADED ON PYROMATIX / NEUROSYNC'
                                  : 'APPLY TO PYROMATIX & NEUROSYNC PIPELINE',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            onPressed: () {
                              appState.setEegConfig(preset.eegConfig);
                              appState.setErpConfig(preset.erpConfig);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Applied "${preset.title}" to Pyromatix & NeuroSync inputs!'),
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