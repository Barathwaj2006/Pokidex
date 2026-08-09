import 'dart:async';
import 'dart:math' as math;

import '../models/eeg_config.dart';
import '../models/erp_config.dart';
import '../models/ground_truth_entry.dart';
import '../models/signal_frame.dart';
import '../services/ground_truth_service.dart';
import 'signal_engine.dart';

class ErpEngine implements SignalEngine {
  final EegConfig eegConfig;
  final ErpConfig erpConfig;
  final GroundTruthService groundTruthService;
  final String sessionId;

  final _controller = StreamController<SignalFrame>.broadcast();
  final _random = math.Random();

  bool _running = false;
  int _sampleIndex = 0;
  int _trialIndex = 0;

  bool _trialActive = false;
  double _trialOnsetSample = 0.0;

  double _trialN75Latency = 0.075;
  double _trialN75Amplitude = 0.0;
  double _trialP100Latency = 0.100;
  double _trialP100Amplitude = 0.0;
  double _trialN145Latency = 0.145;
  double _trialN145Amplitude = 0.0;

  final List<SignalFrameEvent> _pendingEvents = [];

  Timer? _isiTimer;
  Timer? _sampleTimer;

  ErpEngine({
    required this.eegConfig,
    required this.erpConfig,
    required this.groundTruthService,
    required this.sessionId,
  });

  @override
  Stream<SignalFrame> get frames => _controller.stream;

  @override
  bool get isRunning => _running;

  @override
  String get engineType => 'erp';

  void fireTrigger() {
    if (!_running) return;
    _activateTrial();
  }

  void _activateTrial() {
    _trialActive = true;
    _trialOnsetSample = _sampleIndex.toDouble();
    _trialIndex++;

    final jitterFactor = erpConfig.jitterPercent / 100.0;
    final j75 = _gaussianJitter(jitterFactor);
    final j100 = _gaussianJitter(jitterFactor);
    final j145 = _gaussianJitter(jitterFactor);

    _trialN75Latency = (erpConfig.n75.latencyMs / 1000.0) * (1.0 + j75);
    _trialN75Amplitude = erpConfig.n75.amplitudeUv;
    _trialP100Latency = (erpConfig.p100.latencyMs / 1000.0) * (1.0 + j100);
    _trialP100Amplitude = erpConfig.p100.amplitudeUv;
    _trialN145Latency = (erpConfig.n145.latencyMs / 1000.0) * (1.0 + j145);
    _trialN145Amplitude = erpConfig.n145.amplitudeUv;

    groundTruthService.add(GroundTruthEntry(
      id: '_erp_trial',
      timestamp: DateTime.now(),
      engineType: EngineType.erp,
      parameters: {
        'trial_index': _trialIndex,
        'onset_sample': _trialOnsetSample,
        'n75_latency_ms': _trialN75Latency * 1000.0,
        'n75_amplitude_uV': _trialN75Amplitude,
        'p100_latency_ms': _trialP100Latency * 1000.0,
        'p100_amplitude_uV': _trialP100Amplitude,
        'n145_latency_ms': _trialN145Latency * 1000.0,
        'n145_amplitude_uV': _trialN145Amplitude,
        'jitter_percent': erpConfig.jitterPercent,
        ...erpConfig.toJson(),
      },
      notes: 'VEP trial  triggered at '
          't=s. '
          'P100 latency=ms, '
          'amplitude=uV',
    ));

    _pendingEvents.add(SignalFrameEvent(
      timestamp: DateTime.now().millisecondsSinceEpoch / 1000.0,
      eventType: 'trigger',
      value: 'vep_onset',
    ));
  }

  double _gaussianJitter(double stddev) {
    final u1 = _random.nextDouble();
    final u2 = _random.nextDouble();
    return stddev *
        math.sqrt(-2.0 * math.log(u1 == 0 ? 1e-10 : u1)) *
        math.cos(2 * math.pi * u2);
  }

  double _erpResponse(double tFromOnset) {
    if (tFromOnset < 0) return 0.0;

    double response = 0.0;
    response += _gaussian(
      t: tFromOnset,
      latency: _trialN75Latency,
      amplitude: _trialN75Amplitude,
      sigma: erpConfig.n75.sigmaMs / 1000.0,
    );
    response += _gaussian(
      t: tFromOnset,
      latency: _trialP100Latency,
      amplitude: _trialP100Amplitude,
      sigma: erpConfig.p100.sigmaMs / 1000.0,
    );
    response += _gaussian(
      t: tFromOnset,
      latency: _trialN145Latency,
      amplitude: _trialN145Amplitude,
      sigma: erpConfig.n145.sigmaMs / 1000.0,
    );
    return response;
  }

  double _gaussian({
    required double t,
    required double latency,
    required double amplitude,
    required double sigma,
  }) {
    final dt = t - latency;
    return amplitude * math.exp(-(dt * dt) / (2.0 * sigma * sigma));
  }

  @override
  void start() {
    if (_running) return;
    _running = true;
    _sampleIndex = 0;
    _trialIndex = 0;

    final intervalUs = (1000000 / eegConfig.samplingRate).round();
    _sampleTimer = Timer.periodic(
      Duration(microseconds: intervalUs),
      _onTick,
    );

    if (erpConfig.triggerMode != TriggerMode.manual) {
      _scheduleNextIsiTrigger();
    }
  }

  void _scheduleNextIsiTrigger() {
    double isiMs;
    if (erpConfig.triggerMode == TriggerMode.fixedISI) {
      isiMs = erpConfig.fixedIsiMs;
    } else {
      isiMs = erpConfig.minIsiMs +
          _random.nextDouble() * (erpConfig.maxIsiMs - erpConfig.minIsiMs);
    }
    _isiTimer?.cancel();
    _isiTimer = Timer(Duration(milliseconds: isiMs.round()), () {
      if (_running) {
        _activateTrial();
        _scheduleNextIsiTrigger();
      }
    });
  }

  void _onTick(Timer timer) {
    final t = _sampleIndex / eegConfig.samplingRate;
    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;

    final bgSamples = _generateBgSamples(t);

    List<double> finalSamples;
    if (_trialActive) {
      final tFromOnset =
          (_sampleIndex - _trialOnsetSample) / eegConfig.samplingRate;
      final response = _erpResponse(tFromOnset);
      finalSamples = bgSamples.map((s) => s + response).toList();
      final trialEndTime = _trialN145Latency + 3.0 * (erpConfig.n145.sigmaMs / 1000.0);
      if (tFromOnset > trialEndTime) {
        _trialActive = false;
      }
    } else {
      finalSamples = bgSamples;
    }

    final events = List<SignalFrameEvent>.from(_pendingEvents);
    _pendingEvents.clear();

    _controller.add(SignalFrame(
      data: SignalFrameData(
        timestamp: now,
        sequence: _sampleIndex,
        channelSamples: finalSamples,
      ),
      events: events,
    ));

    _sampleIndex++;
  }

  List<double> _generateBgSamples(double t) {
    final bands = [
      eegConfig.delta.copyWith(amplitude: eegConfig.delta.amplitude * 0.5),
      eegConfig.theta.copyWith(amplitude: eegConfig.theta.amplitude * 0.5),
      eegConfig.alpha.copyWith(amplitude: eegConfig.alpha.amplitude * 0.5),
      eegConfig.beta.copyWith(amplitude: eegConfig.beta.amplitude * 0.5),
      eegConfig.gamma.copyWith(amplitude: eegConfig.gamma.amplitude * 0.5),
    ];
    return List.generate(eegConfig.channelCount, (ch) {
      double s = 0.0;
      for (final band in bands) {
        s += band.amplitude *
            math.sin(2 * math.pi * band.frequency * t + ch * 0.3);
      }
      s += (_random.nextDouble() * 2 - 1) *
          (_totalAmplitude(bands) * eegConfig.noisePercent / 100.0) *
          0.3;
      return s;
    });
  }

  double _totalAmplitude(List<BandConfig> bands) =>
      bands.fold(0.0, (a, b) => a + b.amplitude);

  @override
  void stop() {
    _sampleTimer?.cancel();
    _isiTimer?.cancel();
    _sampleTimer = null;
    _isiTimer = null;
    _running = false;
  }

  @override
  void dispose() {
    stop();
    _controller.close();
  }
}