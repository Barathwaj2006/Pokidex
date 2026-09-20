import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';

import '../models/signal_frame.dart';
import 'signal_transport.dart';

enum BleStreamFormat {
  binary,
  json,
}

/// Bluetooth LE Peripheral transport — advertises a custom GATT service
/// (UUID: 0000fe50-0000-1000-8000-00805f9b34fb) and streams SignalFrame
/// compact binary packets or JSON chunks via GATT notifications to Web Bluetooth
/// (NeuroSim / Chrome / Edge) with full two-way command support.
class BlePeripheralTransport implements SignalTransport {
  final String deviceName;

  static const MethodChannel _methodChannel =
      MethodChannel('com.pokidex.pokidex/ble');
  static const EventChannel _eventChannel =
      EventChannel('com.pokidex.pokidex/ble_events');

  final _statusController = StreamController<TransportStatus>.broadcast();
  final _infoController = StreamController<String>.broadcast();
  final _commandController = StreamController<String>.broadcast();

  TransportStatus _status = TransportStatus.stopped;
  int _connectedClientCount = 0;
  int _currentMtu = 23; // Default BLE MTU
  StreamSubscription? _eventSub;
  int _sequenceCounter = 0;
  BleStreamFormat _format = BleStreamFormat.binary;

  BlePeripheralTransport({
    this.deviceName = 'Pokidex-EEG',
    BleStreamFormat format = BleStreamFormat.binary,
  }) : _format = format;

  @override
  TransportStatus get status => _status;

  @override
  int get connectedClientCount => _connectedClientCount;

  int get currentMtu => _currentMtu;

  BleStreamFormat get format => _format;

  void setFormat(BleStreamFormat format) {
    _format = format;
  }

  @override
  Stream<TransportStatus> get statusStream => _statusController.stream;

  @override
  Stream<String> get infoStream => _infoController.stream;

  Stream<String> get commandStream => _commandController.stream;

  Future<bool> checkPermissions() async {
    try {
      final res = await _methodChannel.invokeMethod<bool>('checkPermissions');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestPermissions() async {
    try {
      final res = await _methodChannel.invokeMethod<bool>('requestPermissions');
      return res ?? false;
    } catch (e) {
      _infoController.add('[BLE] Permission request error: $e');
      return false;
    }
  }

  Future<bool> isBluetoothEnabled() async {
    try {
      final res = await _methodChannel.invokeMethod<bool>('isBluetoothEnabled');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> start() async {
    if (_status != TransportStatus.stopped) return;
    _setStatus(TransportStatus.starting);

    _eventSub?.cancel();
    _eventSub = _eventChannel.receiveBroadcastStream().listen((event) {
      if (event is Map) {
        final type = event['type'];
        if (type == 'log') {
          final message = event['message'] as String?;
          if (message != null) {
            _infoController.add('[BLE] $message');
            _updateStatusFromMessage(message);
          }
        } else if (type == 'command') {
          final cmd = event['command'] as String?;
          final sender = event['sender'] as String? ?? 'Web';
          if (cmd != null) {
            _infoController.add('[BLE RECV] Command from $sender: "$cmd"');
            _commandController.add(cmd);
          }
        } else if (type == 'connection') {
          final count = event['connectedCount'] as int? ?? 0;
          final mtu = event['mtu'] as int? ?? _currentMtu;
          _connectedClientCount = count;
          _currentMtu = mtu;
          if (_status != TransportStatus.stopped && _status != TransportStatus.starting) {
            _setStatus(_connectedClientCount > 0
                ? TransportStatus.connected
                : TransportStatus.waiting);
          }
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
    if (msg.contains('connected:') || msg.contains('Web/Central device connected')) {
      _connectedClientCount++;
      _setStatus(TransportStatus.connected);
    } else if (msg.contains('disconnected:') || msg.contains('Web/Central device disconnected')) {
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

  /// Sends a raw binary packet (e.g. 13-byte compact frame) directly via GATT
  Future<bool> sendBinary(Uint8List packetData) async {
    if (_connectedClientCount == 0) return false;
    try {
      final res = await _methodChannel.invokeMethod<bool>('sendBinary', {'data': packetData});
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> send(SignalFrame frame) async {
    if (_connectedClientCount == 0) return;

    if (_format == BleStreamFormat.binary && frame.data != null) {
      // High-speed atomic binary packet: fits inside base MTU without chunking!
      // Header: [0xAA, 0x01, seq_msb, seq_lsb, channel_count]
      final seq = frame.data!.sequence & 0xFFFF;
      final chSamples = frame.data!.channelSamples;
      final chCount = chSamples.length.clamp(1, 16);

      final byteData = ByteData(5 + (chCount * 2));
      byteData.setUint8(0, 0xAA); // Magic start byte
      byteData.setUint8(1, 0x01); // Frame type: Neural data
      byteData.setUint16(2, seq, Endian.big);
      byteData.setUint8(4, chCount);

      // Encode each channel sample as Int16 (microvolts scaled x10: range -3276.8 uV to +3276.7 uV)
      for (int i = 0; i < chCount; i++) {
        final scaled = (chSamples[i] * 10.0).round().clamp(-32768, 32767);
        byteData.setInt16(5 + (i * 2), scaled, Endian.big);
      }

      await sendBinary(byteData.buffer.asUint8List());
      return;
    }

    // Fallback or explicit JSON chunked mode
    final jsonStr = frame.toJsonString();
    final jsonBytes = utf8.encode(jsonStr);

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
        if (totalChunks > 1) {
          await Future.delayed(Duration.zero);
        }
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
    _commandController.close();
  }
}