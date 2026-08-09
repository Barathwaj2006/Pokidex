enum ConnectionStateStep {
  idle,
  qrScanner,
  qrValidated,
  connecting,
  connected,
  handshaking,
  ready,
  streaming,

  // Failures
  qrInvalid,
  networkUnreachable,
  connectionFailed,
  handshakeFailed,
  streamError,
}

extension ConnectionStateStepExtension on ConnectionStateStep {
  String get displayLabel {
    switch (this) {
      case ConnectionStateStep.idle:
        return '● Not Connected';
      case ConnectionStateStep.qrScanner:
        return 'Scanning QR Code...';
      case ConnectionStateStep.qrValidated:
        return 'PyroSync Found';
      case ConnectionStateStep.connecting:
        return 'Connecting...';
      case ConnectionStateStep.connected:
        return '✓ Connected to PyroSync';
      case ConnectionStateStep.handshaking:
        return 'Handshaking...';
      case ConnectionStateStep.ready:
        return 'Waiting for signal...';
      case ConnectionStateStep.streaming:
        return '✓ STREAMING';
      case ConnectionStateStep.qrInvalid:
        return 'Invalid QR Code';
      case ConnectionStateStep.networkUnreachable:
        return 'Cannot reach PyroSync';
      case ConnectionStateStep.connectionFailed:
        return 'Connection Failed';
      case ConnectionStateStep.handshakeFailed:
        return 'Handshake Failed';
      case ConnectionStateStep.streamError:
        return 'Streaming Error';
    }
  }

  bool get isConnected {
    return this == ConnectionStateStep.connected ||
        this == ConnectionStateStep.handshaking ||
        this == ConnectionStateStep.ready ||
        this == ConnectionStateStep.streaming;
  }

  bool get isFailure {
    return this == ConnectionStateStep.qrInvalid ||
        this == ConnectionStateStep.networkUnreachable ||
        this == ConnectionStateStep.connectionFailed ||
        this == ConnectionStateStep.handshakeFailed ||
        this == ConnectionStateStep.streamError;
  }
}