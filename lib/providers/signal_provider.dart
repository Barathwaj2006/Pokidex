import 'dart:async';

import 'package:flutter/foundation.dart';

import '../engines/eeg_engine.dart';
import '../engines/erp_engine.dart';
import '../engines/signal_engine.dart';
import '../models/connection_state_step.dart';
import '../models/eeg_config.dart';
import '../models/qr_pairing_payload.dart';
import '../models/signal_frame.dart';
import '../models/transmission_diagnostics.dart';
import '../services/ground_truth_service.dart';
import '../services/session_service.dart';
import '../transport/ble_peripheral_transport.dart';
import '../transport/client_websocket_connection.dart';
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

  ClientWebSocketConnection? _clientConnection;
  QrPairingPayload? _activeQrPayload;

  StreamSubscription<SignalFrame>? _engineSub;
  StreamSubscription<ConnectionStateStep>? _connectionStepSub;

  ConnectionStateStep _connectionStep = ConnectionStateStep.idle;
  ConnectionStateStep get connectionStep => _connectionStep;

  String? _qrError;
  String? get qrError => _qrError;

  static const _bufferSize = 500;
  final List<List<double>> _waveformBuffer = [];
  int _channelCount = 4;

  // Diagnostics & Queue Monitoring
  int _framesGenerated = 0;
  int _framesSent = 0;
  int _framesFailed = 0;
  int _errorCount = 0;
  int _lastSequenceNumber = 0;
  static const int maxQueueDepth = 50;
  final List<SignalFrame> _sendQueue = [];

  double _actualGenRate = 0.0;
  double _actualTxRate = 0.0;
  int _genTicksCount = 0;
  int _txTicksCount = 0;
  Timer? _rateTimer;

  TransportStatus _transportStatus = TransportStatus.stopped;
  TransportStatus get transportStatus => _transportStatus;

  final List<String> _infoMessages = [];
  List<String> get infoMessages => List.unmodifiable(_infoMessages);

  ErpEngine? _erpEngine;

  SignalProvider({
    required this.appState,
    required this.groundTruthService,
    required this.sessionService,
  });

  List<List<double>> get waveformBuffer => _waveformBuffer;
  int get channelCount => _channelCount;
  QrPairingPayload? get activeQrPayload => _activeQrPayload;

  bool get isServerRunning =>
      _transportStatus != TransportStatus.stopped &&
      _transportStatus != TransportStatus.error;

  int get connectedClientCount =>
      (_multiTransport?.connectedClientCount ?? 0) +
      (_clientConnection?.isConnected == true ? 1 : 0);

  bool get isVerifiedConnected =>
      _clientConnection?.isReady == true ||
      _clientConnection?.isStreaming == true ||
      (_multiTransport?.connectedClientCount ?? 0) > 0;

  bool get isStreamingSignal => appState.isStreaming;

  TransmissionDiagnostics get diagnostics {
    final totalGen = _framesGenerated == 0 ? 1 : _framesGenerated;
    return TransmissionDiagnostics(
      configuredSamplingRate: appState.eegConfig.samplingRate,
      actualGenerationRate: _actualGenRate,
      actualTransmissionRate: _actualTxRate,
      framesGenerated: _framesGenerated,
      framesSent: _framesSent,
      framesFailed: _framesFailed,
      sendQueueDepth: _sendQueue.length,
      lastSequenceNumber: _lastSequenceNumber,
      errorCount: _errorCount,
      droppedFramePercent: (_framesFailed / totalGen) * 100.0,
    );
  }

  // ==========================================
  // QR PAIRING & CLIENT CONNECTION FLOW
  // ==========================================

  void resetConnectionState() {
    _qrError = null;
    _setConnectionStep(ConnectionStateStep.idle);
  }

  Future<bool> processScannedQr(String rawQrJson) async {
    _qrError = null;
    _setConnectionStep(ConnectionStateStep.qrScanner);

    final validation = QrPairingPayload.parseAndValidate(rawQrJson);
    if (!validation.isValid) {
      _qrError = validation.errorMessage;
      _setConnectionStep(ConnectionStateStep.qrInvalid);
      _logInfo('[QR ERROR] $_qrError');
      return false;
    }

    _activeQrPayload = validation.payload!;
    _setConnectionStep(ConnectionStateStep.qrValidated);
    _logInfo('[QR SUCCESS] Validated payload for session ${_activeQrPayload!.sessionId}');
    return true;
  }

  Future<bool> connectToPairingPayload() async {
    if (_activeQrPayload == null) return false;

    _clientConnection?.dispose();
    _clientConnection = ClientWebSocketConnection(payload: _activeQrPayload!);

    _connectionStepSub?.cancel();
    _connectionStepSub = _clientConnection!.stepStream.listen((step) {
      _setConnectionStep(step);
    });

    _clientConnection!.messageStream.listen((msg) {
      _logInfo('[PAIRING] $msg');
    });

    final success = await _clientConnection!.connectAndHandshake();
    if (success) {
      _logInfo('[CONNECTED] PyroSync Handshake Complete & Verified Ready.');
      await startStreaming();
    }
    return success;
  }

  void disconnectPairing() {
    stopStreaming();
    _clientConnection?.disconnect();
    _clientConnection = null;
    _activeQrPayload = null;
    _setConnectionStep(ConnectionStateStep.idle);
  }

  // ==========================================
  // MULTI-TRANSPORT SERVER LIFECYCLE
  // ==========================================

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

    _multiTransport!.infoStream.listen((msg) => _logInfo(msg));

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

  // ==========================================
  // SIGNAL STREAMING ENGINE LIFECYCLE
  // ==========================================

  Future<void> startStreaming() async {
    if (appState.isStreaming) return;

    // Reset counters & session
    _framesGenerated = 0;
    _framesSent = 0;
    _framesFailed = 0;
    _errorCount = 0;
    _lastSequenceNumber = 0;
    _sendQueue.clear();

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

    // Broadcast Initial Metadata Contract Frame
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

    final metaFrame = SignalFrame(metadata: metadata);
    _dispatchFrame(metaFrame);

    _engineSub = _engine!.frames.listen(_onFrame);
    _engine!.start();

    _clientConnection?.notifyStreamStarted();
    _setConnectionStep(ConnectionStateStep.streaming);

    _startRateTimer();
    appState.setStreaming(true);
    notifyListeners();
  }

  void _onFrame(SignalFrame frame) {
    _framesGenerated++;
    _genTicksCount++;

    if (frame.data != null) {
      _lastSequenceNumber = frame.data!.sequence;
      final samples = frame.data!.channelSamples;
      for (int ch = 0; ch < samples.length && ch < _channelCount; ch++) {
        _waveformBuffer[ch].add(samples[ch]);
        if (_waveformBuffer[ch].length > _bufferSize) {
          _waveformBuffer[ch].removeAt(0);
        }
      }
    }

    _dispatchFrame(frame);
  }

  void _dispatchFrame(SignalFrame frame) {
    bool sentAny = false;

    // Send via active QR pairing client
    if (_clientConnection?.isConnected == true) {
      final ok = _clientConnection!.sendFrame(frame);
      if (ok) {
        sentAny = true;
      } else {
        _framesFailed++;
        _errorCount++;
      }
    }

    // Send via server transports (Wi-Fi WebSocket / BLE)
    if (_multiTransport != null && _multiTransport!.connectedClientCount > 0) {
      _multiTransport!.send(frame);
      sentAny = true;
    }

    if (sentAny) {
      _framesSent++;
      _txTicksCount++;
    } else {
      // Queue frame up to max depth to avoid unlimited memory growth
      if (_sendQueue.length < maxQueueDepth) {
        _sendQueue.add(frame);
      } else {
        _sendQueue.removeAt(0);
        _sendQueue.add(frame);
        _framesFailed++;
      }
    }
  }

  void _startRateTimer() {
    _rateTimer?.cancel();
    _genTicksCount = 0;
    _txTicksCount = 0;

    _rateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _actualGenRate = _genTicksCount.toDouble();
      _actualTxRate = _txTicksCount.toDouble();
      appState.setPacketsPerSecond(_txTicksCount);

      _genTicksCount = 0;
      _txTicksCount = 0;
      notifyListeners();
    });
  }

  Future<void> stopStreaming() async {
    _rateTimer?.cancel();
    await _engineSub?.cancel();
    _engine?.stop();
    appState.setStreaming(false);

    if (_connectionStep == ConnectionStateStep.streaming) {
      _setConnectionStep(ConnectionStateStep.ready);
    }

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

  void _setConnectionStep(ConnectionStateStep step) {
    _connectionStep = step;
    notifyListeners();
  }

  void _logInfo(String msg) {
    _infoMessages.add(msg);
    if (_infoMessages.length > 300) _infoMessages.removeAt(0);
    notifyListeners();
  }

  Future<List<String>> getLocalIps() async {
    if (_wifiTransport == null) return [];
    return _wifiTransport!.getLocalIps();
  }

  @override
  void dispose() {
    _engine?.dispose();
    _rateTimer?.cancel();
    _clientConnection?.dispose();
    _multiTransport?.dispose();
    super.dispose();
  }
}