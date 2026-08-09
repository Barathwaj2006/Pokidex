import 'package:uuid/uuid.dart';

class SessionService {
  final _uuid = const Uuid();
  late String _sessionId;
  int _sequence = 0;
  DateTime? _startTime;

  SessionService() {
    _sessionId = _uuid.v4();
  }

  String get sessionId => _sessionId;

  int get nextSequence => _sequence++;

  void resetSession() {
    _sessionId = _uuid.v4();
    _sequence = 0;
    _startTime = null;
  }

  void markStart() {
    _startTime = DateTime.now();
  }

  Duration? get elapsed {
    if (_startTime == null) return null;
    return DateTime.now().difference(_startTime!);
  }
}