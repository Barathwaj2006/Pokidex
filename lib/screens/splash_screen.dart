import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _openController;
  late AnimationController _pulseController;

  // Flight & Roll Animations
  late Animation<Offset> _flyOffsetAnimation;
  late Animation<double> _rollRotationAnimation;
  late Animation<double> _scaleAnimation;

  // Opening & Light Flash Animations
  late Animation<double> _lidOpenAnimation;
  late Animation<double> _lightBurstScaleAnimation;
  late Animation<double> _lightBurstOpacityAnimation;
  late Animation<double> _contentFadeAnimation;

  bool _isOpened = false;

  @override
  void initState() {
    super.initState();

    // Phase 1: Entry Flying & Rolling Ball (1.6s)
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _flyOffsetAnimation = Tween<Offset>(
      begin: const Offset(-1.8, -2.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Curves.easeOutBack,
      ),
    );

    _rollRotationAnimation = Tween<double>(
      begin: -4 * math.pi,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Curves.easeOutCubic,
      ),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.2,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Curves.easeOutBack,
      ),
    );

    // Phase 2: Opening & Light Burst (1.2s)
    _openController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _lidOpenAnimation = Tween<double>(
      begin: 0.0,
      end: -35.0,
    ).animate(
      CurvedAnimation(
        parent: _openController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _lightBurstScaleAnimation = Tween<double>(
      begin: 0.1,
      end: 25.0,
    ).animate(
      CurvedAnimation(
        parent: _openController,
        curve: const Interval(0.2, 0.9, curve: Curves.fastOutSlowIn),
      ),
    );

    _lightBurstOpacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.8), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: 0.8, end: 0.0), weight: 30),
    ]).animate(_openController);

    _contentFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _openController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    // Phase 3: Continuous Pulse after open
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    // Sequence controller steps
    _entryController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            _isOpened = true;
          });
          _openController.forward().then((_) {
            Timer(const Duration(milliseconds: 600), () {
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/');
              }
            });
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _openController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.9,
                  colors: [
                    Color(0xFF1E1B4B),
                    Color(0xFF0F172A),
                    Color(0xFF0B0F19),
                  ],
                ),
              ),
            ),
          ),

          // Flying and Rolling Animated Pokéball Container
          AnimatedBuilder(
            animation: Listenable.merge([_entryController, _openController]),
            builder: (context, child) {
              return SlideTransition(
                position: _flyOffsetAnimation,
                child: Transform.rotate(
                  angle: _rollRotationAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glow Ring around Pokéball
                        Container(
                          width: 170,
                          height: 170,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.cyanAccent.withValues(alpha: 0.5),
                                blurRadius: 40,
                                spreadRadius: 8,
                              ),
                              BoxShadow(
                                color: Colors.indigoAccent.withValues(alpha: 0.7),
                                blurRadius: 60,
                                spreadRadius: 15,
                              ),
                            ],
                          ),
                        ),

                        // Pokéball Top Half (Separates on Open)
                        Transform.translate(
                          offset: Offset(0, _lidOpenAnimation.value),
                          child: ClipRect(
                            child: Align(
                              alignment: Alignment.topCenter,
                              heightFactor: 0.5,
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                ),
                                child: Image.asset(
                                  'assets/images/pokidex_logo.jpg',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Pokéball Bottom Half
                        Transform.translate(
                          offset: Offset(0, -_lidOpenAnimation.value * 0.5),
                          child: ClipRect(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              heightFactor: 0.5,
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                ),
                                child: Image.asset(
                                  'assets/images/pokidex_logo.jpg',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Pokéball Center Trigger Button Glow
                        if (!_isOpened)
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.cyanAccent,
                                  blurRadius: 15,
                                  spreadRadius: 4,
                                ),
                              ],
                              border: Border.all(color: Colors.black, width: 3),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Bright Radial Light Flash Burst upon Pokéball Opening
          AnimatedBuilder(
            animation: _openController,
            builder: (context, child) {
              if (_openController.value == 0) return const SizedBox.shrink();
              return Opacity(
                opacity: _lightBurstOpacityAnimation.value,
                child: Transform.scale(
                  scale: _lightBurstScaleAnimation.value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white,
                          Colors.cyanAccent,
                          Colors.blueAccent,
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.3, 0.7, 1.0],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Revealed Application Title & Subtitle after Bright Light Flash
          Positioned(
            bottom: 110,
            child: FadeTransition(
              opacity: _contentFadeAnimation,
              child: Column(
                children: [
                  const Text(
                    'POKIDEX',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 5.0,
                      shadows: [
                        Shadow(color: Colors.cyanAccent, blurRadius: 15),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'NEURAL SIGNAL SIMULATION PLATFORM',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyanAccent,
                      letterSpacing: 2.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4)),
                    ),
                    child: const Text(
                      'Pyromatix & NeuroSync BCI Enabled',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
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