import 'package:flutter/foundation.dart';

import '../models/eeg_config.dart';
import '../models/erp_config.dart';
import '../models/scenario.dart';

enum ActiveEngine { eeg, erp }

class AppStateProvider extends ChangeNotifier {
  ActiveEngine _activeEngine = ActiveEngine.eeg;

  ActiveEngine get activeEngine => _activeEngine;

  void setActiveEngine(ActiveEngine engine) {
    _activeEngine = engine;
    notifyListeners();
  }

  bool _isStreaming = false;

  bool get isStreaming => _isStreaming;

  void setStreaming(bool v) {
    _isStreaming = v;
    notifyListeners();
  }

  int _packetsPerSecond = 0;

  int get packetsPerSecond => _packetsPerSecond;

  void setPacketsPerSecond(int v) {
    if (_packetsPerSecond == v) return;
    _packetsPerSecond = v;
    notifyListeners();
  }

  EegConfig _eegConfig = const EegConfig();

  EegConfig get eegConfig => _eegConfig;

  void updateEegConfig(EegConfig config) {
    _eegConfig = config;
    notifyListeners();
  }

  ErpConfig _erpConfig = const ErpConfig();

  ErpConfig get erpConfig => _erpConfig;

  void updateErpConfig(ErpConfig config) {
    _erpConfig = config;
    notifyListeners();
  }

  Scenario _currentScenario = Scenario.custom;

  Scenario get currentScenario => _currentScenario;

  void applyScenario(Scenario scenario) {
    _currentScenario = scenario;
    if (scenario != Scenario.custom) {
      final preset = kScenarioPresets[scenario]!;
      _eegConfig = preset.eegConfig;
      _erpConfig = preset.erpConfig;
    }
    notifyListeners();
  }

  int _wsPort = 8765;

  int get wsPort => _wsPort;

  void setWsPort(int port) {
    _wsPort = port;
    notifyListeners();
  }

  int _batchSize = 10;

  int get batchSize => _batchSize;

  void setBatchSize(int size) {
    _batchSize = size;
    notifyListeners();
  }

  // --- Dual Transport Toggles ---
  bool _isWifiEnabled = true;
  bool get isWifiEnabled => _isWifiEnabled;

  void setWifiEnabled(bool enabled) {
    _isWifiEnabled = enabled;
    notifyListeners();
  }

  bool _isBleEnabled = true;
  bool get isBleEnabled => _isBleEnabled;

  void setBleEnabled(bool enabled) {
    _isBleEnabled = enabled;
    notifyListeners();
  }

  String _bleDeviceName = 'Pokidex-EEG';
  String get bleDeviceName => _bleDeviceName;

  void setBleDeviceName(String name) {
    _bleDeviceName = name;
    notifyListeners();
  }
}