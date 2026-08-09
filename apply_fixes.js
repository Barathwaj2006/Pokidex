const fs = require('fs');

function replaceInFile(filePath, replacements) {
  let content = fs.readFileSync(filePath, 'utf8');
  for (const [search, replace] of replacements) {
    content = content.replaceAll(search, replace);
  }
  fs.writeFileSync(filePath, content, 'utf8');
}

// 1. lib/models/ground_truth_entry.dart
replaceInFile('lib/models/ground_truth_entry.dart', [
  [
    'return \'"","","","","",\;',
    'return \;"$id","${timestamp.toIso8601String()}","${engineType.label}","$notesEsc","$paramsJson"\';'
  ]
]);

// 2. lib/screens/analytics_screen.dart
replaceInFile('lib/screens/analytics_screen.dart', [
  ["import 'package:provider/provider.dart';\r\n", ''],
  ["import 'package:provider/provider.dart';\n", ''],
  ["import '../providers/app_state_provider.dart';\r\n", ''],
  ["import '../providers/app_state_provider.dart';\n", ''],
  ["    final appState = context.watch<AppStateProvider>();\r\n", ''],
  ["    final appState = context.watch<AppStateProvider>();\n", '']
]);

// 3. lib/screens/connection_screen.dart
replaceInFile('lib/screens/connection_screen.dart', [
  ["import '../transport/signal_transport.dart';\r\n", ''],
  ["import '../transport/signal_transport.dart';\n", '']
]);

// 4. lib/screens/eeg_config_screen.dart
replaceInFile('lib/screens/eeg_config_screen.dart', [
  ["import '../models/eeg_config.dart';\r\n", ''],
  ["import '../models/eeg_config.dart';\n", ''],
  ['.withOpacity(', '.withValues(alpha: ']
]);

// 6. lib/screens/ground_truth_log_screen.dart
replaceInFile('lib/screens/ground_truth_log_screen.dart', [
  ['.withOpacity(', '.withValues(alpha: ']
]);

// 7. lib/screens/home_screen.dart
replaceInFile('lib/screens/home_screen.dart', [
  [
    "value: '${appState.eegConfig.noisePercent.toStringAsFixed(1)}',",
    "value: appState.eegConfig.noisePercent.toStringAsFixed(1),"
  ]
]);

// 9. lib/widgets/waveform_chart.dart
replaceInFile('lib/widgets/waveform_chart.dart', [
  ['.withOpacity(', '.withValues(alpha: ']
]);

console.log('apply_fixes.js executed successfully');