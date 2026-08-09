import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/app_state_provider.dart';
import '../providers/signal_provider.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  late TextEditingController _portController;
  late TextEditingController _bleNameController;
  List<String> _ips = [];
  bool _isScanningBle = false;
  List<Map<String, String>> _discoveredBleDevices = [];

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

  void _scanNearbyBleDevices() {
    setState(() {
      _isScanningBle = true;
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _isScanningBle = false;
          _discoveredBleDevices = [
            {'name': 'Pyromatix BCI Core Node', 'rssi': '-42 dBm', 'uuid': '0000fe50-pyro-1000-8000-00805f9b34fb'},
            {'name': 'NeuroSync Headset Gen-2', 'rssi': '-58 dBm', 'uuid': '0000fe50-neuro-1000-8000-00805f9b34fb'},
            {'name': 'Pokidex EEG Broadcast', 'rssi': '-12 dBm', 'uuid': '0000fe50-0000-1000-8000-00805f9b34fb'},
            {'name': 'Generic BLE EEG Receiver', 'rssi': '-75 dBm', 'uuid': '0000180d-0000-1000-8000-00805f9b34fb'},
          ];
        });
      }
    });
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
        title: const Text('Device Connection & Transports'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade900, Colors.blue.shade900],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.hub, color: Colors.cyanAccent, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'HARDWARE & INTERFACE TRANSPORTS',
                        style: TextStyle(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Stream live multi-channel signal telemetry via local Wi-Fi Sockets or Bluetooth Low Energy.',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Master Dual-Transport Server Control
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'MASTER TRANSPORT CONTROLLER',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: signalProvider.isServerRunning ? Colors.tealAccent.withValues(alpha: 0.2) : Colors.redAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          signalProvider.isServerRunning ? 'SERVER ACTIVE' : 'SERVER IDLE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: signalProvider.isServerRunning ? Colors.tealAccent : Colors.redAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
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
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: Icon(signalProvider.isServerRunning
                          ? Icons.stop
                          : Icons.play_arrow),
                      label: Text(
                        signalProvider.isServerRunning
                            ? 'STOP ALL TRANSPORTS'
                            : 'START TRANSPORTS (Wi-Fi + BLE)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Compact Nearby BLE Scanner Card (Fixed Screen Overflow)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.bluetooth_searching, color: Colors.amberAccent, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'NEARBY BLE & BCI SCANNER',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.amberAccent,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        icon: _isScanningBle
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.refresh, color: Colors.amberAccent, size: 20),
                        onPressed: _isScanningBle ? null : _scanNearbyBleDevices,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Scan for Pyromatix nodes, NeuroSync headsets, or nearby BLE receivers:',
                    style: TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  if (_discoveredBleDevices.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          _isScanningBle
                              ? 'Scanning nearby Bluetooth channels...'
                              : 'Tap refresh icon to scan for Pyromatix nodes & NeuroSync headsets.',
                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 180),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _discoveredBleDevices.length,
                        itemBuilder: (ctx, idx) {
                          final dev = _discoveredBleDevices[idx];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.bluetooth, color: Colors.blueAccent, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        dev['name']!,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        'UUID: ${dev['uuid']}',
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 8,
                                          color: Colors.white54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  dev['rssi']!,
                                  style: const TextStyle(fontSize: 10, color: Colors.greenAccent),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.tealAccent,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text('PAIR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Paired with ${dev['name']}! Ready for telemetry streaming.')),
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 1. Wi-Fi WebSocket Broadcast Socket
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.wifi, color: Colors.cyanAccent, size: 18),
                          SizedBox(width: 8),
                          Text(
                            '1. WI-FI WEBSOCKET BROADCAST',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
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
                  const SizedBox(height: 4),
                  const Text(
                    'Spins up a local WebSocket server to stream real-time JSON signal frames over TCP.',
                    style: TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  if (_ips.isEmpty)
                    Text(
                      'No Wi-Fi interface detected or server offline.',
                      style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 11),
                    )
                  else
                    ..._ips.map((ip) {
                      final url = 'ws://$ip:${appState.wsPort}';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.link, size: 14, color: Colors.cyanAccent),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                url,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.copy, size: 14),
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
                      isDense: true,
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

          // 2. Bluetooth LE Peripheral Broadcast
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.bluetooth, color: Colors.blueAccent, size: 18),
                          SizedBox(width: 8),
                          Text(
                            '2. BLE PERIPHERAL BROADCAST',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
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
                  const SizedBox(height: 4),
                  const Text(
                    'Simulates an EEG headset, broadcasting bio-potential packets to nearby Bluetooth scanners.',
                    style: TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _bleNameController,
                    decoration: const InputDecoration(
                      labelText: 'Advertised Device Name',
                      border: OutlineInputBorder(),
                      isDense: true,
                      helperText: 'Scanned by BLE receivers',
                    ),
                    onChanged: (val) {
                      if (val.isNotEmpty) {
                        appState.setBleDeviceName(val);
                      }
                    },
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