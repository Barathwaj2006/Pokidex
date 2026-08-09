import '../models/scenario.dart';
import '../models/eeg_config.dart';
import '../models/erp_config.dart';

class ScenarioEngine {
  Scenario _currentScenario = Scenario.rest;

  Scenario get currentScenario => _currentScenario;

  EegConfig getEegConfig(Scenario scenario) {
    return kScenarioPresets[scenario]!.eegConfig;
  }

  ErpConfig getErpConfig(Scenario scenario) {
    return kScenarioPresets[scenario]!.erpConfig;
  }

  (EegConfig, ErpConfig) apply(Scenario scenario) {
    _currentScenario = scenario;
    final preset = kScenarioPresets[scenario]!;
    return (preset.eegConfig, preset.erpConfig);
  }

  List<Scenario> get allScenarios => Scenario.values;
}