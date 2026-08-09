import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:web_socket_channel/io.dart';
import '../models/connection_state_step.dart';
import '../models/qr_pairing_payload.dart';
import '../models/signal_frame.dart';

class ClientWebSocketConnection {
  final QrPairingPayload payload;
  IOWebSocketChannel? _channel;
  StreamSubscription? _subscription;

  final _stepController = StreamController<ConnectionStateStep>.broadcast();
  final _messageController = StreamController<String>.broadcast();

  ConnectionStateStep _step = ConnectionStateStep.idle;
  bool _handshakeComplete = false;

  ClientWebSocketConnection({required this.payload});

  ConnectionStateStep get step => _step;
  bool get isConnected => _step.isConnected;
  bool get isReady => _step == ConnectionStateStep.ready || _step == ConnectionStateStep.streaming;
  bool get isStreaming => _step == ConnectionStateStep.streaming;

  Stream<ConnectionStateStep> get stepStream => _stepController.stream;
  Stream<String> get messageStream => _messageController.stream;

  Future<bool> connectAndHandshake({Duration timeout = const Duration(seconds: 5)}) async {
    _setStep(ConnectionStateStep.connecting);
    _messageController.add('Connecting to PyroSync at ${payload.host}:${payload.port}...');

    final wsUri = Uri.parse('ws://${payload.host}:${payload.port}');

    try {
      final socket = await WebSocket.connect(wsUri.toString()).timeout(timeout);
      _channel = IOWebSocketChannel(socket);
      _setStep(ConnectionStateStep.connected);
      _messageController.add('✓ Connected to PyroSync socket');
    } catch (e) {
      _setStep(ConnectionStateStep.networkUnreachable);
      _messageController.add('Cannot reach PyroSync: $e');
      return false;
    }

    _setStep(ConnectionStateStep.handshaking);
    _messageController.add('Initiating mutual handshake...');

    final handshakeCompleter = Completer<bool>();

    _subscription = _channel!.stream.listen(
      (data) {
        _handleInboundMessage(data, handshakeCompleter);
      },
      onDone: () {
        _handleDisconnect('Connection closed by PyroSync.');
        if (!handshakeCompleter.isCompleted) {
          handshakeCompleter.complete(false);
        }
      },
      onError: (error) {
        _handleDisconnect('Socket error: $error');
        if (!handshakeCompleter.isCompleted) {
          handshakeCompleter.complete(false);
        }
      },
      cancelOnError: false,
    );

    _sendJson({
      'type': 'HELLO',
      'protocol': payload.protocol,
      'version': payload.version,
      'session_id': payload.sessionId,
      'token': payload.token,
      'source': 'pokidex',
    });

    try {
      final success = await handshakeCompleter.future.timeout(const Duration(seconds: 6));
      return success;
    } catch (_) {
      if (!handshakeCompleter.isCompleted) {
        _setStep(ConnectionStateStep.handshakeFailed);
        _messageController.add('Handshake timed out waiting for PyroSync ACK.');
        _disconnectSocket();
      }
      return false;
    }
  }

  void _handleInboundMessage(dynamic data, Completer<bool> handshakeCompleter) {
    try {
      final json = jsonDecode(data.toString()) as Map<String, dynamic>;
      final type = json['type'] as String?;

      if (type == 'HELLO_ACK' || type == 'HELLO') {
        _sendJson({'type': 'HELLO_ACK', 'session_id': payload.sessionId});
      } else if (type == 'SESSION_ACCEPTED') {
        _sendJson({'type': 'READY', 'session_id': payload.sessionId});
      } else if (type == 'START_STREAM') {
        _handshakeComplete = true;
        _setStep(ConnectionStateStep.ready);
        _messageController.add('✓ PyroSync READY for signal stream');
        if (!handshakeCompleter.isCompleted) {
          handshakeCompleter.complete(true);
        }
      } else if (type == 'SIGNAL_STREAMING') {
        _setStep(ConnectionStateStep.streaming);
        _messageController.add('✓ SIGNAL STREAMING ACTIVE');
      } else if (type == 'PING') {
        _sendJson({'type': 'PONG'});
      }
    } catch (_) {}
  }

  void notifyStreamStarted() {
    if (_handshakeComplete) {
      _setStep(ConnectionStateStep.streaming);
      _sendJson({
        'type': 'SIGNAL_STREAMING',
        'session_id': payload.sessionId,
      });
    }
  }

  bool sendFrame(SignalFrame frame) {
    if (_channel == null || !isConnected) return false;
    try {
      _channel!.sink.add(frame.toJsonString());
      return true;
    } catch (e) {
      _handleDisconnect('Transmission error: $e');
      return false;
    }
  }

  void _sendJson(Map<String, dynamic> json) {
    try {
      _channel?.sink.add(jsonEncode(json));
    } catch (_) {}
  }

  void _handleDisconnect(String reason) {
    _handshakeComplete = false;
    _setStep(ConnectionStateStep.connectionFailed);
    _messageController.add(reason);
    _disconnectSocket();
  }

  void _disconnectSocket() {
    _subscription?.cancel();
    _subscription = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  void disconnect() {
    _setStep(ConnectionStateStep.idle);
    _messageController.add('Disconnected.');
    _disconnectSocket();
  }

  void _setStep(ConnectionStateStep s) {
    _step = s;
    _stepController.add(s);
  }

  void dispose() {
    disconnect();
    _stepController.close();
    _messageController.close();
  }
}