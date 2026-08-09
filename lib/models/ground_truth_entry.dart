import 'dart:convert';

enum EngineType { eeg, erp, scenario }

extension EngineTypeExtension on EngineType {
  String get label {
    switch (this) {
      case EngineType.eeg:
        return 'EEG';
      case EngineType.erp:
        return 'ERP';
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
    required this.parameters,
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
    return '"$id","${timestamp.toIso8601String()}","${engineType.label}","$notesEsc","$paramsJson"';
  }

  static String csvHeader() =>
      '"id","timestamp","engine_type","notes","parameters_json"';
}
