import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokidex/models/connection_state_step.dart';
import 'package:pokidex/models/qr_pairing_payload.dart';
import 'package:pokidex/models/signal_frame.dart';
import 'package:pokidex/transport/client_websocket_connection.dart';

void main() {
  group('1. QR Payload Parser Tests', () {
    test('Valid QR Payload parses successfully', () {
      final json = '''
      {
        "protocol": "pyrosync-pokidex",
        "version": 1,
        "session_id": "PX-8842",
        "host": "192.168.1.50",
        "port": 8765,
        "transport": "websocket",
        "token": "tok_xyz123"
      }
      ''';
      final res = QrPairingPayload.parseAndValidate(json);
      expect(res.isValid, isTrue);
      expect(res.payload!.sessionId, equals('PX-8842'));
      expect(res.payload!.host, equals('192.168.1.50'));
      expect(res.payload!.port, equals(8765));
      expect(res.payload!.token, equals('tok_xyz123'));
    });

    test('Invalid protocol rejected', () {
      final json = '{"protocol":"wrong-proto","version":1,"host":"192.168.1.1","port":8765,"session_id":"s1","token":"t1"}';
      final res = QrPairingPayload.parseAndValidate(json);
      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('Invalid protocol'));
    });

    test('Unsupported version rejected', () {
      final json = '{"protocol":"pyrosync-pokidex","version":99,"host":"192.168.1.1","port":8765,"session_id":"s1","token":"t1"}';
      final res = QrPairingPayload.parseAndValidate(json);
      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('Unsupported protocol version'));
    });

    test('Missing host rejected', () {
      final json = '{"protocol":"pyrosync-pokidex","version":1,"port":8765,"session_id":"s1","token":"t1"}';
      final res = QrPairingPayload.parseAndValidate(json);
      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('Missing host IP'));
    });

    test('Missing token rejected', () {
      final json = '{"protocol":"pyrosync-pokidex","version":1,"host":"192.168.1.1","port":8765,"session_id":"s1"}';
      final res = QrPairingPayload.parseAndValidate(json);
      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('Missing authentication token'));
    });

    test('Expired QR timestamp rejected', () {
      final pastDate = DateTime.now().subtract(const Duration(hours: 1)).toIso8601String();
      final json = '{"protocol":"pyrosync-pokidex","version":1,"host":"192.168.1.1","port":8765,"session_id":"s1","token":"t1","expires_at":"$pastDate"}';
      final res = QrPairingPayload.parseAndValidate(json);
      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('QR code has expired'));
    });
  });

  group('2. SignalFrame Serialization & Sequence Tests', () {
    test('SignalFrame serializes metadata, data, and events to valid JSON', () {
      final meta = SignalFrameMetadata(
        source: 'pokidex',
        signalType: SignalType.eeg,
        channelCount: 4,
        channelNames: ['Fp1', 'Fp2', 'O1', 'O2'],
        samplingRate: 250,
        unit: 'uV',
        sessionId: 'SESS-100',
      );

      final data = SignalFrameData(
        timestamp: 1700000000.123,
        sequence: 101,
        channelSamples: [12.4, -5.2, 8.1, 0.4],
      );

      final frame = SignalFrame(metadata: meta, data: data);
      final jsonStr = frame.toJsonString();

      expect(jsonStr, contains('"source":"pokidex"'));
      expect(jsonStr, contains('"signal_type":"eeg"'));
      expect(jsonStr, contains('"sequence":101'));
      expect(jsonStr, contains('"sampling_rate":250'));
    });
  });

  group('3. Pokidex ClientWebSocketConnection Mutual Handshake Tests', () {
    test('Mutual Handshake connects, verifies token & session, and reaches READY step', () async {
      // 1. Create a local mock WebSocket server simulating PyroSync
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8769);
      server.listen((HttpRequest request) async {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          final socket = await WebSocketTransformer.upgrade(request);
          // Step 1: PyroSync server sends HELLO
          socket.add(jsonEncode({
            'type': 'handshake',
            'action': 'HELLO',
            'protocol': 'pyrosync-pokidex',
            'version': 1,
            'session_id': 'PX-TEST-8769',
          }));

          socket.listen((data) {
            final Map<String, dynamic> msg = jsonDecode(data.toString());
            final action = msg['action'];

            if (action == 'HELLO_ACK') {
              // Step 3: PyroSync sends SESSION_ACCEPTED
              socket.add(jsonEncode({
                'type': 'handshake',
                'action': 'SESSION_ACCEPTED',
                'session_id': 'PX-TEST-8769',
              }));
            } else if (action == 'READY') {
              // Step 5: PyroSync sends START_STREAM
              socket.add(jsonEncode({
                'type': 'handshake',
                'action': 'START_STREAM',
                'session_id': 'PX-TEST-8769',
              }));
            }
          });
        }
      });

      final payload = QrPairingPayload(
        protocol: 'pyrosync-pokidex',
        version: 1,
        sessionId: 'PX-TEST-8769',
        host: '127.0.0.1',
        port: 8769,
        transport: 'websocket',
        token: 'tok_test8769',
      );

      final client = ClientWebSocketConnection(payload: payload);
      final steps = <ConnectionStateStep>[];
      client.stepStream.listen((s) => steps.add(s));

      final success = await client.connectAndHandshake(timeout: const Duration(seconds: 3));

      expect(success, isTrue);
      expect(client.isReady, isTrue);
      expect(steps, contains(ConnectionStateStep.connecting));
      expect(steps, contains(ConnectionStateStep.handshaking));
      expect(steps, contains(ConnectionStateStep.ready));

      client.dispose();
      await server.close(force: true);
    });
  });
}