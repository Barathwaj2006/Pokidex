import '../models/signal_frame.dart';

enum TransportStatus {
  stopped,
  starting,
  waiting,
  connected,
  error,
}

abstract class SignalTransport {
  Future<void> start();
  Future<void> stop();
  Future<void> send(SignalFrame frame);
  Stream<TransportStatus> get statusStream;
  Stream<String> get infoStream;
  int get connectedClientCount;
  TransportStatus get status;
}