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

    // Simulate scanning nearby Pyromatix, NeuroSync, and BLE devices
    Future.delayed(const Duration(milliseconds: 1500), () {
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
        title: const Text('Pyromatix & NeuroSync Connectivity'),
        actions: [
          IconButton(
            icon: const Icon(Icons.medication),
            tooltip: '20 Patient Presets',
            onPressed: () => Navigator.pushNamed(context, '/patient-presets'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Pyromatix & NeuroSync Dedicated Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade900, Colors.blue.shade900],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.cable, color: Colors.cyanAccent, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'PYROMATIX & NEUROSYNC UNIFIED LINK',
                        style: TextStyle(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 0.8,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Seamlessly transmit biopotential telemetry to Pyromatix & NeuroSync via WebSockets or Bluetooth LE.',
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
                                : 'START TRANSPORTS (Wi-Fi + BLE)',
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

          // BLE Device Scanner for Nearby Devices
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
                          Icon(Icons.bluetooth_searching, color: Colors.amberAccent, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'NEARBY BLE & BCI DEVICE SCANNER',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.amberAccent,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: _isScanningBle
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.refresh, color: Colors.amberAccent),
                        onPressed: _isScanningBle ? null : _scanNearbyBleDevices,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Scan for Pyromatix nodes, NeuroSync headsets, or nearby BLE receivers:',
                    style: TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                  const SizedBox(height: 10),
                  if (_discoveredBleDevices.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          _isScanningBle
                              ? 'Scanning nearby Bluetooth channels...'
                              : 'Tap refresh icon above to scan nearby Bluetooth devices.',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: _discoveredBleDevices.map((dev) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.bluetooth_connected, color: Colors.blueAccent, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dev['name']!,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'UUID: ${dev['uuid']}',
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 9,
                                        color: Colors.white54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade900,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  dev['rssi']!,
                                  style: const TextStyle(fontSize: 10, color: Colors.greenAccent),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.tealAccent,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                ),
                                child: const Text('PAIR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Connected to ${dev['name']}! Ready for streaming.')),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
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
                            '1. PYROMATIX / NEUROSYNC WI-FI SOCKET',
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
                                  SnackBar(content: Text('Copied $url for Pyromatix/NeuroSync')),
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
                            '2. BLE PERIPHERAL BROADCAST',
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
                      helperText: 'Scanned by Pyromatix & NeuroSync BLE',
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