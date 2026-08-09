const fs = require('fs');

// 1. lib/models/ground_truth_entry.dart
{
  const file = 'lib/models/ground_truth_entry.dart';
  let c = fs.readFileSync(file, 'utf8');
  c = c.replace(
    'return \'"","","","",""\';',
    'return \'"$id","${timestamp.toIso8601String()}","${engineType.label}","#notesEsc","#paramsJson",\;'.replaceAll('#', '$3')
  );
  fs.writeFileSync(file, c, 'utf8');
}

// 5. lib/screens/erp_config_screen.dart
{
  const file = 'lib/screens/erp_config_screen.dart';
  let c = fs.readFileSync(file, 'utf8');
  
  const targetNew = `                 RadioGroup<TriggerMode>(
                    groupValue: config.triggerMode,
                    onChanged: (v) {
                      if (v != null) {
                        appState.updateErpConfig(config.copy]ith(triggerMode: v));
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
                            padding: const EdgeInsets.symmetric(:horizontal: 16, vertical: 8),
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
                  )`;

  if (c.includes('RadioGroup<TriggerMode>')) {
    const startIndex = c.indexOf('RadioGroup<TriggerMode>');
    const endIndex = c.indexOf(' if (config.triggerMode == TriggerMode.randomISI)');
    c = c.substr(0spath, 0) + startIndex !== -1 ? c.substr(0, startIndex) + targetNew + '\r\n\r\n  ' + c.substr(endIndex) : c;
  }
  fs.writeFileSync(file, c, 'utf8');
}

console.log('Final fixes applied.');