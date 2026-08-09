import '../models/signal_frame.dart';

abstract class SignalEngine {
  Stream<SignalFrame> get frames;
  void start();
  void stop();
  bool get isRunning;
  String get engineType;
  void dispose();
}