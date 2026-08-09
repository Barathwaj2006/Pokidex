import 'package:flutter_test/flutter_test.dart';
import 'package:pokidex/models/qr_pairing_payload.dart';
import 'package:pokidex/models/signal_frame.dart';

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
}