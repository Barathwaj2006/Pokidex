import 'package:flutter/foundation.dart';

import '../models/eeg_config.dart';
import '../models/erp_config.dart';
import '../models/scenario.dart';
import '../transport/ble_peripheral_transport.dart';

enum ActiveEngine { eeg, erp }

class AppStateProvider extends ChangeNotifier {
  // --- Authentication & Session State ---
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  String _researcherName = 'Barathwaj R.';
  String get researcherName => _researcherName;

  String _researcherEmail = 'researcher@bci-lab.org';
  String get researcherEmail => _researcherEmail;

  String _institution = 'Cognitive Neuroscience & BCI Laboratory';
  String get institution => _institution;

  String _researcherRole = 'Principal Investigator';
  String get researcherRole => _researcherRole;

  bool _termsAccepted = false;
  bool get termsAccepted => _termsAccepted;

  DateTime? _termsAcceptedAt;
  DateTime? get termsAcceptedAt => _termsAcceptedAt;

  void acceptTerms() {
    _termsAccepted = true;
    _termsAcceptedAt = DateTime.now();
    notifyListeners();
  }

  void setTermsAccepted(bool accepted) {
    _termsAccepted = accepted;
    if (accepted) {
      _termsAcceptedAt = DateTime.now();
    }
    notifyListeners();
  }

  bool login({
    required String email,
    required String password,
    String? name,
    String? role,
    String? institution,
  }) {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      return false;
    }
    _isLoggedIn = true;
    _researcherEmail = email.trim();
    if (name != null && name.isNotEmpty) _researcherName = name;
    if (role != null && role.isNotEmpty) _researcherRole = role;
    if (institution != null && institution.isNotEmpty) _institution = institution;
    _termsAccepted = true;
    _termsAcceptedAt ??= DateTime.now();
    notifyListeners();
    return true;
  }

  void loginAsGuest({String role = 'Laboratory Guest Investigator'}) {
    _isLoggedIn = true;
    _researcherName = 'Guest Researcher';
    _researcherEmail = 'demo@pokidex-bci.local';
    _researcherRole = role;
    _termsAccepted = true;
    _termsAcceptedAt ??= DateTime.now();
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }

  // --- Engine & Telemetry State ---
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

  BleStreamFormat _bleFormat = BleStreamFormat.binary;
  BleStreamFormat get bleFormat => _bleFormat;

  void setBleFormat(BleStreamFormat format) {
    _bleFormat = format;
    notifyListeners();
  }
}