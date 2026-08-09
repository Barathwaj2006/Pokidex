import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/ground_truth_entry.dart';

class GroundTruthService {
  final List<GroundTruthEntry> _entries = [];
  static const _filename = 'pokidex_ground_truth.json';

  List<GroundTruthEntry> get entries => List.unmodifiable(_entries);

  void add(GroundTruthEntry entry) {
    _entries.add(entry);
  }

  void clear() {
    _entries.clear();
  }

  Future<String> exportJson() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_filename');
    final jsonList = _entries.map((e) => e.toJson()).toList();
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(jsonList),
    );
    return file.path;
  }

  Future<String> exportCsv() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/pokidex_ground_truth.csv');
    final buffer = StringBuffer();
    buffer.writeln(GroundTruthEntry.csvHeader());
    for (final entry in _entries) {
      buffer.writeln(entry.toCsvRow());
    }
    await file.writeAsString(buffer.toString());
    return file.path;
  }
}