import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';

class TermsConditionsScreen extends StatelessWidget {
  final bool showAcceptButton;

  const TermsConditionsScreen({
    super.key,
    this.showAcceptButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Safety Protocols'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Header badge
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.verified_user_outlined,
                            color: AppColors.primaryAccent,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CLINICAL RESEARCH COMPLIANCE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: AppColors.secondaryBlue,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Institutional Review Board (IRB) & Signal Governance Protocols',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  _buildSection(
                    icon: Icons.biotech_outlined,
                    title: '1. Non-Diagnostic Research Device Disclaimer',
                    content:
                        'Pokidex is an investigative biopotential neural signal generator and wireless telemetry platform engineered strictly for scientific experimentation, cognitive load simulation, and algorithmic benchmarking. It is not intended for primary clinical diagnostics, therapeutic intervention, or patient life-support applications. Signal traces represent mathematical models and synthetic simulations for BCI interface validation.',
                  ),

                  _buildSection(
                    icon: Icons.lock_outline,
                    title: '2. Data Governance & Zero-PII Transmission',
                    content:
                        'All continuous 4-channel neural waveforms (EEG/ERP) transmitted via Bluetooth Low Energy (BLE) or Wi-Fi WebSockets are strictly pseudonymized and stripped of Personally Identifiable Information (PII). In accordance with GDPR and HIPAA data handling guidelines, no patient names, biological identifiers, or institutional network credentials are leaked into the RF broadcast.',
                  ),

                  _buildSection(
                    icon: Icons.sensors,
                    title: '3. Telemetry Integrity & Hardware Safety',
                    content:
                        'Continuous streaming operates at 250 Hz (4 ms packet intervals). When running in high-frequency mode, the application utilizes an Android foreground service with dedicated wake-locks to avoid Doze-mode stream truncation. Operators must ensure receiving hardware (e.g. NeuroSim terminals) enforces flow control and CRC verification to maintain zero-drop analytical fidelity.',
                  ),

                  _buildSection(
                    icon: Icons.sync_alt,
                    title: '4. Remote Two-Way Command Governance',
                    content:
                        'The platform supports two-way remote command execution, allowing external terminals to alter patient parameters and trigger ERP stimulus sequences. Remote commands must originate from authorized research networks. Unauthorized or unauthenticated socket injections are systematically rejected.',
                  ),

                  _buildSection(
                    icon: Icons.gavel_outlined,
                    title: '5. Institutional Consent & User Liability',
                    content:
                        'By authenticating and broadcasting neural waveforms through Pokidex, the investigator certifies that all experimental protocols comply with local institutional ethics committees, safety regulations, and signal transmission standards. Developers and affiliated institutions disclaim liability for improper hardware interfacing.',
                  ),

                  const SizedBox(height: 12),
                  if (appState.termsAccepted)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.button),
                        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Terms accepted on ${appState.termsAcceptedAt?.toLocal().toString().split('.')[0] ?? 'Active Session'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            if (showAcceptButton)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.primarySurface,
                  border: Border(
                    top: BorderSide(color: AppColors.cardBorder, width: 1),
                  ),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    appState.acceptTerms();
                    Navigator.of(context).pop(true);
                  },
                  child: const Text(
                    'I ACCEPT & ACKNOWLEDGE PROTOCOLS',
                    style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static Widget _buildSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.secondaryBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}
