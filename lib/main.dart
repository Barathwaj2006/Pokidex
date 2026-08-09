import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_state_provider.dart';
import 'providers/signal_provider.dart';
import 'screens/connection_screen.dart';
import 'screens/eeg_config_screen.dart';
import 'screens/erp_config_screen.dart';
import 'screens/ground_truth_log_screen.dart';
import 'screens/main_shell_screen.dart';
import 'screens/patient_presets_screen.dart';
import 'screens/scenario_picker_screen.dart';
import 'screens/splash_screen.dart';
import 'services/ground_truth_service.dart';
import 'services/session_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final appState = AppStateProvider();
  final groundTruthService = GroundTruthService();
  final sessionService = SessionService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appState),
        Provider.value(value: groundTruthService),
        Provider.value(value: sessionService),
        ChangeNotifierProvider(
          create: (_) => SignalProvider(
            appState: appState,
            groundTruthService: groundTruthService,
            sessionService: sessionService,
          ),
        ),
      ],
      child: const PokidexApp(),
    ),
  );
}

class PokidexApp extends StatelessWidget {
  const PokidexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokidex',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: AppTheme.lightTheme,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/': (context) => const MainShellScreen(),
        '/eeg-config': (context) => const EegConfigScreen(),
        '/erp-config': (context) => const ErpConfigScreen(),
        '/scenarios': (context) => const ScenarioPickerScreen(),
        '/patient-presets': (context) => const PatientPresetsScreen(),
        '/connection': (context) => const ConnectionScreen(),
        '/log': (context) => const GroundTruthLogScreen(),
      },
    );
  }
}