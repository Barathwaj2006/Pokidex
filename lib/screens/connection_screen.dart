import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/app_state_provider.dart';
import '../providers/signal_provider.dart';
import '../widgets/status_chip.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  late TextEditingController _portController;
  late TextEditingController _bleNameController;
  List<String> _ips = [];

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppStateProvider>();
    _portController = TextEditingController(text: appState.wsPort.toString());
    _bleNameController = TextEditingController(text: appState.bleDeviceName);
    _loadIps();
  }

  Future<void> _loadIps() async {
    final signalProvider = context.read<SignalProvider>();
    final ips = await signalProvider.getLocalIps();
    if (mounted) {
      setState(() {
        _ips = ips;
      });
    }
  }

  @override
  void dispose() {
    _portController.dispose();
    _bleNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final signalProvider = context.watch<SignalProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connection Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Master Dual-Transport Server Control
          Card(
            color: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: signalProvider.isServerRunning
                    ? Colors.tealAccent
                    : Colors.grey.shade700,
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'DUAL TRANSPORT SERVER CONTROLLER',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      StatusChip(
                        status: signalProvider.transportStatus,
                        connectedClients: signalProvider.connectedClientCount,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (signalProvider.isServerRunning) {
                              await signalProvider.stopServer();
                            } else {
                              await signalProvider.startServer();
                              await _loadIps();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: signalProvider.isServerRunning
                                ? Colors.redAccent
                                : Colors.tealAccent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: Icon(signalProvider.isServerRunning
                              ? Icons.stop
                              : Icons.play_arrow),
                          label: Text(
                            signalProvider.isServerRunning
                                ? 'STOP ALL TRANSPORTS'
                                : 'START DUAL TRANSPORTS (Wi-Fi + BLE)',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 1. Wi-Fi WebSocket Server Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.wifi, color: Colors.cyanAccent, size: 20),
                          SizedBox(width: 8),
                          Text(
                            '1. WI-FI WEBSOCKET SERVER',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.cyanAccent,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: appState.isWifiEnabled,
                        onChanged: (v) {
                          appState.setWifiEnabled(v);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_ips.isEmpty)
                    Text(
                      'No Wi-Fi interface detected or server offline.',
                      style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                    )
                  else
                    ..._ips.map((ip) {
                      final url = 'ws://$ip:${appState.wsPort}';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.link, size: 16, color: Colors.cyanAccent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                url,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 16),
                              tooltip: 'Copy URL',
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: url));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Copied $url')),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _portController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'WebSocket Port',
                      border: OutlineInputBorder(),
                      helperText: 'Default: 8765',
                    ),
                    onChanged: (val) {
                      final p = int.tryParse(val);
                      if (p != null && p > 1024 && p < 65535) {
                        appState.setWsPort(p);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Bluetooth LE Peripheral Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.bluetooth, color: Colors.blueAccent, size: 20),
                          SizedBox(width: 8),
                          Text(
                            '2. BLE PERIPHERAL (GATT SERVER)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.blueAccent,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: appState.isBleEnabled,
                        onChanged: (v) {
                          appState.setBleEnabled(v);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      StatusChip(
                        status: signalProvider.bleStatus,
                        connectedClients: signalProvider.bleConnectedCount,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _bleNameController,
                    decoration: const InputDecoration(
                      labelText: 'Advertised Device Name',
                      border: OutlineInputBorder(),
                      helperText: 'Scanned by PyroSync BLE Central',
                    ),
                    onChanged: (val) {
                      if (val.isNotEmpty) {
                        appState.setBleDeviceName(val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // UUID Badges
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'SERVICE UUID: 0000fe50-0000-1000-8000-00805f9b34fb',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            color: Colors.lightBlueAccent,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'CHARACTERISTIC UUID: 0000fe51-0000-1000-8000-00805f9b34fb (NOTIFY)',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            color: Colors.lightBlueAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Packet Batch Configuration
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Batch Size (samples/packet):'),
                  DropdownButton<int>(
                    value: appState.batchSize,
                    items: [1, 5, 10, 20, 50].map((b) {
                      return DropdownMenuItem(
                        value: b,
                        child: Text('$b samples'),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) appState.setBatchSize(v);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Dual Transport Event Console Log
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'DUAL TRANSPORT LOG CONSOLE',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      Text(
                        '${signalProvider.infoMessages.length} events',
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 160,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: ListView.builder(
                      itemCount: signalProvider.infoMessages.length,
                      itemBuilder: (ctx, idx) {
                        final msg = signalProvider.infoMessages[idx];
                        Color color = Colors.greenAccent;
                        if (msg.contains('[BLE]')) color = Colors.lightBlueAccent;
                        if (msg.contains('[DUAL LOG]')) color = Colors.amberAccent;
                        if (msg.contains('[ERROR]')) color = Colors.redAccent;
                        return Text(
                          msg,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            color: color,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}