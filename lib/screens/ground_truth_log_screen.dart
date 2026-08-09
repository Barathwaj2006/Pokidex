import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/ground_truth_entry.dart';
import '../services/ground_truth_service.dart';

class GroundTruthLogScreen extends StatefulWidget {
  const GroundTruthLogScreen({super.key});

  @override
  State<GroundTruthLogScreen> createState() => _GroundTruthLogScreenState();
}

class _GroundTruthLogScreenState extends State<GroundTruthLogScreen> {
  @override
  Widget build(BuildContext context) {
    final gtService = context.watch<GroundTruthService>();
    final entries = gtService.entries.reversed.toList();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Ground Truth Log (${entries.length})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear Log',
            onPressed: entries.isEmpty
                ? null
                : () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Clear Ground Truth Log?'),
                        content: const Text(
                          'This will remove all recorded parameter snapshots from local memory.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('CANCEL'),
                          ),
                          TextButton(
                            onPressed: () {
                              gtService.clear();
                              setState(() {});
                              Navigator.pop(ctx);
                            },
                            child: const Text('CLEAR', style: TextStyle(color: Colors.redAccent)),
                          ),
                        ],
                      ),
                    );
                  },
          ),
        ],
      ),
      body: entries.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 48,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No Ground Truth entries recorded yet.',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Start streaming to record generator parameter snapshots.',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: entries.length,
              itemBuilder: (ctx, idx) {
                final entry = entries[idx];
                return _LogEntryTile(entry: entry);
              },
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
        color: theme.colorScheme.surface,
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: entries.isEmpty
                    ? null
                    : () async {
                        final path = await gtService.exportJson();
                        await Share.shareXFiles(
                          [XFile(path)],
                          text: 'Pokidex Ground Truth Log (JSON)',
                        );
                      },
                icon: const Icon(Icons.code),
                label: const Text('EXPORT JSON'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: entries.isEmpty
                    ? null
                    : () async {
                        final path = await gtService.exportCsv();
                        await Share.shareXFiles(
                          [XFile(path)],
                          text: 'Pokidex Ground Truth Log (CSV)',
                        );
                      },
                icon: const Icon(Icons.table_chart),
                label: const Text('EXPORT CSV'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogEntryTile extends StatelessWidget {
  final GroundTruthEntry entry;

  const _LogEntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeStr = entry.timestamp.toIso8601String().substring(11, 19);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: entry.engineType == EngineType.eeg
                ? Colors.cyan.withValues(alpha: 0.2)
                : Colors.amber.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            entry.engineType.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: entry.engineType == EngineType.eeg
                  ? Colors.cyanAccent
                  : Colors.amberAccent,
            ),
          ),
        ),
        title: Text(
          entry.notes.isNotEmpty ? entry.notes : entry.id,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '$timeStr — ${entry.id}',
          style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            color: Colors.black.withValues(alpha: 0.3),
            child: Text(
              const JsonEncoder.withIndent('  ').convert(entry.parameters),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: Colors.greenAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}