import 'dart:async';
import 'dart:io';

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/signal_frame.dart';
import 'signal_transport.dart';

class WebSocketTransport implements SignalTransport {
  final int port;

  final _statusController =
      StreamController<TransportStatus>.broadcast();
  final _infoController = StreamController<String>.broadcast();

  final List<WebSocketChannel> _clients = [];
  HttpServer? _server;
  TransportStatus _status = TransportStatus.stopped;

  WebSocketTransport({this.port = 8765});

  @override
  TransportStatus get status => _status;

  @override
  int get connectedClientCount => _clients.length;

  @override
  Stream<TransportStatus> get statusStream => _statusController.stream;

  @override
  Stream<String> get infoStream => _infoController.stream;

  @override
  Future<void> start() async {
    if (_status != TransportStatus.stopped) return;

    _setStatus(TransportStatus.starting);

    try {
      final handler = webSocketHandler((WebSocketChannel channel) {
        _clients.add(channel);
        _setStatus(TransportStatus.connected);
        _infoController.add('Client connected (${_clients.length} total)');

        channel.stream.listen(
          null,
          onDone: () {
            _clients.remove(channel);
            _infoController
                .add('Client disconnected (${_clients.length} remaining)');
            if (_clients.isEmpty) {
              _setStatus(TransportStatus.waiting);
            }
          },
          onError: (e) {
            _clients.remove(channel);
            _infoController.add('Client error: $e');
            if (_clients.isEmpty) {
              _setStatus(TransportStatus.waiting);
            }
          },
          cancelOnError: true,
        );
      });

      _server = await shelf_io.serve(
        shelf.logRequests(logger: (msg, isError) {
          if (isError) _infoController.add('[ERROR] $msg');
        }).addHandler(handler),
        InternetAddress.anyIPv4,
        port,
      );

      _setStatus(TransportStatus.waiting);

      final ips = await _getLocalIps();
      final wsUrls = ips.map((ip) => 'ws://$ip:$port').join(', ');
      _infoController.add('Server started — $wsUrls');
    } catch (e) {
      _setStatus(TransportStatus.error);
      _infoController.add('Failed to start server: $e');
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    for (final client in List.from(_clients)) {
      await client.sink.close();
    }
    _clients.clear();
    await _server?.close(force: true);
    _server = null;
    _setStatus(TransportStatus.stopped);
    _infoController.add('Server stopped');
  }

  @override
  Future<void> send(SignalFrame frame) async {
    if (_clients.isEmpty) return;
    final json = frame.toJsonString();
    for (final client in List.from(_clients)) {
      try {
        client.sink.add(json);
      } catch (_) {}
    }
  }

  Future<List<String>> getLocalIps() => _getLocalIps();

  Future<List<String>> _getLocalIps() async {
    final List<String> ips = [];
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) {
            ips.add(addr.address);
          }
        }
      }
    } catch (_) {}
    return ips;
  }

  void _setStatus(TransportStatus s) {
    _status = s;
    _statusController.add(s);
  }

  void dispose() {
    stop();
    _statusController.close();
    _infoController.close();
  }
}