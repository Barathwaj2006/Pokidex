import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';
import 'terms_conditions_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'barathwaj@bci-lab.org');
  final _passwordController = TextEditingController(text: 'NeuroSim@2026');
  final _institutionController = TextEditingController(text: 'Cognitive Neuroscience Lab');

  String _selectedRole = 'Principal Investigator';
  bool _obscurePassword = true;
  bool _agreedToTerms = false;
  String? _errorMessage;

  final List<String> _roles = const [
    'Principal Investigator',
    'Clinical Neuroscientist',
    'BCI Systems Engineer',
    'Laboratory Analyst',
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _institutionController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    setState(() => _errorMessage = null);

    if (!_agreedToTerms) {
      setState(() {
        _errorMessage = 'You must review and accept the Research Terms & Safety Protocol to proceed.';
      });
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final appState = context.read<AppStateProvider>();
    final success = appState.login(
      email: _emailController.text,
      password: _passwordController.text,
      name: 'Barathwaj R.',
      role: _selectedRole,
      institution: _institutionController.text,
    );

    if (success) {
      Navigator.of(context).pushReplacementNamed('/');
    } else {
      setState(() {
        _errorMessage = 'Invalid credentials. Please verify your researcher ID and security key.';
      });
    }
  }

  void _handleGuestLogin() {
    final appState = context.read<AppStateProvider>();
    appState.loginAsGuest(role: 'Guest Investigator');
    Navigator.of(context).pushReplacementNamed('/');
  }

  void _openTerms() async {
    final accepted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const TermsConditionsScreen(showAcceptButton: true),
      ),
    );
    if (accepted == true) {
      setState(() {
        _agreedToTerms = true;
        _errorMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // System Branding Icon & Badge
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primarySurface,
                          border: Border.all(color: AppColors.cardBorder, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryAccent.withValues(alpha: 0.15),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.psychology_outlined,
                          size: 44,
                          color: AppColors.primaryAccent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Center(
                      child: Text(
                        'POKIDEX',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3.0,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Center(
                      child: Text(
                        'Neural Telemetry & BCI Research Terminal',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Protocol specs chip
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.secondarySurface,
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.waves, size: 13, color: AppColors.waveformCyan),
                            SizedBox(width: 6),
                            Text(
                              '4-CH BIOPOTENTIAL • 250 HZ STREAMING',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: AppColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Card Container
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(AppRadius.heroCard),
                        border: Border.all(color: AppColors.cardBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'RESEARCHER AUTHENTICATION',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: AppColors.secondaryBlue,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Email / Researcher ID
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(fontSize: 14, color: AppColors.primaryText),
                            decoration: const InputDecoration(
                              labelText: 'Researcher ID / Institutional Email',
                              prefixIcon: Icon(Icons.badge_outlined, size: 20, color: AppColors.mutedText),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter your researcher ID';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Password / Key
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(fontSize: 14, color: AppColors.primaryText),
                            decoration: InputDecoration(
                              labelText: 'Terminal Security Key',
                              prefixIcon: const Icon(Icons.key_outlined, size: 20, color: AppColors.mutedText),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  size: 20,
                                  color: AppColors.mutedText,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter your security key';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Role Dropdown
                          DropdownButtonFormField<String>(
                            value: _selectedRole,
                            dropdownColor: AppColors.secondarySurface,
                            style: const TextStyle(fontSize: 13, color: AppColors.primaryText),
                            decoration: const InputDecoration(
                              labelText: 'Investigator Role',
                              prefixIcon: Icon(Icons.work_outline, size: 20, color: AppColors.mutedText),
                            ),
                            items: _roles.map((role) {
                              return DropdownMenuItem(
                                value: role,
                                child: Text(role),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedRole = val);
                            },
                          ),
                          const SizedBox(height: 16),

                          // Terms and Conditions Checkbox
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _agreedToTerms = !_agreedToTerms;
                                if (_agreedToTerms) _errorMessage = null;
                              });
                            },
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _agreedToTerms,
                                    activeColor: AppColors.primaryAccent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    onChanged: (v) {
                                      setState(() {
                                        _agreedToTerms = v ?? false;
                                        if (_agreedToTerms) _errorMessage = null;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Wrap(
                                    children: [
                                      const Text(
                                        'I agree to the ',
                                        style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                                      ),
                                      GestureDetector(
                                        onTap: _openTerms,
                                        child: const Text(
                                          'Research Terms & Safety Protocols',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primaryAccent,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (_errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, size: 16, color: AppColors.error),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(fontSize: 11, color: AppColors.error),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),

                          // Authenticate Button
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.button),
                              ),
                            ),
                            icon: const Icon(Icons.login, size: 18),
                            label: const Text(
                              'AUTHENTICATE TERMINAL',
                              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                            onPressed: _handleLogin,
                          ),
                          const SizedBox(height: 12),

                          // Quick Demo Mode Button
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.secondaryText,
                              side: const BorderSide(color: AppColors.border),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.button),
                              ),
                            ),
                            icon: const Icon(Icons.bolt, size: 18, color: AppColors.warning),
                            label: const Text(
                              'Quick Laboratory Demo Mode',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            onPressed: _handleGuestLogin,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Institutional Compliance Footer
                    const Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, size: 14, color: AppColors.success),
                          SizedBox(width: 6),
                          Text(
                            'IRB Protocol Compliant • Pseudonymized Zero-PII Telemetry',
                            style: TextStyle(fontSize: 10.5, color: AppColors.mutedText),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
