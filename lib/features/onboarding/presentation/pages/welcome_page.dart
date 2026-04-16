import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/localization/app_language.dart';
import '../../../../core/settings/app_preferences.dart';

class WelcomePage extends ConsumerStatefulWidget {
  const WelcomePage({super.key});

  @override
  ConsumerState<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends ConsumerState<WelcomePage> {
  Locale _selected = const Locale('tr');
  bool _accepted = false;

  @override
  void initState() {
    super.initState();
    _selected = ref.read(appLocaleProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF004D31), Color(0xFF006D44), Color(0xFF003321)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -50, right: -50,
              child: Container(
                width: 450, height: 450,
                decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFFFD200).withValues(alpha: 0.05)),
              ).animate().fadeIn(duration: 2.seconds).scale(duration: 2.seconds, begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1)),
            ),
            Positioned(
              bottom: 200, left: -100,
              child: Container(
                width: 400, height: 400,
                decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF91F8BA).withValues(alpha: 0.1)),
              ).animate().fadeIn(duration: 2.seconds, delay: 400.ms).scale(duration: 2.seconds, begin: const Offset(1.1, 1.1), end: const Offset(0.9, 0.9)),
            ),
            
            const Positioned.fill(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(top: 100),
                  child: Icon(Icons.mosque, size: 300, color: Colors.white12),
                ),
              ),
            ),
            
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 24.0),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD200).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFFD200).withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            'DIVINE GUIDANCE',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: const Color(0xFFD9C36C),
                              letterSpacing: 3,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Al-Quran',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(48),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                child: Container(
                                  width: double.infinity,
                                  height: 320,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(48),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                  ),
                                  child: Stack(
                                    children: [
                                      const Positioned(
                                        top: 24, left: 32,
                                        child: Icon(Icons.bedtime, color: Color(0xFFFFDF91), size: 40),
                                      ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: -5, end: 5, duration: 2.seconds),
                                      const Positioned(
                                        top: 32, right: 48,
                                        child: Icon(Icons.star, color: Color(0xFFD9C36C), size: 24),
                                      ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 1.5.seconds),
                                      
                                      Center(
                                        child: Container(
                                          width: 180, height: 240,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: const BorderRadius.only(
                                              topRight: Radius.circular(16),
                                              bottomRight: Radius.circular(16),
                                              topLeft: Radius.circular(4),
                                              bottomLeft: Radius.circular(4),
                                            ),
                                            boxShadow: [
                                              BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 40, offset: const Offset(10, 10)),
                                            ],
                                          ),
                                          child: Stack(
                                            children: [
                                              Container(width: 6, color: const Color(0xFFFFD200).withValues(alpha: 0.2)),
                                              Positioned(
                                                top: 0, right: 20,
                                                child: Container(
                                                  width: 24, height: 60,
                                                  decoration: const BoxDecoration(
                                                    color: Color(0xFF006D44),
                                                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
                                                  ),
                                                ),
                                              ),
                                              Center(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Container(
                                                      width: 72, height: 72,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: const Color(0xFF006D44).withValues(alpha: 0.1),
                                                      ),
                                                      child: const Icon(Icons.menu_book, color: Color(0xFF006D44), size: 40),
                                                    ),
                                                    const SizedBox(height: 16),
                                                    Container(width: 48, height: 4, decoration: BoxDecoration(color: const Color(0xFFD9C36C), borderRadius: BorderRadius.circular(2))),
                                                    const SizedBox(height: 12),
                                                    const Text(
                                                      'القرآن الكريم',
                                                      style: TextStyle(fontSize: 24, color: Color(0xFF006D44), fontWeight: FontWeight.bold, fontFamily: 'Amiri'),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ).animate().scale(delay: 400.ms, duration: 800.ms, curve: Curves.easeOutBack),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ).animate().fadeIn(duration: 800.ms),
                            
                            Positioned(
                              bottom: -15, left: -10,
                              child: Transform.rotate(
                                angle: 0.05,
                                child: Container(
                                  width: 180, height: 240,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFFFFD200).withValues(alpha: 0.3), width: 2),
                                    borderRadius: const BorderRadius.only(topRight: Radius.circular(16), bottomRight: Radius.circular(16), topLeft: Radius.circular(4), bottomLeft: Radius.circular(4)),
                                  ),
                                ),
                              ),
                            ).animate().fadeIn(duration: 1.seconds),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(48), topRight: Radius.circular(48)),
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 40, offset: Offset(0, -10)),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(32, 40, 32, 40),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(width: 32, height: 6, decoration: BoxDecoration(color: const Color(0xFF006D44), borderRadius: BorderRadius.circular(3))),
                            const SizedBox(width: 6),
                            Container(width: 8, height: 6, decoration: BoxDecoration(color: const Color(0xFFE1E3E0), borderRadius: BorderRadius.circular(3))),
                            const SizedBox(width: 6),
                            Container(width: 8, height: 6, decoration: BoxDecoration(color: const Color(0xFFE1E3E0), borderRadius: BorderRadius.circular(3))),
                          ],
                        ),
                        const SizedBox(height: 32),
                        
                        Text(
                          '${AppText.of(context, 'welcomeGreeting')} & ${AppText.of(context, 'welcomeAppName')}',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF191C1A),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppText.of(context, 'welcomeTagline'),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF404943),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F4F1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<Locale>(
                              isExpanded: true,
                              value: _selected,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              borderRadius: BorderRadius.circular(12),
                              icon: const Icon(Icons.language, color: Color(0xFF006D44)),
                              items: appLanguageOptions.map((o) => DropdownMenuItem<Locale>(value: o.locale, child: Text(o.label, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
                              onChanged: (value) {
                                if (value != null) setState(() => _selected = value);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        Theme(
                          data: Theme.of(context).copyWith(
                            checkboxTheme: CheckboxThemeData(
                              fillColor: WidgetStateProperty.resolveWith((states) {
                                if (states.contains(WidgetState.selected)) return const Color(0xFF006D44);
                                return Colors.transparent;
                              }),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                          ),
                          child: CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            value: _accepted,
                            onChanged: (val) => setState(() => _accepted = val ?? false),
                            title: Text(
                              AppText.of(context, 'welcomeTerms'),
                              style: const TextStyle(fontSize: 13, color: Color(0xFF404943)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        Container(
                          width: double.infinity,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF006D44), Color(0xFF005232)]),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFF006D44).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10)),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: !_accepted ? null : () async {
                                ref.read(appLocaleProvider.notifier).state = _selected;
                                await AppPreferences.setLocaleCode(_selected.languageCode);
                                if (!context.mounted) return;
                                context.go('/setup');
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    AppText.of(context, 'welcomeFindLocation').toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.arrow_forward, color: Color(0xFFFFDF91)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().slideY(begin: 0.5, end: 0, duration: 800.ms, curve: Curves.easeOutCubic),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
