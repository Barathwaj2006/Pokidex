import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../models/connection_state_step.dart';
import '../providers/app_state_provider.dart';
import '../providers/signal_provider.dart';
import '../theme/app_theme.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  MobileScannerController? _scannerController;
  bool _isScannerOpen = false;

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  void _openQrScanner() {
    setState(() {
      _isScannerOpen = true;
      _scannerController = MobileScannerController();
    });
  }

  void _closeQrScanner() {
    if (!mounted) {
      _scannerController?.dispose();
      _scannerController = null;
      return;
    }
    setState(() {
      _isScannerOpen = false;
      _scannerController?.dispose();
      _scannerController = null;
    });
  }

  void _onDetect(BarcodeCapture capture) async {
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.isNotEmpty) {
        _closeQrScanner();
        if (!mounted) return;
        final signalProvider = context.read<SignalProvider>();
        await signalProvider.processScannedQr(rawValue);
        break;
      }
    }
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        backgroundColor: Colors.tealAccent.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showWebBluetoothCodeModal(BuildContext context) {
    const jsCode = '''
// Web Bluetooth Connection Snippet for NeuroSim / Web Interfaces
async function connectPokidexBLE() {
  try {
    console.log("Requesting Bluetooth Device...");
    const device = await navigator.bluetooth.requestDevice({
      filters: [{ services: ['0000fe50-0000-1000-8000-00805f9b34fb'] }],
      optionalServices: ['0000fe50-0000-1000-8000-00805f9b34fb']
    });

    const server = await device.gatt.connect();
    const service = await server.getPrimaryService('0000fe50-0000-1000-8000-00805f9b34fb');
    const characteristic = await service.getCharacteristic('0000fe51-0000-1000-8000-00805f9b34fb');

    await characteristic.startNotifications();
    console.log("Subscribed to Pokidex EEG notifications!");

    // Buffer for reassembling chunked packets
    let chunkBuffer = new Map();

    characteristic.addEventListener('characteristicvaluechanged', (event) => {
      const dataView = event.target.value;
      const seq = (dataView.getUint8(0) << 8) | dataView.getUint8(1);
      const chunkIdx = dataView.getUint8(2);
      const totalChunks = dataView.getUint8(3);

      const chunkBytes = new Uint8Array(dataView.buffer, 4);

      if (!chunkBuffer.has(seq)) {
        chunkBuffer.set(seq, new Array(totalChunks));
      }
      const chunks = chunkBuffer.get(seq);
      chunks[chunkIdx] = chunkBytes;

      // Check if all chunks received
      if (chunks.filter(Boolean).length === totalChunks) {
        let totalLen = chunks.reduce((acc, c) => acc + c.length, 0);
        let merged = new Uint8Array(totalLen);
        let offset = 0;
        for (const c of chunks) {
          merged.set(c, offset);
          offset += c.length;
        }
        chunkBuffer.delete(seq);

        const jsonStr = new TextDecoder().decode(merged);
        const frame = JSON.parse(jsonStr);
        console.log("Received Signal Frame:", frame);

        if (frame.data && frame.data.channel_samples) {
          // Render or pass to Cognitive Load Analyzer / Charts
          onNeuralSamplesReceived(frame.data.channel_samples, frame.data.timestamp);
        }
      }
    });
  } catch (err) {
    console.error("Bluetooth connection failed:", err);
  }
}''';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: controller,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'WEB BLUETOOTH INTEGRATION',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.cyanAccent),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Paste this JavaScript into your web interface (NeuroSim / Chrome / Edge) to connect and receive live waveforms via Web Bluetooth API.',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: const SelectableText(
                  jsCode,
                  style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.tealAccent),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent, foregroundColor: Colors.black),
                icon: const Icon(Icons.copy),
                label: const Text('COPY JAVASCRIPT CODE', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  _copyToClipboard(context, jsCode, 'Web Bluetooth code');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWebSocketCodeModal(BuildContext context, String wsUrl) {
    final jsCode = '''
// WebSocket Connection Snippet for NeuroSim / Web Interfaces
const socket = new WebSocket("$wsUrl");

socket.onopen = () => {
  console.log("Connected to Pokidex Telemetry WebSocket ($wsUrl)");
};

socket.onmessage = (event) => {
  try {
    const frame = JSON.parse(event.data);
    if (frame.data && frame.data.channel_samples) {
      // frame.data.channel_samples: [ch1, ch2, ch3, ch4] in uV
      // frame.data.timestamp: timestamp in seconds
      // frame.data.sequence: sequence counter
      onNeuralSamplesReceived(frame.data.channel_samples, frame.data.timestamp);
    }
  } catch (e) {
    console.error("Frame parse error:", e);
  }
};

socket.onerror = (err) => console.error("WebSocket error:", err);
socket.onclose = () => console.log("Disconnected from Pokidex.");
''';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'WEBSOCKET INTEGRATION',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.cyanAccent),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Connect any browser or backend to Pokidex via standard WebSockets on your local network:',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: SelectableText(
                jsCode,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.tealAccent),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent, foregroundColor: Colors.black),
                icon: const Icon(Icons.copy),
                label: const Text('COPY WEBSOCKET CODE', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  _copyToClipboard(context, jsCode, 'WebSocket code');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final signalProvider = context.watch<SignalProvider>();
    final isStreaming = signalProvider.isStreamingSignal;
    final isBroadcasting = signalProvider.isServerRunning;
    final diag = signalProvider.diagnostics;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wireless Telemetry & Web Broadcast'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Transmission Diagnostics',
            onPressed: () => _showDiagnosticsModal(context, signalProvider),
          ),
        ],
      ),
      body: _isScannerOpen
          ? _buildCameraScannerView()
          : ListView(
              padding: const EdgeInsets.all(18),
              children: [
                // 1. Top Transport Mode Selector
                _buildTransportModeSelector(context, appState, signalProvider),
                const SizedBox(height: 16),

                // 2. Master Broadcast Controller Card
                _buildMasterBroadcastCard(context, signalProvider, appState, isBroadcasting, isStreaming, diag),
                const SizedBox(height: 16),

                // 3. Bluetooth (BLE Peripheral) Telemetry Card
                _buildBluetoothCard(context, appState, signalProvider),
                const SizedBox(height: 16),

                // 4. Wi-Fi (WebSocket Server) Telemetry Card
                _buildWifiCard(context, appState, signalProvider),
                const SizedBox(height: 16),

                // 5. Live Simulation & 20 Patient Condition Alteration Card
                _buildLiveAlterationCard(context),
                const SizedBox(height: 16),

                // 6. Optional QR Camera Pairing for External Sessions
                _buildQrPairingSection(context, signalProvider),
              ],
            ),
    );
  }

  Widget _buildTransportModeSelector(
    BuildContext context,
    AppStateProvider appState,
    SignalProvider signalProvider,
  ) {
    final isWifi = appState.isWifiEnabled;
    final isBle = appState.isBleEnabled;

    int selectedIndex = 0;
    if (isBle && isWifi) {
      selectedIndex = 2; // Dual
    } else if (isBle) {
      selectedIndex = 0; // BLE only
    } else if (isWifi) {
      selectedIndex = 1; // Wi-Fi only
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          _buildModeTabItem(
            label: 'Bluetooth (BLE)',
            icon: Icons.bluetooth,
            isSelected: selectedIndex == 0,
            onTap: () async {
              await signalProvider.toggleBle(true);
              await signalProvider.toggleWifi(false);
            },
          ),
          _buildModeTabItem(
            label: 'Wi-Fi (Socket)',
            icon: Icons.wifi,
            isSelected: selectedIndex == 1,
            onTap: () async {
              await signalProvider.toggleBle(false);
              await signalProvider.toggleWifi(true);
            },
          ),
          _buildModeTabItem(
            label: 'Dual (Both)',
            icon: Icons.bolt,
            isSelected: selectedIndex == 2,
            onTap: () async {
              await signalProvider.toggleBle(true);
              await signalProvider.toggleWifi(true);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModeTabItem({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.tealAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.black : Colors.white70,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.black : Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMasterBroadcastCard(
    BuildContext context,
    SignalProvider signalProvider,
    AppStateProvider appState,
    bool isBroadcasting,
    bool isStreaming,
    dynamic diag,
  ) {
    Color statusColor = Colors.grey;
    String statusText = 'BROADCAST INACTIVE';
    if (isStreaming) {
      statusColor = Colors.tealAccent;
      statusText = 'BROADCASTING & STREAMING LIVE';
    } else if (isBroadcasting) {
      statusColor = Colors.amberAccent;
      statusText = 'BROADCAST ACTIVE (WAITING FOR SIGNAL)';
    }

    final totalClients = signalProvider.connectedClientCount;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: totalClients > 0 ? Colors.green.shade900 : Colors.black38,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$totalClients Client${totalClients == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: totalClients > 0 ? Colors.greenAccent : Colors.white60,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isStreaming ? Colors.redAccent : Colors.tealAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: Icon(isStreaming ? Icons.stop : Icons.sensors),
              label: Text(
                isStreaming ? 'STOP BROADCASTING' : 'START WIRELESS BROADCAST',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              onPressed: () async {
                if (isStreaming) {
                  await signalProvider.stopBroadcasting();
                } else {
                  final ok = await signalProvider.startBroadcasting();
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(signalProvider.lastError ?? 'Failed to start broadcast. Check Bluetooth and Wi-Fi.'),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
            ),
          ),
          const SizedBox(height: 14),

          // Transmission metrics row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MetricTile(label: 'Engine', value: appState.activeEngine.name.toUpperCase()),
              _MetricTile(label: 'Sampling', value: '${appState.eegConfig.samplingRate} Hz'),
              _MetricTile(label: 'Channels', value: '${signalProvider.channelCount} CH'),
              _MetricTile(label: 'Tx Rate', value: '${diag.actualTransmissionRate.toStringAsFixed(1)} Hz'),
              _MetricTile(label: 'Frames Sent', value: '${diag.framesSent}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBluetoothCard(
    BuildContext context,
    AppStateProvider appState,
    SignalProvider signalProvider,
  ) {
    final isEnabled = appState.isBleEnabled;
    final bleConnected = signalProvider.bleConnectedCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isEnabled ? Colors.blueAccent.withValues(alpha: 0.5) : Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.bluetooth, color: Colors.blueAccent, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Bluetooth LE Peripheral',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              Switch(
                value: isEnabled,
                activeColor: Colors.blueAccent,
                onChanged: (val) async {
                  await signalProvider.toggleBle(val);
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Advertises GATT Service for web browsers (Chrome/Edge) using Web Bluetooth API.',
            style: TextStyle(fontSize: 11, color: Colors.white60),
          ),
          const Divider(height: 18, color: Colors.white10),

          // Specs rows
          _SpecRow(label: 'Device Name', value: appState.bleDeviceName),
          const SizedBox(height: 6),
          _SpecRow(
            label: 'GATT Service UUID',
            value: '0000fe50-0000-1000-8000-00805f9b34fb',
            isMonospace: true,
            onCopy: () => _copyToClipboard(context, '0000fe50-0000-1000-8000-00805f9b34fb', 'Service UUID'),
          ),
          const SizedBox(height: 6),
          _SpecRow(
            label: 'Characteristic UUID',
            value: '0000fe51-0000-1000-8000-00805f9b34fb (Notify)',
            isMonospace: true,
            onCopy: () => _copyToClipboard(context, '0000fe51-0000-1000-8000-00805f9b34fb', 'Characteristic UUID'),
          ),
          const SizedBox(height: 6),
          _SpecRow(label: 'Connected Web Clients', value: '$bleConnected client${bleConnected == 1 ? '' : 's'}'),
          const SizedBox(height: 10),

          // Bluetooth Stream Format Selector
          Row(
            children: [
              const Text('Format: ', style: TextStyle(fontSize: 11, color: Colors.white54)),
              Expanded(
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Binary (High-Speed)', style: TextStyle(fontSize: 10)),
                      selected: appState.bleFormat == BleStreamFormat.binary,
                      selectedColor: Colors.blueAccent,
                      backgroundColor: Colors.black26,
                      onSelected: (val) {
                        if (val) signalProvider.setBleFormat(BleStreamFormat.binary);
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('JSON', style: TextStyle(fontSize: 10)),
                      selected: appState.bleFormat == BleStreamFormat.json,
                      selectedColor: Colors.blueAccent,
                      backgroundColor: Colors.black26,
                      onSelected: (val) {
                        if (val) signalProvider.setBleFormat(BleStreamFormat.json);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (signalProvider.lastBleCommand != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade900.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.download, size: 14, color: Colors.cyanAccent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Last Remote Command: "${signalProvider.lastBleCommand}"',
                      style: const TextStyle(fontSize: 10, color: Colors.cyanAccent, fontFamily: 'monospace'),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.cyanAccent),
                  icon: const Icon(Icons.code, size: 16),
                  label: const Text('WEB JS CODE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () => _showWebBluetoothCodeModal(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWifiCard(
    BuildContext context,
    AppStateProvider appState,
    SignalProvider signalProvider,
  ) {
    final isEnabled = appState.isWifiEnabled;
    final wifiConnected = signalProvider.wifiConnectedCount;
    final ip = signalProvider.localWifiIp ?? '127.0.0.1';
    final wsUrl = 'ws://$ip:${appState.wsPort}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isEnabled ? Colors.tealAccent.withValues(alpha: 0.5) : Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.wifi, color: Colors.tealAccent, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Wi-Fi WebSocket Server',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              Switch(
                value: isEnabled,
                activeColor: Colors.tealAccent,
                onChanged: (val) async {
                  await signalProvider.toggleWifi(val);
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Streams real-time JSON SignalFrames over local TCP WebSocket.',
            style: TextStyle(fontSize: 11, color: Colors.white60),
          ),
          const Divider(height: 18, color: Colors.white10),

          // Specs rows
          _SpecRow(
            label: 'WebSocket Endpoint',
            value: wsUrl,
            isMonospace: true,
            onCopy: () => _copyToClipboard(context, wsUrl, 'WebSocket URL'),
          ),
          const SizedBox(height: 6),
          _SpecRow(label: 'Port', value: '${appState.wsPort} (TCP)'),
          const SizedBox(height: 6),
          _SpecRow(label: 'Connected WebSockets', value: '$wifiConnected active'),

          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.tealAccent),
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('COPY WS URL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () => _copyToClipboard(context, wsUrl, 'WebSocket URL'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent.shade700,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.code, size: 16),
                  label: const Text('JS SNIPPET', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () => _showWebSocketCodeModal(context, wsUrl),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveAlterationCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_fix_high, color: Colors.cyanAccent, size: 20),
              SizedBox(width: 8),
              Text(
                'LIVE CONDITION & PARAMETER ALTERATIONS',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'While connected to your website via Bluetooth or Wi-Fi, you can switch between any of the 20 patient variants or alter signal parameters. The stream will immediately update the output waveforms in real time.',
            style: TextStyle(fontSize: 11, color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                backgroundColor: const Color(0xFF1E293B),
                avatar: const Icon(Icons.psychology, size: 16, color: Colors.tealAccent),
                label: const Text('20 Patient Presets', style: TextStyle(fontSize: 11, color: Colors.white)),
                onPressed: () => Navigator.pushNamed(context, '/patient-presets'),
              ),
              ActionChip(
                backgroundColor: const Color(0xFF1E293B),
                avatar: const Icon(Icons.tune, size: 16, color: Colors.cyanAccent),
                label: const Text('EEG Parameters', style: TextStyle(fontSize: 11, color: Colors.white)),
                onPressed: () => Navigator.pushNamed(context, '/eeg-config'),
              ),
              ActionChip(
                backgroundColor: const Color(0xFF1E293B),
                avatar: const Icon(Icons.waves, size: 16, color: Colors.amberAccent),
                label: const Text('Simulations', style: TextStyle(fontSize: 11, color: Colors.white)),
                onPressed: () => Navigator.pushNamed(context, '/simulations'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQrPairingSection(BuildContext context, SignalProvider signalProvider) {
    return ExpansionTile(
      title: const Text(
        'External Session QR Scanner',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white60),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'If your external web interface displays a session QR code, scan it to automatically pair credentials.',
                style: TextStyle(fontSize: 11, color: Colors.white60),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('OPEN CAMERA QR SCANNER'),
                  onPressed: _openQrScanner,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCameraScannerView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.indigo.shade900,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Scan the QR code displayed by your web interface',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _closeQrScanner,
              ),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              MobileScanner(
                controller: _scannerController,
                onDetect: _onDetect,
              ),
              Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.cyanAccent, width: 3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDiagnosticsModal(BuildContext context, SignalProvider signalProvider) {
    final diag = signalProvider.diagnostics;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('TRANSMISSION DIAGNOSTICS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
            const Divider(),
            Text('Configured Rate: ${diag.configuredSamplingRate} Hz'),
            Text('Generation Rate: ${diag.actualGenerationRate.toStringAsFixed(1)} Hz'),
            Text('Transmission Rate: ${diag.actualTransmissionRate.toStringAsFixed(1)} Hz'),
            Text('Total Generated: ${diag.framesGenerated}'),
            Text('Total Sent: ${diag.framesSent}'),
            Text('Send Failures: ${diag.framesFailed}'),
            Text('Queue Depth: ${diag.sendQueueDepth} / ${SignalProvider.maxQueueDepth}'),
            Text('Dropped Percent: ${diag.droppedFramePercent.toStringAsFixed(2)}%'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('CLOSE')),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  const _MetricTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.white54)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }
}

class _SpecRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isMonospace;
  final VoidCallback? onCopy;

  const _SpecRow({
    required this.label,
    required this.value,
    this.isMonospace = false,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 11, color: Colors.white54),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontFamily: isMonospace ? 'monospace' : null,
              fontWeight: FontWeight.w600,
              color: isMonospace ? Colors.tealAccent : Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (onCopy != null)
          InkWell(
            onTap: onCopy,
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(Icons.copy, size: 14, color: Colors.cyanAccent),
            ),
          ),
      ],
    );
  }
}