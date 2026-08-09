import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../transport/signal_transport.dart';

class StatusChip extends StatelessWidget {
  final TransportStatus status;
  final int connectedClients;

  const StatusChip({
    super.key,
    required this.status,
    this.connectedClients = 0,
  });

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = _statusInfo();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  (Color, IconData, String) _statusInfo() {
    switch (status) {
      case TransportStatus.stopped:
        return (AppColors.mutedText, Icons.stop_circle_outlined, 'OFFLINE');
      case TransportStatus.starting:
        return (AppColors.warning, Icons.hourglass_empty, 'STARTING');
      case TransportStatus.waiting:
        return (AppColors.warning, Icons.wifi_tethering, 'WAITING FOR CLIENT');
      case TransportStatus.connected:
        return (
          AppColors.success,
          Icons.wifi,
          'CONNECTED ($connectedClients)'
        );
      case TransportStatus.error:
        return (AppColors.error, Icons.error_outline, 'ERROR');
    }
  }
}