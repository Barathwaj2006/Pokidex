import 'dart:async';

import 'package:flutter/foundation.dart';

import '../engines/eeg_engine.dart';
import '../engines/erp_engine.dart';
import '../engines/signal_engine.dart';
import '../models/eeg_config.dart';
import '../models/signal_frame.dart';
import '../services/ground_truth_service.dart';
import '../services/session_service.dart';
import '../transport/ble_peripheral_transport.dart';
import '../transport/multi_signal_transport.dart';
import '../transport/signal_transport.dart';
import '../transport/websocket_transport.dart';
import 'app_state_provider.dart';

class SignalProvider extends ChangeNotifier {
  final AppStateProvider appState;
  final GroundTruthService groundTruthService;
  final SessionService sessionService;

  SignalEngine? _engine;
  MultiSignalTransport? _multiTransport;
  WebSocketTransport? _wifiTransport;
  BlePeripheralTransport? _bleTransport;

  StreamSubscription<SignalFrame>? _engineSub;

  static const _bufferSize = 500;
  final List<List<double>> _waveformBuffer = [];
  int _channelCount = 4;

  int _packetCount = 0;
  Timer? _rateTimer;

  TransportStatus _transportStatus = TransportStatus.stopped;
  TransportStatus get transportStatus => _transportStatus;

  final List<String> _infoMessages = [];
  List<String> get infoMessages => List.unmodifiable(_infoMessages);

  final List<SignalFrame> _batchBuffer = [];

  ErpEngine? _erpEngine;

  SignalProvider({
    required this.appState,
    required this.groundTruthService,
    required this.sessionService,
  });

  List<List<double>> get waveformBuffer => _waveformBuffer;
  int get channelCount => _channelCount;

  bool get isServerRunning =>
      _transportStatus != TransportStatus.stopped &&
      _transportStatus != TransportStatus.error;

  int get connectedClientCount =>
      _multiTransport?.connectedClientCount ?? 0;

  TransportStatus get wifiStatus =>
      _wifiTransport?.status ?? TransportStatus.stopped;

  TransportStatus get bleStatus =>
      _bleTransport?.status ?? TransportStatus.stopped;

  int get wifiConnectedCount =>
      _wifiTransport?.connectedClientCount ?? 0;

  int get bleConnectedCount =>
      _bleTransport?.connectedClientCount ?? 0;

  Future<void> startServer() async {
    _multiTransport?.dispose();

    _wifiTransport = WebSocketTransport(port: appState.wsPort);
    _bleTransport = BlePeripheralTransport(deviceName: appState.bleDeviceName);

    _multiTransport = MultiSignalTransport(
      wifiTransport: _wifiTransport!,
      bleTransport: _bleTransport!,
    );
    _multiTransport!.setWifiEnabled(appState.isWifiEnabled);
    _multiTransport!.setBleEnabled(appState.isBleEnabled);

    _multiTransport!.statusStream.listen((s) {
      _transportStatus = s;
      notifyListeners();
    });

    _multiTransport!.infoStream.listen((msg) {
      _infoMessages.add(msg);
      if (_infoMessages.length > 300) _infoMessages.removeAt(0);
      notifyListeners();
    });

    await _multiTransport!.start();
    notifyListeners();
  }

  Future<void> stopServer() async {
    await stopStreaming();
    await _multiTransport?.stop();
    _multiTransport = null;
    _wifiTransport = null;
    _bleTransport = null;
    _transportStatus = TransportStatus.stopped;
    notifyListeners();
  }

  Future<void> startStreaming() async {
    if (appState.isStreaming) return;

    sessionService.resetSession();
    sessionService.markStart();

    _channelCount = appState.eegConfig.channelCount;
    _initWaveformBuffer(_channelCount);

    _engine?.dispose();
    _erpEngine = null;

    if (appState.activeEngine == ActiveEngine.eeg) {
      _engine = EegEngine(
        config: appState.eegConfig,
        groundTruthService: groundTruthService,
        sessionId: sessionService.sessionId,
      );
    } else {
      final erpEng = ErpEngine(
        eegConfig: appState.eegConfig,
        erpConfig: appState.erpConfig,
        groundTruthService: groundTruthService,
        sessionId: sessionService.sessionId,
      );
      _engine = erpEng;
      _erpEngine = erpEng;
    }

    final metadata = SignalFrameMetadata(
      source: 'pokidex',
      signalType: appState.activeEngine == ActiveEngine.eeg
          ? SignalType.eeg
          : SignalType.vep,
      channelCount: _channelCount,
      channelNames: EegConfig.defaultChannelNames(_channelCount),
      samplingRate: appState.eegConfig.samplingRate,
      unit: 'uV',
      sessionId: sessionService.sessionId,
    );
    await _multiTransport?.send(SignalFrame(metadata: metadata));

    _engineSub = _engine!.frames.listen(_onFrame);
    _engine!.start();

    _startRateTimer();
    appState.setStreaming(true);
    notifyListeners();
  }

  void _onFrame(SignalFrame frame) {
    if (frame.data != null) {
      final samples = frame.data!.channelSamples;
      for (int ch = 0; ch < samples.length && ch < _channelCount; ch++) {
        _waveformBuffer[ch].add(samples[ch]);
        if (_waveformBuffer[ch].length > _bufferSize) {
          _waveformBuffer[ch].removeAt(0);
        }
      }
    }

    _batchBuffer.add(frame);
    if (_batchBuffer.length >= appState.batchSize) {
      _flushBatch();
    }
  }

  void _flushBatch() {
    if (_batchBuffer.isEmpty || _multiTransport == null) {
      _batchBuffer.clear();
      return;
    }
    for (final f in _batchBuffer) {
      _multiTransport!.send(f);
      _packetCount++;
    }
    _batchBuffer.clear();
    notifyListeners();
  }

  void _startRateTimer() {
    _rateTimer?.cancel();
    _rateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      appState.setPacketsPerSecond(_packetCount);
      _packetCount = 0;
    });
  }

  Future<void> stopStreaming() async {
    _rateTimer?.cancel();
    await _engineSub?.cancel();
    _flushBatch();
    _engine?.stop();
    appState.setStreaming(false);
    notifyListeners();
  }

  void fireManualTrigger() {
    _erpEngine?.fireTrigger();
  }

  void _initWaveformBuffer(int channels) {
    _waveformBuffer.clear();
    for (int i = 0; i < channels; i++) {
      _waveformBuffer.add([]);
    }
  }

  Future<List<String>> getLocalIps() async {
    if (_wifiTransport == null) return [];
    return _wifiTransport!.getLocalIps();
  }

  @override
  void dispose() {
    _engine?.dispose();
    _rateTimer?.cancel();
    super.dispose();
  }
}