import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokidex/models/connection_state_step.dart';
import 'package:pokidex/models/qr_pairing_payload.dart';
import 'package:pokidex/models/signal_frame.dart';
import 'package:pokidex/transport/client_websocket_connection.dart';

void main() {
  group('Pokidex ↔ PyroSync Live End-to-End Network Connectivity & Handshake Verification', () {
    late HttpServer mockPyroSyncServer;
    late List<WebSocket> activeSockets;
    late String testToken;
    late String testSessionId;

    setUp(() async {
      activeSockets = [];
      testToken = 'A1B2C3D4E5F67890';
      testSessionId = 'PX-TEST-SESSION-999';

      // Bind real PyroSync QR Pairing WebSocket Server on localhost port 8768
      mockPyroSyncServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 8768);
    });

    tearDown(() async {
      for (final ws in activeSockets) {
        await ws.close();
      }
      await mockPyroSyncServer.close(force: true);
    });

    test('1. Full E2E Mutual Handshake & SignalFrame TCP Stream Verification', () async {
      final String qrJson = jsonEncode({
        'protocol': 'pyrosync-pokidex',
        'version': 1,
        'session_id': testSessionId,
        'host': '127.0.0.1',
        'port': 8768,
        'token': testToken,
        'expires_at': DateTime.now().add(const Duration(minutes: 5)).toIso8601String(),
      });

      // 1. Validate QR payload extraction on Pokidex side
      final qrResult = QrPairingPayload.parseAndValidate(qrJson);
      expect(qrResult.isValid, isTrue);
      final qrPayload = qrResult.payload!;
      expect(qrPayload.sessionId, equals(testSessionId));
      expect(qrPayload.token, equals(testToken));
      expect(qrPayload.port, equals(8768));

      final connection = ClientWebSocketConnection(payload: qrPayload);
      final List<ConnectionStateStep> clientSteps = [];
      connection.stepStream.listen((s) => clientSteps.add(s));

      final Completer<bool> serverHandshakeCompleted = Completer<bool>();
      final List<Map<String, dynamic>> receivedSignalFrames = [];

      // Server-side behavior simulating PyroSync PokidexQrPairingServer
      mockPyroSyncServer.listen((HttpRequest request) async {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          final socket = await WebSocketTransformer.upgrade(request);
          activeSockets.add(socket);

          // Step 1: Server sends HELLO
          socket.add(jsonEncode({
            'type': 'handshake',
            'action': 'HELLO',
            'protocol': 'pyrosync-pokidex',
            'version': 1,
            'session_id': testSessionId,
          }));

          socket.listen((data) {
            final Map<String, dynamic> msg = jsonDecode(data.toString());

            if (msg['type'] == 'handshake') {
              final action = msg['action'];

              if (action == 'HELLO_ACK') {
                // Verify Pokidex submitted correct token & session
                expect(msg['token'], equals(testToken));
                expect(msg['session_id'], equals(testSessionId));

                // Step 3: Server sends SESSION_ACCEPTED
                socket.add(jsonEncode({
                  'type': 'handshake',
                  'action': 'SESSION_ACCEPTED',
                  'session_id': testSessionId,
                }));
              } else if (action == 'READY') {
                // Step 5: Server commands START_STREAM
                socket.add(jsonEncode({
                  'type': 'handshake',
                  'action': 'START_STREAM',
                  'session_id': testSessionId,
                }));
              } else if (action == 'SIGNAL_STREAMING') {
                serverHandshakeCompleted.complete(true);
              }
            } else if (msg.containsKey('metadata') && msg.containsKey('data')) {
              // Store incoming SignalFrames from Pokidex
              receivedSignalFrames.add(msg);
            }
          });
        }
      });

      // 2. Connect Pokidex WebSocket client to real local server socket and run mutual handshake
      final handshakeSuccess = await connection.connectAndHandshake();
      expect(handshakeSuccess, isTrue);

      // Pokidex notifies stream started
      connection.notifyStreamStarted();

      // Wait for server to receive SIGNAL_STREAMING confirmation
      final serverOk = await serverHandshakeCompleted.future.timeout(const Duration(seconds: 5));
      expect(serverOk, isTrue);

      // 3. Verify Pokidex client connection step transitions
      expect(connection.step, equals(ConnectionStateStep.streaming));
      expect(connection.isStreaming, isTrue);
      expect(clientSteps, contains(ConnectionStateStep.connecting));
      expect(clientSteps, contains(ConnectionStateStep.handshaking));
      expect(clientSteps, contains(ConnectionStateStep.ready));
      expect(clientSteps, contains(ConnectionStateStep.streaming));

      // 4. Stream 50 high-frequency SignalFrame JSON packets over real TCP socket
      for (int i = 1; i <= 50; i++) {
        final frame = SignalFrame(
          metadata: SignalFrameMetadata(
            source: 'Pokidex-Android-E2E',
            signalType: SignalType.eeg,
            channelCount: 8,
            channelNames: const ['Fp1', 'Fp2', 'C3', 'C4', 'P3', 'P4', 'O1', 'O2'],
            samplingRate: 250,
            unit: 'uV',
            sessionId: testSessionId,
          ),
          data: SignalFrameData(
            timestamp: DateTime.now().millisecondsSinceEpoch.toDouble(),
            sequence: i,
            channelSamples: List.generate(8, (ch) => 10.0 + ch),
          ),
          events: i % 10 == 0
              ? [SignalFrameEvent(timestamp: DateTime.now().millisecondsSinceEpoch.toDouble(), eventType: 'vep_flash', value: '1')]
              : const [],
        );

        final ok = connection.sendFrame(frame);
        expect(ok, isTrue);
        await Future.delayed(const Duration(milliseconds: 2));
      }

      await Future.delayed(const Duration(milliseconds: 200));

      // 5. Verify server received all 50 frames with zero packet loss
      expect(receivedSignalFrames.length, equals(50));
      expect(receivedSignalFrames.first['data']['sequence'], equals(1));
      expect(receivedSignalFrames.last['data']['sequence'], equals(50));
      expect(receivedSignalFrames.first['metadata']['channel_count'], equals(8));
      expect(receivedSignalFrames.first['metadata']['source'], equals('Pokidex-Android-E2E'));

      // 6. Test graceful disconnection
      connection.disconnect();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(connection.step, equals(ConnectionStateStep.idle));
      expect(connection.isConnected, isFalse);
    });
  });
}
