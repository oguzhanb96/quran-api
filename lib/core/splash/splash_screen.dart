import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.spiritualGradient,
        ),
        child: Stack(
          children: [
            Positioned(
              top: -80,
              left: -80,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFE932C).withValues(alpha: 0.15),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFE932C).withValues(alpha: 0.1),
                      blurRadius: 100,
                      spreadRadius: 50,
                    ),
                  ],
                ),
              )
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scale(duration: 4.seconds, begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), curve: Curves.easeInOut)
                  .move(duration: 4.seconds, begin: Offset.zero, end: const Offset(30, 30), curve: Curves.easeInOut),
            ),
            Positioned(
              bottom: -100,
              right: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF95D3BA).withValues(alpha: 0.12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF95D3BA).withValues(alpha: 0.1),
                      blurRadius: 100,
                      spreadRadius: 50,
                    ),
                  ],
                ),
              )
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scale(duration: 5.seconds, begin: const Offset(1.1, 1.1), end: const Offset(0.9, 0.9), curve: Curves.easeInOut)
                  .move(duration: 5.seconds, begin: Offset.zero, end: const Offset(-30, -20), curve: Curves.easeInOut),
            ),

            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                      child: Container(
                        width: 144,
                        height: 144,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 40,
                              spreadRadius: -10,
                            )
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    blurRadius: 40,
                                    spreadRadius: 15,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.menu_book_rounded,
                              color: Colors.white,
                              size: 64,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .scale(duration: 1200.ms, curve: Curves.elasticOut)
                      .fadeIn(duration: 800.ms),

                  const SizedBox(height: 48),

                  Text(
                    'Quran Companion',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                          letterSpacing: 0,
                          fontWeight: FontWeight.w700,
                        ),
                  )
                      .animate()
                      .slideY(begin: 0.2, end: 0, duration: 1.seconds, curve: Curves.easeOutCubic, delay: 300.ms)
                      .fadeIn(duration: 1.seconds, delay: 300.ms),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(height: 1, width: 40, color: Colors.white.withValues(alpha: 0.25)),
                      const SizedBox(width: 16),
                      Text(
                        'AL-QURAN',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              letterSpacing: 6,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                      ),
                      const SizedBox(width: 16),
                      Container(height: 1, width: 40, color: Colors.white.withValues(alpha: 0.25)),
                    ],
                  ).animate().fadeIn(duration: 1.seconds, delay: 600.ms),
                ],
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 64,
              child: Container(
                width: 200,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 80,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2A762),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE2A762).withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ).animate(onPlay: (controller) => controller.repeat()).moveX(
                    begin: -80,
                    end: 200,
                    duration: 1.5.seconds,
                    curve: Curves.easeInOut,
                  ),
                ),
              ).animate().fadeIn(duration: 1.seconds, delay: 900.ms),
            ),
          ],
        ),
      ),
    );
  }
}