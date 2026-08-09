import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../models/connection_state_step.dart';
import '../providers/signal_provider.dart';

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
        final signalProvider = context.read<SignalProvider>();
        await signalProvider.processScannedQr(rawValue);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final signalProvider = context.watch<SignalProvider>();
    final step = signalProvider.connectionStep;
    final payload = signalProvider.activeQrPayload;
    final diag = signalProvider.diagnostics;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PyroSync Connectivity'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Diagnostics',
            onPressed: () => _showDiagnosticsModal(context, signalProvider),
          ),
        ],
      ),
      body: _isScannerOpen
          ? _buildCameraScannerView()
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Top Master Status Header Card
                _buildStatusHeaderCard(context, signalProvider, step),
                const SizedBox(height: 20),

                // Main Action Card based on state
                if (step == ConnectionStateStep.idle)
                  _buildIdleCard(context)
                else if (step == ConnectionStateStep.qrValidated && payload != null)
                  _buildValidatedCard(context, signalProvider, payload)
                else if (step == ConnectionStateStep.connecting ||
                    step == ConnectionStateStep.handshaking)
                  _buildConnectingCard(context, step)
                else if (step.isConnected || step == ConnectionStateStep.ready || step == ConnectionStateStep.streaming)
                  _buildConnectedCard(context, signalProvider, step, payload)
                else if (step.isFailure)
                  _buildFailureCard(context, signalProvider, step),

                const SizedBox(height: 24),

                // Compact Real-Time Transmission Dashboard Panel
                _buildCompactDashboardPanel(context, signalProvider, diag),

                const SizedBox(height: 24),

                // Preserved Secondary Transports (BLE Peripheral & Wi-Fi Server)
                _buildSecondaryTransportsExpansion(context, signalProvider),
              ],
            ),
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
                'Scan the QR code displayed by PyroSync',
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

  Widget _buildStatusHeaderCard(BuildContext context, SignalProvider signalProvider, ConnectionStateStep step) {
    Color color = Colors.grey;
    if (step == ConnectionStateStep.streaming) color = Colors.tealAccent;
    else if (step.isConnected || step == ConnectionStateStep.ready) color = Colors.greenAccent;
    else if (step == ConnectionStateStep.connecting || step == ConnectionStateStep.handshaking) color = Colors.amberAccent;
    else if (step.isFailure) color = Colors.redAccent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CONNECTION STATUS', style: TextStyle(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(
                  step.displayLabel,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
          ),
          if (step != ConnectionStateStep.idle)
            TextButton(
              onPressed: () {
                signalProvider.disconnectPairing();
              },
              child: const Text('RESET', style: TextStyle(color: Colors.white70, fontSize: 11)),
            ),
        ],
      ),
    );
  }

  Widget _buildIdleCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.qr_code_scanner, size: 48, color: Colors.cyanAccent),
            const SizedBox(height: 12),
            const Text(
              'CONNECT TO PYROSYNC',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
            ),
            const SizedBox(height: 6),
            const Text(
              'Scan the QR code displayed by PyroSync to automatically validate session credentials and begin signal streaming.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.camera_alt),
                label: const Text('OPEN QR SCANNER', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: _openQrScanner,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidatedCard(BuildContext context, SignalProvider signalProvider, payload) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.tealAccent, size: 20),
                SizedBox(width: 8),
                Text('PyroSync Found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              ],
            ),
            const Divider(height: 20),
            Text('Session: ${payload.sessionId}', style: const TextStyle(fontFamily: 'monospace', color: Colors.cyanAccent)),
            const SizedBox(height: 4),
            Text('Host IP: ${payload.host}:${payload.port}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
            const SizedBox(height: 4),
            Text('Transport: ${payload.transport.toUpperCase()}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.link),
                label: const Text('CONNECT & START HANDSHAKE', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () async {
                  await signalProvider.connectToPairingPayload();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectingCard(BuildContext context, ConnectionStateStep step) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircularProgressIndicator(color: Colors.cyanAccent),
            const SizedBox(height: 16),
            Text(
              step == ConnectionStateStep.handshaking ? 'Executing Mutual Handshake...' : 'Connecting to PyroSync...',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
            ),
            const SizedBox(height: 6),
            const Text('Exchanging HELLO & READY control packets...', style: TextStyle(fontSize: 11, color: Colors.white54)),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectedCard(BuildContext context, SignalProvider signalProvider, ConnectionStateStep step, payload) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  step == ConnectionStateStep.streaming ? Icons.sensors : Icons.check_circle,
                  color: Colors.tealAccent,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  step == ConnectionStateStep.streaming ? '✓ SIGNAL STREAMING ACTIVE' : '✓ Connected to PyroSync',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.tealAccent),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (payload != null)
              Text('Session ID: ${payload.sessionId}', style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.white70)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: step == ConnectionStateStep.streaming ? Colors.redAccent : Colors.tealAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: Icon(step == ConnectionStateStep.streaming ? Icons.stop : Icons.play_arrow),
                label: Text(
                  step == ConnectionStateStep.streaming ? 'PAUSE / STOP STREAM' : 'START TRANSMISSION STREAM',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  if (step == ConnectionStateStep.streaming) {
                    await signalProvider.stopStreaming();
                  } else {
                    await signalProvider.startStreaming();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFailureCard(BuildContext context, SignalProvider signalProvider, ConnectionStateStep step) {
    final errorMsg = signalProvider.qrError ?? step.displayLabel;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 36),
            const SizedBox(height: 10),
            Text(step.displayLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.redAccent)),
            const SizedBox(height: 6),
            Text(errorMsg, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.white70)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _openQrScanner,
                    child: const Text('RE-SCAN QR'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent, foregroundColor: Colors.black),
                    onPressed: () => signalProvider.connectToPairingPayload(),
                    child: const Text('RETRY'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactDashboardPanel(BuildContext context, SignalProvider signalProvider, diag) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SIGNAL TRANSMISSION METRICS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MetricMiniTile(label: 'Engine', value: signalProvider.appState.activeEngine.name.toUpperCase()),
              _MetricMiniTile(label: 'Sampling', value: '${diag.configuredSamplingRate} Hz'),
              _MetricMiniTile(label: 'Channels', value: '${signalProvider.channelCount} CH'),
              _MetricMiniTile(label: 'Actual Rate', value: '${diag.actualTransmissionRate.toStringAsFixed(1)} Hz'),
            ],
          ),
          const Divider(height: 20, color: Colors.white10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MetricMiniTile(label: 'Sent Frames', value: '${diag.framesSent}'),
              _MetricMiniTile(label: 'Queue Depth', value: '${diag.sendQueueDepth}'),
              _MetricMiniTile(label: 'Failed / Drops', value: '${diag.framesFailed}'),
              _MetricMiniTile(label: 'Last Seq', value: '#${diag.lastSequenceNumber}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryTransportsExpansion(BuildContext context, SignalProvider signalProvider) {
    return ExpansionTile(
      title: const Text('Secondary Hardware Transports (BLE & Wi-Fi Server)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70)),
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• BLE Peripheral Characteristic: FE51 (Notify + Read)', style: TextStyle(fontSize: 11, color: Colors.white60)),
                const SizedBox(height: 4),
                Text('• Local Wi-Fi WebSocket Port: ${signalProvider.appState.wsPort}', style: const TextStyle(fontSize: 11, color: Colors.white60)),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: signalProvider.isServerRunning ? Colors.redAccent : Colors.tealAccent, foregroundColor: Colors.black),
                  onPressed: () async {
                    if (signalProvider.isServerRunning) {
                      await signalProvider.stopServer();
                    } else {
                      await signalProvider.startServer();
                    }
                  },
                  child: Text(signalProvider.isServerRunning ? 'STOP SERVER TRANSPORTS' : 'START SERVER TRANSPORTS'),
                ),
              ],
            ),
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
            const Text('ADVANCED TRANSMISSION DIAGNOSTICS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
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

class _MetricMiniTile extends StatelessWidget {
  final String label;
  final String value;
  const _MetricMiniTile({required this.label, required this.value});

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