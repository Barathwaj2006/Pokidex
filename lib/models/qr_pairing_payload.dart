import 'dart:convert';

class QrPayloadValidationResult {
  final bool isValid;
  final String? errorMessage;
  final QrPairingPayload? payload;

  const QrPayloadValidationResult.success(this.payload)
      : isValid = true,
        errorMessage = null;

  const QrPayloadValidationResult.failure(this.errorMessage)
      : isValid = false,
        payload = null;
}

class QrPairingPayload {
  final String protocol;
  final int version;
  final String sessionId;
  final String host;
  final int port;
  final String transport;
  final String token;
  final DateTime? expiresAt;

  const QrPairingPayload({
    required this.protocol,
    required this.version,
    required this.sessionId,
    required this.host,
    required this.port,
    required this.transport,
    required this.token,
    this.expiresAt,
  });

  static QrPayloadValidationResult parseAndValidate(String rawJson) {
    if (rawJson.trim().isEmpty) {
      return const QrPayloadValidationResult.failure('QR code payload is empty.');
    }

    Map<String, dynamic> json;
    try {
      json = jsonDecode(rawJson) as Map<String, dynamic>;
    } catch (_) {
      return const QrPayloadValidationResult.failure('Malformed QR code: Invalid JSON string.');
    }

    final protocol = json['protocol'] as String?;
    if (protocol != 'pyrosync-pokidex' && protocol != 'pyrosync') {
      return QrPayloadValidationResult.failure(
        'Invalid protocol "$protocol". Expected "pyrosync-pokidex".',
      );
    }

    final version = json['version'];
    if (version == null || (version is int && version != 1)) {
      return QrPayloadValidationResult.failure(
        'Unsupported protocol version "$version". Expected 1.',
      );
    }

    final host = json['host'] as String?;
    if (host == null || host.trim().isEmpty) {
      return const QrPayloadValidationResult.failure('Missing host IP in QR payload.');
    }

    final port = json['port'];
    if (port == null || port is! int || port <= 0 || port > 65535) {
      return const QrPayloadValidationResult.failure('Missing or invalid port number in QR payload.');
    }

    final sessionId = json['session_id'] as String?;
    if (sessionId == null || sessionId.trim().isEmpty) {
      return const QrPayloadValidationResult.failure('Missing session_id in QR payload.');
    }

    final token = json['token'] as String?;
    if (token == null || token.trim().isEmpty) {
      return const QrPayloadValidationResult.failure('Missing authentication token in QR payload.');
    }

    DateTime? expiresAt;
    if (json['expires_at'] != null) {
      try {
        expiresAt = DateTime.parse(json['expires_at'].toString());
        if (DateTime.now().isAfter(expiresAt)) {
          return const QrPayloadValidationResult.failure('QR code has expired. Please refresh the QR on PyroSync.');
        }
      } catch (_) {
        return const QrPayloadValidationResult.failure('Invalid expiration timestamp in QR payload.');
      }
    }

    final transport = (json['transport'] as String?) ?? 'websocket';

    return QrPayloadValidationResult.success(
      QrPairingPayload(
        protocol: protocol!,
        version: version is int ? version : 1,
        sessionId: sessionId,
        host: host,
        port: port,
        transport: transport,
        token: token,
        expiresAt: expiresAt,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'protocol': protocol,
        'version': version,
        'session_id': sessionId,
        'host': host,
        'port': port,
        'transport': transport,
        'token': token,
        if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
      };
}