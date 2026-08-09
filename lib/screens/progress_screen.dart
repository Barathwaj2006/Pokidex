import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/ground_truth_entry.dart';
import '../services/ground_truth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/hero_card.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gtService = context.watch<GroundTruthService>();
    final entries = gtService.entries.reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress & History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Export Ground Truth',
            onPressed: entries.isEmpty
                ? null
                : () async {
                    final path = await gtService.exportJson();
                    await Share.shareXFiles(
                      [XFile(path)],
                      text: 'Pokidex Ground Truth Log (JSON)',
                    );
                  },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          HeroCard(
            title: 'WEEKLY SIMULATION TARGET',
            progressPercent: '84%',
            subtitle: 'of weekly research target completed',
            highlightText: '14 validation sessions logged this week',
            onAction: () {},
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ground Truth History (${entries.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              if (entries.isNotEmpty)
                TextButton.icon(
                  onPressed: () async {
                    final path = await gtService.exportCsv();
                    await Share.shareXFiles(
                      [XFile(path)],
                      text: 'Pokidex Ground Truth Log (CSV)',
                    );
                  },
                  icon: const Icon(Icons.table_chart_outlined, size: 16),
                  label: const Text('CSV'),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (entries.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: const [
                  Icon(
                    Icons.assignment_outlined,
                    size: 44,
                    color: AppColors.mutedText,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No Ground Truth Entries Logged Yet',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Start streaming signals from Home or Simulations to record generator parameter snapshots.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            )
          else
            ...entries.map((entry) {
              final timeStr = entry.timestamp.toIso8601String().substring(11, 19);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.border),
                ),
                child: ExpansionTile(
                  leading: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: entry.engineType == EngineType.eeg
                          ? AppColors.softBlue
                          : AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                    child: Text(
                      entry.engineType.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: entry.engineType == EngineType.eeg
                            ? AppColors.primaryAccent
                            : AppColors.warning,
                      ),
                    ),
                  ),
                  title: Text(
                    entry.notes.isNotEmpty ? entry.notes : entry.id,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                  subtitle: Text(
                    '$timeStr • ${entry.id}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.secondaryText,
                      fontFamily: 'monospace',
                    ),
                  ),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      width: double.infinity,
                      color: AppColors.secondaryBackground,
                      child: Text(
                        const JsonEncoder.withIndent('  ').convert(entry.parameters),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          color: AppColors.darkSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}