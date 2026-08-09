import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';

import '../models/signal_frame.dart';
import 'signal_transport.dart';

/// Bluetooth LE Peripheral transport — advertises a custom GATT service
/// (UUID: 0000fe50-0000-1000-8000-00805f9b34fb) and Streams SignalFrame
/// JSON chunks via GATT notifications.
class BlePeripheralTransport implements SignalTransport {
  final String deviceName;

  static const MethodChannel _methodChannel =
      MethodChannel('com.pokidex.pokidex/ble');
  static const EventChannel _eventChannel =
      EventChannel('com.pokidex.pokidex/ble_events');

  final _statusController = StreamController<TransportStatus>.broadcast();
  final _infoController = StreamController<String>.broadcast();

  TransportStatus _status = TransportStatus.stopped;
  int _connectedClientCount = 0;
  int _currentMtu = 23; // Default BLE MTU
  StreamSubscription? _eventSub;
  int _sequenceCounter = 0;

  BlePeripheralTransport({this.deviceName = 'Pokidex-EEG'});

  @override
  TransportStatus get status => _status;

  @override
  int get connectedClientCount => _connectedClientCount;

  @override
  Stream<TransportStatus> get statusStream => _statusController.stream;

  @override
  Stream<String> get infoStream => _infoController.stream;

  @override
  Future<void> start() async {
    if (_status != TransportStatus.stopped) return;
    _setStatus(TransportStatus.starting);

    _eventSub?.cancel();
    _eventSub = _eventChannel.receiveBroadcastStream().listen((event) {
      if (event is Map) {
        final type = event['type'];
        final message = event['message'] as String?;
        if (type == 'log' && message != null) {
          _infoController.add('[BLE] $message');
          _updateStatusFromMessage(message);
        }
      }
    });

    try {
      final res = await _methodChannel.invokeMethod<bool>('startAdvertising', {
        'deviceName': deviceName,
      });
      if (res == true) {
        _setStatus(TransportStatus.waiting);
      } else {
        _setStatus(TransportStatus.error);
      }
    } catch (e) {
      _setStatus(TransportStatus.error);
      _infoController.add('[BLE ERROR] Failed to start advertising: $e');
    }
  }

  void _updateStatusFromMessage(String msg) {
    if (msg.contains('connected:')) {
      _connectedClientCount++;
      _setStatus(TransportStatus.connected);
    } else if (msg.contains('disconnected:')) {
      if (_connectedClientCount > 0) _connectedClientCount--;
      if (_connectedClientCount == 0) {
        _setStatus(TransportStatus.waiting);
      }
    } else if (msg.contains('MTU updated to')) {
      final parts = msg.split('MTU updated to');
      if (parts.length > 1) {
        final mtuVal = int.tryParse(parts[1].trim().split(' ')[0]);
        if (mtuVal != null) _currentMtu = mtuVal;
      }
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _methodChannel.invokeMethod('stopAdvertising');
    } catch (_) {}
    _eventSub?.cancel();
    _connectedClientCount = 0;
    _setStatus(TransportStatus.stopped);
    _infoController.add('[BLE] Transport stopped');
  }

  @override
  Future<void> send(SignalFrame frame) async {
    if (_connectedClientCount == 0) return;

    final jsonStr = frame.toJsonString();
    final jsonBytes = utf8.encode(jsonStr);

    // Effective chunk payload = currentMtu - 3 (GATT header) - 4 (Packet Chunk Header)
    final maxChunkSize = (_currentMtu - 7).clamp(20, 500);
    final totalChunks = (jsonBytes.length / maxChunkSize).ceil();
    final seq = _sequenceCounter++ % 65536;

    for (int chunkIdx = 0; chunkIdx < totalChunks; chunkIdx++) {
      final start = chunkIdx * maxChunkSize;
      final end = (start + maxChunkSize > jsonBytes.length)
          ? jsonBytes.length
          : start + maxChunkSize;
      final chunkPayload = jsonBytes.sublist(start, end);

      // Packet Header: [seq_msb, seq_lsb, chunk_index, total_chunks]
      final header = [
        (seq >> 8) & 0xFF,
        seq & 0xFF,
        chunkIdx & 0xFF,
        totalChunks & 0xFF,
      ];
      final packetData = Uint8List.fromList([...header, ...chunkPayload]);

      try {
        await _methodChannel.invokeMethod('sendChunk', {'data': packetData});
      } catch (_) {}
    }
  }

  void _setStatus(TransportStatus s) {
    _status = s;
    _statusController.add(s);
  }

  void dispose() {
    stop();
    _statusController.close();
    _infoController.close();
  }
}