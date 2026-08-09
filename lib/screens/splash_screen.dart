import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;

  // Step 1: Emerging from depth behind
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _flyOffsetAnimation;
  late Animation<double> _bounceAnimation;

  // Step 2: Hinge opening & Neuro reveal
  late Animation<double> _openLidAnimation;
  late Animation<double> _neuroFadeAnimation;

  // Step 3: Typography & 2-Second 1% -> 100% Progress
  late Animation<double> _textFadeAnimation;
  late Animation<double> _progressAnimation;

  int _progressPercent = 1;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    // 1. Emerging from behind (0.0 -> 0.35 of timeline, ~900ms)
    _scaleAnimation = Tween<double>(begin: 0.15, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.30, curve: Curves.easeOutCubic),
      ),
    );

    _flyOffsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -0.6),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.30, curve: Curves.easeOutCubic),
      ),
    );

    // Bounce effect on landing (0.30 -> 0.42)
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.92), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 0.92, end: 1.0), weight: 50),
    ]).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.30, 0.42, curve: Curves.easeInOut),
      ),
    );

    // 2. Open Lid (0.40 -> 0.58)
    _openLidAnimation = Tween<double>(begin: 0.0, end: -0.45).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.40, 0.58, curve: Curves.easeOutBack),
      ),
    );

    // 3. Neuro Reveal (0.50 -> 0.70)
    _neuroFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.50, 0.68, curve: Curves.easeIn),
      ),
    );

    // 4. Logo Typography (0.60 -> 0.75)
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.60, 0.75, curve: Curves.easeIn),
      ),
    );

    // 5. Loading Bar 1% to 100% (Exactly 2.0 Seconds total sequence)
    _progressAnimation = Tween<double>(begin: 0.01, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.20, 0.95, curve: Curves.easeInOut),
      ),
    );

    _progressAnimation.addListener(() {
      final p = (_progressAnimation.value * 100).round().clamp(1, 100);
      if (p != _progressPercent) {
        setState(() {
          _progressPercent = p;
        });
      }
    });

    _mainController.forward().then((_) {
      Timer(const Duration(milliseconds: 200), () {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/');
        }
      });
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Minimal Clean White Background with Subtle Glow Halo
          Positioned.fill(
            child: Container(
              color: Colors.white,
              child: Center(
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFE53935).withValues(alpha: 0.06),
                        const Color(0xFF00B3FF).withValues(alpha: 0.04),
                        Colors.white,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Main Animated Canvas Layout
          AnimatedBuilder(
            animation: _mainController,
            builder: (context, child) {
              final scale = _scaleAnimation.value * _bounceAnimation.value;
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // Pokéball + Neuro Emergence Center Piece
                  SlideTransition(
                    position: _flyOffsetAnimation,
                    child: Transform.scale(
                      scale: scale,
                      child: SizedBox(
                        width: 220,
                        height: 240,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Soft Contact Shadow under Pokéball
                            Positioned(
                              bottom: 10,
                              child: Container(
                                width: 140 * scale,
                                height: 18,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(100),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.18),
                                      blurRadius: 16,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Realistic Closed / Opened Pokéball
                            if (_openLidAnimation.value == 0.0) ...[
                              // Sealed Pokéball Image
                              Image.asset(
                                'assets/images/pokeball_icon.jpg',
                                width: 180,
                                height: 180,
                                fit: BoxFit.contain,
                              ),
                            ] else ...[
                              // Open Pokéball Shell with Floating Neuro Hologram
                              Image.asset(
                                'assets/images/open_pokeball_brain.jpg',
                                width: 220,
                                height: 220,
                                fit: BoxFit.contain,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Brand Title & Typography
                  FadeTransition(
                    opacity: _textFadeAnimation,
                    child: Column(
                      children: [
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                              color: Color(0xFF1A1A1A),
                            ),
                            children: [
                              TextSpan(text: 'POKÉ'),
                              TextSpan(
                                text: 'DEX',
                                style: TextStyle(color: Color(0xFFE53935)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'NEURO SIGNAL GENERATOR',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'EEG • VEP • BIOELECTRIC SIGNALS',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // 2-Second Precise Loading Progress (1% -> 100%)
                  FadeTransition(
                    opacity: _textFadeAnimation,
                    child: Column(
                      children: [
                        const Text(
                          'LOADING...',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6B7280),
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Progress Bar Container
                        Container(
                          width: 200,
                          height: 6,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: _progressAnimation.value.clamp(0.01, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFE53935),
                                      Color(0xFFFF5252),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFE53935).withValues(alpha: 0.4),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        Text(
                          '$_progressPercent%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE53935),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}