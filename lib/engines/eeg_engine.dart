import 'dart:async';
import 'dart:math' as math;

import '../models/eeg_config.dart';
import '../models/ground_truth_entry.dart';
import '../models/signal_frame.dart';
import '../services/ground_truth_service.dart';
import 'signal_engine.dart';

class EegEngine implements SignalEngine {
  final EegConfig config;
  final GroundTruthService groundTruthService;
  final String sessionId;

  final _random = math.Random();
  final _controller = StreamController<SignalFrame>.broadcast();

  Timer? _timer;
  bool _running = false;

  late List<List<double>> _bandPhases;

  static const _pinkGenerators = 16;
  late List<List<double>> _pinkState;
  late List<int> _pinkCounter;

  int _sampleIndex = 0;

  bool _blinkActive = false;
  double _blinkProgress = 0.0;
  static const _blinkDurationSeconds = 0.35;
  double _nextBlinkTime = 0.0;

  bool _emgActive = false;
  double _emgProgress = 0.0;
  double _nextEmgTime = 0.0;
  static const _emgDurationSeconds = 0.12;

  EegEngine({
    required this.config,
    required this.groundTruthService,
    required this.sessionId,
  }) {
    _initState();
  }

  void _initState() {
    final ch = config.channelCount;
    _bandPhases = List.generate(
      ch,
      (_) => List.generate(5, (_) => _random.nextDouble() * 2 * math.pi),
    );
    _pinkState =
        List.generate(ch, (_) => List.filled(_pinkGenerators, 0.0));
    _pinkCounter = List.filled(ch, 0);
    _scheduleNextBlink();
    _scheduleNextEmg();
  }

  void _scheduleNextBlink() {
    _nextBlinkTime = (_sampleIndex / config.samplingRate) +
        3.0 +
        _random.nextDouble() * 5.0;
  }

  void _scheduleNextEmg() {
    _nextEmgTime = (_sampleIndex / config.samplingRate) +
        5.0 +
        _random.nextDouble() * 7.0;
  }

  @override
  Stream<SignalFrame> get frames => _controller.stream;

  @override
  bool get isRunning => _running;

  @override
  String get engineType => 'eeg';

  @override
  void start() {
    if (_running) return;
    _running = true;
    _sampleIndex = 0;
    _logGroundTruth();

    final intervalUs = (1000000 / config.samplingRate).round();
    _timer = Timer.periodic(
      Duration(microseconds: intervalUs),
      _onTick,
    );
  }

  void _onTick(Timer timer) {
    final t = _sampleIndex / config.samplingRate;
    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final samples = _generateSamples(t);

    _controller.add(SignalFrame(
      data: SignalFrameData(
        timestamp: now,
        sequence: _sampleIndex,
        channelSamples: samples,
      ),
    ));

    _sampleIndex++;
    if (_sampleIndex % config.samplingRate == 0) {
      _logGroundTruth();
    }
  }

  List<double> _generateSamples(double t) {
    return List.generate(config.channelCount, (ch) => _generateSample(t, ch));
  }

  double _generateSample(double t, int ch) {
    double sample = 0.0;

    final bands = [
      config.delta,
      config.theta,
      config.alpha,
      config.beta,
      config.gamma,
    ];
    for (int b = 0; b < bands.length; b++) {
      final band = bands[b];
      if (band.amplitude <= 0) continue;
      final ampVar = 1.0 + (_random.nextDouble() - 0.5) * 0.2;
      sample += band.amplitude *
          ampVar *
          math.sin(2 * math.pi * band.frequency * t + _bandPhases[ch][b]);
    }

    if (config.noisePercent > 0) {
      final totalAmplitude = _totalBandAmplitude();
      final noiseAmp = totalAmplitude * config.noisePercent / 100.0;
      sample += _pinkNoise(ch) * noiseAmp * 0.5;
      sample += (_random.nextDouble() * 2.0 - 1.0) * noiseAmp * 0.5;
    }

    if (config.artifacts.lineNoise) {
      sample += 2.0 *
          math.sin(2 * math.pi * config.artifacts.lineNoiseFreq * t);
    }

    if (config.artifacts.eyeBlink) {
      final currentTime = _sampleIndex / config.samplingRate;
      if (!_blinkActive && currentTime >= _nextBlinkTime) {
        _blinkActive = true;
        _blinkProgress = 0.0;
      }
      if (_blinkActive) {
        final blinkAmp = (ch < 2) ? 80.0 : 20.0;
        sample += blinkAmp * math.sin(math.pi * _blinkProgress);
        _blinkProgress += 1.0 / (config.samplingRate * _blinkDurationSeconds);
        if (_blinkProgress >= 1.0) {
          _blinkActive = false;
          _scheduleNextBlink();
        }
      }
    }

    if (config.artifacts.emg) {
      final currentTime = _sampleIndex / config.samplingRate;
      if (!_emgActive && currentTime >= _nextEmgTime) {
        _emgActive = true;
        _emgProgress = 0.0;
      }
      if (_emgActive) {
        sample += (_random.nextDouble() * 2.0 - 1.0) * 30.0;
        _emgProgress += 1.0 / (config.samplingRate * _emgDurationSeconds);
        if (_emgProgress >= 1.0) {
          _emgActive = false;
          _scheduleNextEmg();
        }
      }
    }

    return sample;
  }

  double _pinkNoise(int ch) {
    _pinkCounter[ch]++;
    int mask = 1;
    for (int i = 0; i < _pinkGenerators; i++) {
      if ((_pinkCounter[ch] & mask) != 0) {
        _pinkState[ch][i] = _random.nextDouble() * 2.0 - 1.0;
        break;
      }
      mask <<= 1;
    }
    return _pinkState[ch].fold(0.0, (a, b) => a + b) / _pinkGenerators;
  }

  double _totalBandAmplitude() {
    return config.delta.amplitude +
        config.theta.amplitude +
        config.alpha.amplitude +
        config.beta.amplitude +
        config.gamma.amplitude;
  }

  void _logGroundTruth() {
    groundTruthService.add(GroundTruthEntry(
      id: '_eeg_',
      timestamp: DateTime.now(),
      engineType: EngineType.eeg,
      parameters: {
        ...config.toJson(),
        'sample_index': _sampleIndex,
        'elapsed_seconds': _sampleIndex / config.samplingRate,
        'blink_active': _blinkActive,
        'emg_active': _emgActive,
      },
      notes: 'EEG snapshot at t=s',
    ));
  }

  @override
  void stop() {
    _timer?.cancel();
    _timer = null;
    _running = false;
  }

  @override
  void dispose() {
    stop();
    _controller.close();
  }
}