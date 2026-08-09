class TransmissionDiagnostics {
  final int configuredSamplingRate;
  final double actualGenerationRate;
  final double actualTransmissionRate;
  final int framesGenerated;
  final int framesSent;
  final int framesFailed;
  final int sendQueueDepth;
  final int lastSequenceNumber;
  final int errorCount;
  final double droppedFramePercent;

  const TransmissionDiagnostics({
    required this.configuredSamplingRate,
    required this.actualGenerationRate,
    required this.actualTransmissionRate,
    required this.framesGenerated,
    required this.framesSent,
    required this.framesFailed,
    required this.sendQueueDepth,
    required this.lastSequenceNumber,
    required this.errorCount,
    required this.droppedFramePercent,
  });

  factory TransmissionDiagnostics.empty() {
    return const TransmissionDiagnostics(
      configuredSamplingRate: 250,
      actualGenerationRate: 0.0,
      actualTransmissionRate: 0.0,
      framesGenerated: 0,
      framesSent: 0,
      framesFailed: 0,
      sendQueueDepth: 0,
      lastSequenceNumber: 0,
      errorCount: 0,
      droppedFramePercent: 0.0,
    );
  }
}