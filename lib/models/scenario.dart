import 'eeg_config.dart';
import 'erp_config.dart';

enum Scenario {
  rest,
  relaxed,
  lowLoad,
  mediumLoad,
  highLoad,
  fatigue,
  custom,
}

extension ScenarioExtension on Scenario {
  String get label {
    switch (this) {
      case Scenario.rest:
        return 'REST';
      case Scenario.relaxed:
        return 'RELAXED';
      case Scenario.lowLoad:
        return 'LOW LOAD';
      case Scenario.mediumLoad:
        return 'MEDIUM LOAD';
      case Scenario.highLoad:
        return 'HIGH LOAD';
      case Scenario.fatigue:
        return 'FATIGUE';
      case Scenario.custom:
        return 'CUSTOM';
    }
  }

  String get description {
    switch (this) {
      case Scenario.rest:
        return 'Eyes-closed resting state. Dominant alpha, very low noise.';
      case Scenario.relaxed:
        return 'Awake, relaxed. Moderate alpha, low beta.';
      case Scenario.lowLoad:
        return 'Mild cognitive engagement. Alpha decreasing, beta rising.';
      case Scenario.mediumLoad:
        return 'Sustained attention task. Balanced theta/beta, moderate noise.';
      case Scenario.highLoad:
        return 'Heavy working memory load. Theta dominant, high beta, elevated noise.';
      case Scenario.fatigue:
        return 'Mental fatigue state. Delta/theta elevated, alpha fragmented.';
      case Scenario.custom:
        return 'User-defined configuration. Load from current EEG/ERP settings.';
    }
  }

  String get paramSummary {
    switch (this) {
      case Scenario.rest:
        return 'Alpha ^^, Beta v, Noise 3%';
      case Scenario.relaxed:
        return 'Alpha ^, Theta ^, Noise 5%';
      case Scenario.lowLoad:
        return 'Alpha v, Beta ^, Noise 7%';
      case Scenario.mediumLoad:
        return 'Theta ^, Beta ^^, Noise 10%';
      case Scenario.highLoad:
        return 'Theta ^^, Beta ^^, Gamma ^, Noise 15%';
      case Scenario.fatigue:
        return 'Delta ^, Theta ^^, Alpha frag., Noise 12%';
      case Scenario.custom:
        return 'From current config';
    }
  }
}

class ScenarioPreset {
  final Scenario scenario;
  final EegConfig eegConfig;
  final ErpConfig erpConfig;

  const ScenarioPreset({
    required this.scenario,
    required this.eegConfig,
    required this.erpConfig,
  });
}

const Map<Scenario, ScenarioPreset> kScenarioPresets = {
  Scenario.rest: ScenarioPreset(
    scenario: Scenario.rest,
    eegConfig: EegConfig(
      delta: BandConfig(amplitude: 8.0, frequency: 1.5),
      theta: BandConfig(amplitude: 5.0, frequency: 6.0),
      alpha: BandConfig(amplitude: 35.0, frequency: 10.0),
      beta: BandConfig(amplitude: 3.0, frequency: 18.0),
      gamma: BandConfig(amplitude: 1.0, frequency: 35.0),
      noisePercent: 3.0,
      artifacts: ArtifactConfig(),
      channelCount: 4,
      samplingRate: 250,
    ),
    erpConfig: ErpConfig(
      jitterPercent: 8.0,
      triggerMode: TriggerMode.fixedISI,
      fixedIsiMs: 1200.0,
    ),
  ),
  Scenario.relaxed: ScenarioPreset(
    scenario: Scenario.relaxed,
    eegConfig: EegConfig(
      delta: BandConfig(amplitude: 8.0, frequency: 1.5),
      theta: BandConfig(amplitude: 10.0, frequency: 6.0),
      alpha: BandConfig(amplitude: 22.0, frequency: 10.0),
      beta: BandConfig(amplitude: 6.0, frequency: 18.0),
      gamma: BandConfig(amplitude: 1.5, frequency: 35.0),
      noisePercent: 5.0,
      artifacts: ArtifactConfig(eyeBlink: true),
      channelCount: 4,
      samplingRate: 250,
    ),
    erpConfig: ErpConfig(
      jitterPercent: 6.0,
      triggerMode: TriggerMode.fixedISI,
      fixedIsiMs: 1000.0,
    ),
  ),
  Scenario.lowLoad: ScenarioPreset(
    scenario: Scenario.lowLoad,
    eegConfig: EegConfig(
      delta: BandConfig(amplitude: 6.0, frequency: 2.0),
      theta: BandConfig(amplitude: 8.0, frequency: 6.5),
      alpha: BandConfig(amplitude: 14.0, frequency: 10.0),
      beta: BandConfig(amplitude: 10.0, frequency: 20.0),
      gamma: BandConfig(amplitude: 2.5, frequency: 35.0),
      noisePercent: 7.0,
      artifacts: ArtifactConfig(eyeBlink: true),
      channelCount: 4,
      samplingRate: 250,
    ),
    erpConfig: ErpConfig(
      p100: ErpComponentConfig(
        name: 'P100',
        latencyMs: 105.0,
        amplitudeUv: 5.5,
        sigmaMs: 20.0,
      ),
      jitterPercent: 7.0,
      triggerMode: TriggerMode.randomISI,
      minIsiMs: 800.0,
      maxIsiMs: 1400.0,
    ),
  ),
  Scenario.mediumLoad: ScenarioPreset(
    scenario: Scenario.mediumLoad,
    eegConfig: EegConfig(
      delta: BandConfig(amplitude: 5.0, frequency: 2.0),
      theta: BandConfig(amplitude: 14.0, frequency: 6.5),
      alpha: BandConfig(amplitude: 10.0, frequency: 10.0),
      beta: BandConfig(amplitude: 16.0, frequency: 22.0),
      gamma: BandConfig(amplitude: 4.0, frequency: 38.0),
      noisePercent: 10.0,
      artifacts: ArtifactConfig(eyeBlink: true, emg: true),
      channelCount: 4,
      samplingRate: 250,
    ),
    erpConfig: ErpConfig(
      p100: ErpComponentConfig(
        name: 'P100',
        latencyMs: 110.0,
        amplitudeUv: 5.0,
        sigmaMs: 22.0,
      ),
      jitterPercent: 10.0,
      triggerMode: TriggerMode.randomISI,
      minIsiMs: 700.0,
      maxIsiMs: 1300.0,
    ),
  ),
  Scenario.highLoad: ScenarioPreset(
    scenario: Scenario.highLoad,
    eegConfig: EegConfig(
      delta: BandConfig(amplitude: 5.0, frequency: 2.0),
      theta: BandConfig(amplitude: 20.0, frequency: 7.0),
      alpha: BandConfig(amplitude: 6.0, frequency: 10.0),
      beta: BandConfig(amplitude: 22.0, frequency: 25.0),
      gamma: BandConfig(amplitude: 7.0, frequency: 40.0),
      noisePercent: 15.0,
      artifacts: ArtifactConfig(eyeBlink: true, emg: true),
      channelCount: 4,
      samplingRate: 250,
    ),
    erpConfig: ErpConfig(
      p100: ErpComponentConfig(
        name: 'P100',
        latencyMs: 118.0,
        amplitudeUv: 4.2,
        sigmaMs: 25.0,
      ),
      jitterPercent: 15.0,
      triggerMode: TriggerMode.randomISI,
      minIsiMs: 600.0,
      maxIsiMs: 1200.0,
    ),
  ),
  Scenario.fatigue: ScenarioPreset(
    scenario: Scenario.fatigue,
    eegConfig: EegConfig(
      delta: BandConfig(amplitude: 18.0, frequency: 1.5),
      theta: BandConfig(amplitude: 22.0, frequency: 6.0),
      alpha: BandConfig(amplitude: 12.0, frequency: 9.5),
      beta: BandConfig(amplitude: 8.0, frequency: 18.0),
      gamma: BandConfig(amplitude: 2.0, frequency: 35.0),
      noisePercent: 12.0,
      artifacts: ArtifactConfig(eyeBlink: true, emg: true),
      channelCount: 4,
      samplingRate: 250,
    ),
    erpConfig: ErpConfig(
      p100: ErpComponentConfig(
        name: 'P100',
        latencyMs: 125.0,
        amplitudeUv: 3.5,
        sigmaMs: 28.0,
      ),
      jitterPercent: 20.0,
      triggerMode: TriggerMode.randomISI,
      minIsiMs: 800.0,
      maxIsiMs: 1600.0,
    ),
  ),
  Scenario.custom: ScenarioPreset(
    scenario: Scenario.custom,
    eegConfig: EegConfig(),
    erpConfig: ErpConfig(),
  ),
};