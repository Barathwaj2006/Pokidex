enum TriggerMode { manual, fixedISI, randomISI }

class ErpComponentConfig {
  final String name;
  final double latencyMs;
  final double amplitudeUv;
  final double sigmaMs;

  const ErpComponentConfig({
    required this.name,
    required this.latencyMs,
    required this.amplitudeUv,
    required this.sigmaMs,
  });

  ErpComponentConfig copyWith({
    String? name,
    double? latencyMs,
    double? amplitudeUv,
    double? sigmaMs,
  }) =>
      ErpComponentConfig(
        name: name ?? this.name,
        latencyMs: latencyMs ?? this.latencyMs,
        amplitudeUv: amplitudeUv ?? this.amplitudeUv,
        sigmaMs: sigmaMs ?? this.sigmaMs,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'latency_ms': latencyMs,
        'amplitude_uV': amplitudeUv,
        'sigma_ms': sigmaMs,
      };
}

class ErpConfig {
  final ErpComponentConfig n75;
  final ErpComponentConfig p100;
  final ErpComponentConfig n145;
  final double jitterPercent;
  final TriggerMode triggerMode;
  final double fixedIsiMs;
  final double minIsiMs;
  final double maxIsiMs;

  const ErpConfig({
    this.n75 = const ErpComponentConfig(
      name: 'N75',
      latencyMs: 75.0,
      amplitudeUv: -3.0,
      sigmaMs: 15.0,
    ),
    this.p100 = const ErpComponentConfig(
      name: 'P100',
      latencyMs: 100.0,
      amplitudeUv: 6.0,
      sigmaMs: 20.0,
    ),
    this.n145 = const ErpComponentConfig(
      name: 'N145',
      latencyMs: 145.0,
      amplitudeUv: -4.0,
      sigmaMs: 18.0,
    ),
    this.jitterPercent = 5.0,
    this.triggerMode = TriggerMode.fixedISI,
    this.fixedIsiMs = 1000.0,
    this.minIsiMs = 800.0,
    this.maxIsiMs = 1500.0,
  });

  ErpConfig copyWith({
    ErpComponentConfig? n75,
    ErpComponentConfig? p100,
    ErpComponentConfig? n145,
    double? jitterPercent,
    TriggerMode? triggerMode,
    double? fixedIsiMs,
    double? minIsiMs,
    double? maxIsiMs,
  }) =>
      ErpConfig(
        n75: n75 ?? this.n75,
        p100: p100 ?? this.p100,
        n145: n145 ?? this.n145,
        jitterPercent: jitterPercent ?? this.jitterPercent,
        triggerMode: triggerMode ?? this.triggerMode,
        fixedIsiMs: fixedIsiMs ?? this.fixedIsiMs,
        minIsiMs: minIsiMs ?? this.minIsiMs,
        maxIsiMs: maxIsiMs ?? this.maxIsiMs,
      );

  Map<String, dynamic> toJson() => {
        'n75': n75.toJson(),
        'p100': p100.toJson(),
        'n145': n145.toJson(),
        'jitter_percent': jitterPercent,
        'trigger_mode': triggerMode.name,
        'fixed_isi_ms': fixedIsiMs,
        'min_isi_ms': minIsiMs,
        'max_isi_ms': maxIsiMs,
      };
}