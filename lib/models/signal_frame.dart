import 'dart:convert';

enum SignalType { eeg, erp, vep }

extension SignalTypeExtension on SignalType {
  String get value {
    switch (this) {
      case SignalType.eeg:
        return 'eeg';
      case SignalType.erp:
        return 'erp';
      case SignalType.vep:
        return 'vep';
    }
  }
}

class SignalFrameMetadata {
  final String source;
  final SignalType signalType;
  final int channelCount;
  final List<String> channelNames;
  final int samplingRate;
  final String unit;
  final String sessionId;

  const SignalFrameMetadata({
    required this.source,
    required this.signalType,
    required this.channelCount,
    required this.channelNames,
    required this.samplingRate,
    required this.unit,
    required this.sessionId,
  });

  Map<String, dynamic> toJson() => {
        'source': source,
        'signal_type': signalType.value,
        'channel_count': channelCount,
        'channel_names': channelNames,
        'sampling_rate': samplingRate,
        'unit': unit,
        'session_id': sessionId,
      };
}

class SignalFrameData {
  final double timestamp;
  final int sequence;
  final List<double> channelSamples;

  const SignalFrameData({
    required this.timestamp,
    required this.sequence,
    required this.channelSamples,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp,
        'sequence': sequence,
        'channel_samples': channelSamples,
      };
}

class SignalFrameEvent {
  final double timestamp;
  final String eventType;
  final String value;

  const SignalFrameEvent({
    required this.timestamp,
    required this.eventType,
    required this.value,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp,
        'event_type': eventType,
        'value': value,
      };
}

class SignalFrame {
  final SignalFrameMetadata? metadata;
  final SignalFrameData? data;
  final List<SignalFrameEvent> events;

  const SignalFrame({
    this.metadata,
    this.data,
    this.events = const [],
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (metadata != null) map['metadata'] = metadata!.toJson();
    if (data != null) map['data'] = data!.toJson();
    if (events.isNotEmpty) map['events'] = events.map((e) => e.toJson()).toList();
    return map;
  }

  String toJsonString() => jsonEncode(toJson());
}