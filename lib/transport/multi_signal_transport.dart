import 'dart:async';

import '../models/signal_frame.dart';
import 'ble_peripheral_transport.dart';
import 'signal_transport.dart';
import 'websocket_transport.dart';

/// Composite SignalTransport that runs WebSocket (Wi-Fi) and BLE Peripheral
/// concurrently and independently for research latency & reliability comparison.
class MultiSignalTransport implements SignalTransport {
  final WebSocketTransport wifiTransport;
  final BlePeripheralTransport bleTransport;

  final _statusController = StreamController<TransportStatus>.broadcast();
  final _infoController = StreamController<String>.broadcast();

  bool _isWifiEnabled = true;
  bool _isBleEnabled = true;

  MultiSignalTransport({
    required this.wifiTransport,
    required this.bleTransport,
  }) {
    wifiTransport.infoStream.listen((msg) => _infoController.add(msg));
    bleTransport.infoStream.listen((msg) => _infoController.add(msg));

    wifiTransport.statusStream.listen((_) => _updateCompositeStatus());
    bleTransport.statusStream.listen((_) => _updateCompositeStatus());
  }

  bool get isWifiEnabled => _isWifiEnabled;
  bool get isBleEnabled => _isBleEnabled;

  void setWifiEnabled(bool enabled) {
    _isWifiEnabled = enabled;
  }

  void setBleEnabled(bool enabled) {
    _isBleEnabled = enabled;
  }

  void _updateCompositeStatus() {
    final wifiStatus = wifiTransport.status;
    final bleStatus = bleTransport.status;

    if (wifiStatus == TransportStatus.connected ||
        bleStatus == TransportStatus.connected) {
      _setStatus(TransportStatus.connected);
    } else if (wifiStatus == TransportStatus.waiting ||
        bleStatus == TransportStatus.waiting) {
      _setStatus(TransportStatus.waiting);
    } else if (wifiStatus == TransportStatus.starting ||
        bleStatus == TransportStatus.starting) {
      _setStatus(TransportStatus.starting);
    } else if (wifiStatus == TransportStatus.error &&
        bleStatus == TransportStatus.error) {
      _setStatus(TransportStatus.error);
    } else {
      _setStatus(TransportStatus.stopped);
    }
  }

  @override
  TransportStatus get status => _compositeStatus();

  TransportStatus _compositeStatus() {
    final wifiStatus = wifiTransport.status;
    final bleStatus = bleTransport.status;
    if (wifiStatus == TransportStatus.connected ||
        bleStatus == TransportStatus.connected) {
      return TransportStatus.connected;
    }
    if (wifiStatus == TransportStatus.waiting ||
        bleStatus == TransportStatus.waiting) {
      return TransportStatus.waiting;
    }
    if (wifiStatus == TransportStatus.starting ||
        bleStatus == TransportStatus.starting) {
      return TransportStatus.starting;
    }
    return TransportStatus.stopped;
  }

  @override
  int get connectedClientCount =>
      wifiTransport.connectedClientCount + bleTransport.connectedClientCount;

  @override
  Stream<TransportStatus> get statusStream => _statusController.stream;

  @override
  Stream<String> get infoStream => _infoController.stream;

  @override
  Future<void> start() async {
    final futures = <Future>[];
    if (_isWifiEnabled) futures.add(wifiTransport.start());
    if (_isBleEnabled) futures.add(bleTransport.start());
    await Future.wait(futures);
    _updateCompositeStatus();
  }

  @override
  Future<void> stop() async {
    await wifiTransport.stop();
    await bleTransport.stop();
    _updateCompositeStatus();
  }

  @override
  Future<void> send(SignalFrame frame) async {
    final List<String> sentTransports = [];
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    if (_isWifiEnabled && wifiTransport.connectedClientCount > 0) {
      wifiTransport.send(frame);
      sentTransports.add('Wi-Fi');
    }

    if (_isBleEnabled && bleTransport.connectedClientCount > 0) {
      bleTransport.send(frame);
      sentTransports.add('BLE');
    }

    if (sentTransports.isNotEmpty && frame.data != null) {
      _infoController.add(
        '[DUAL LOG] Seq #${frame.data!.sequence} dispatched via [${sentTransports.join(', ')}] @ t=$nowMs',
      );
    }
  }

  void _setStatus(TransportStatus s) {
    _statusController.add(s);
  }

  void dispose() {
    wifiTransport.dispose();
    bleTransport.dispose();
    _statusController.close();
    _infoController.close();
  }
}