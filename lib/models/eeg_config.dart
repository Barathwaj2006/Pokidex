class BandConfig {
  final double amplitude;
  final double frequency;

  const BandConfig({required this.amplitude, required this.frequency});

  BandConfig copyWith({double? amplitude, double? frequency}) => BandConfig(
        amplitude: amplitude ?? this.amplitude,
        frequency: frequency ?? this.frequency,
      );

  Map<String, dynamic> toJson() => {
        'amplitude_uV': amplitude,
        'frequency_Hz': frequency,
      };
}

class ArtifactConfig {
  final bool eyeBlink;
  final bool emg;
  final bool lineNoise;
  final double lineNoiseFreq;

  const ArtifactConfig({
    this.eyeBlink = false,
    this.emg = false,
    this.lineNoise = false,
    this.lineNoiseFreq = 50.0,
  });

  ArtifactConfig copyWith({
    bool? eyeBlink,
    bool? emg,
    bool? lineNoise,
    double? lineNoiseFreq,
  }) =>
      ArtifactConfig(
        eyeBlink: eyeBlink ?? this.eyeBlink,
        emg: emg ?? this.emg,
        lineNoise: lineNoise ?? this.lineNoise,
        lineNoiseFreq: lineNoiseFreq ?? this.lineNoiseFreq,
      );

  Map<String, dynamic> toJson() => {
        'eye_blink': eyeBlink,
        'emg': emg,
        'line_noise': lineNoise,
        'line_noise_freq_Hz': lineNoiseFreq,
      };
}

class EegConfig {
  final BandConfig delta;
  final BandConfig theta;
  final BandConfig alpha;
  final BandConfig beta;
  final BandConfig gamma;
  final double noisePercent;
  final ArtifactConfig artifacts;
  final int channelCount;
  final int samplingRate;

  const EegConfig({
    this.delta = const BandConfig(amplitude: 15.0, frequency: 2.0),
    this.theta = const BandConfig(amplitude: 8.0, frequency: 6.0),
    this.alpha = const BandConfig(amplitude: 25.0, frequency: 10.0),
    this.beta = const BandConfig(amplitude: 5.0, frequency: 20.0),
    this.gamma = const BandConfig(amplitude: 2.0, frequency: 35.0),
    this.noisePercent = 5.0,
    this.artifacts = const ArtifactConfig(),
    this.channelCount = 4,
    this.samplingRate = 250,
  });

  EegConfig copyWith({
    BandConfig? delta,
    BandConfig? theta,
    BandConfig? alpha,
    BandConfig? beta,
    BandConfig? gamma,
    double? noisePercent,
    ArtifactConfig? artifacts,
    int? channelCount,
    int? samplingRate,
  }) =>
      EegConfig(
        delta: delta ?? this.delta,
        theta: theta ?? this.theta,
        alpha: alpha ?? this.alpha,
        beta: beta ?? this.beta,
        gamma: gamma ?? this.gamma,
        noisePercent: noisePercent ?? this.noisePercent,
        artifacts: artifacts ?? this.artifacts,
        channelCount: channelCount ?? this.channelCount,
        samplingRate: samplingRate ?? this.samplingRate,
      );

  Map<String, dynamic> toJson() => {
        'delta': delta.toJson(),
        'theta': theta.toJson(),
        'alpha': alpha.toJson(),
        'beta': beta.toJson(),
        'gamma': gamma.toJson(),
        'noise_percent': noisePercent,
        'artifacts': artifacts.toJson(),
        'channel_count': channelCount,
        'sampling_rate_Hz': samplingRate,
      };

  static List<String> defaultChannelNames(int count) {
    const names = ['Fp1', 'Fp2', 'O1', 'O2', 'C3', 'C4', 'P3', 'P4'];
    return names.take(count).toList();
  }
}