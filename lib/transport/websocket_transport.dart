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

  final _statusController = StreamController<TransportStatus>.broadcast();
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
        _infoController.add('[WebSocket] Pyromatix / NeuroSync Client Connected (Total: ${_clients.length})');

        channel.stream.listen(
          (msg) {
            // Keep-alive or inbound telemetry commands
          },
          onDone: () {
            _clients.remove(channel);
            _infoController.add('[WebSocket] Client Disconnected (${_clients.length} remaining)');
            if (_clients.isEmpty) {
              _setStatus(TransportStatus.waiting);
            }
          },
          onError: (e) {
            _clients.remove(channel);
            _infoController.add('[WebSocket] Client error: $e');
            if (_clients.isEmpty) {
              _setStatus(TransportStatus.waiting);
            }
          },
          cancelOnError: false,
        );
      });

      _server = await shelf_io.serve(
        shelf.logRequests().addHandler(handler),
        InternetAddress.anyIPv4,
        port,
        shared: true,
      );

      _setStatus(TransportStatus.waiting);

      final ips = await _getLocalIps();
      final wsUrls = ips.map((ip) => 'ws://$ip:$port').join(', ');
      _infoController.add('[WebSocket] Server active — $wsUrls');
    } catch (e) {
      _setStatus(TransportStatus.error);
      _infoController.add('[WebSocket] Server Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    for (final client in List.from(_clients)) {
      try {
        await client.sink.close();
      } catch (_) {}
    }
    _clients.clear();
    await _server?.close(force: true);
    _server = null;
    _setStatus(TransportStatus.stopped);
    _infoController.add('[WebSocket] Server stopped');
  }

  @override
  Future<void> send(SignalFrame frame) async {
    final jsonPayload = frame.toJsonString();

    for (final client in List.from(_clients)) {
      try {
        client.sink.add(jsonPayload);
      } catch (e) {
        _clients.remove(client);
        _infoController.add('[WebSocket] Send failed, client dropped');
        if (_clients.isEmpty) {
          _setStatus(TransportStatus.waiting);
        }
      }
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