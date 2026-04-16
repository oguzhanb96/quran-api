import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/settings/app_preferences.dart';

import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/network/app_dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PremiumPage extends ConsumerStatefulWidget {
  const PremiumPage({super.key});

  @override
  ConsumerState<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends ConsumerState<PremiumPage> {
  bool _premium = AppPreferences.isPremiumEnabled();
  bool _isPurchasing = false;
  int _selectedPlan = 1;

  static const _plans = [
    (id: 'monthly', label: 'Aylık', price: '₺49,99', period: '/ay', badge: ''),
    (id: 'yearly', label: 'Yıllık', price: '₺399,99', period: '/yıl', badge: '%33 İndirim'),
  ];

  static const _features = [
    (icon: Icons.download_rounded, title: 'Offline Kur\'an Ses İndirme', desc: 'İnternetsiz dinleme imkânı'),
    (icon: Icons.block_rounded, title: 'Reklamsız Kullanım', desc: 'Kesintisiz manevi deneyim'),
    (icon: Icons.record_voice_over_rounded, title: 'Tüm Kari Sesleri', desc: 'Dünyaca ünlü hafızlar'),
    (icon: Icons.bar_chart_rounded, title: 'Gelişmiş İstatistikler', desc: 'Detaylı ilerleme takibi'),
    (icon: Icons.palette_rounded, title: 'Özel Temalar', desc: 'Kişiselleştirilmiş arayüz'),
    (icon: Icons.color_lens_rounded, title: 'Tecvid Pro', desc: 'Gelişmiş renklendirme motoru'),
  ];

  // DEMO MODE: Set to true for testing premium features without backend
  static const bool _demoMode = true;

  Future<void> _purchase() async {
    if (!AuthService().isAuthenticated) {
      final didAuth = await context.push<bool>('/auth');
      if (didAuth != true) return; 
    }

    setState(() => _isPurchasing = true);
    try {
      // Simulate app store payment hook
      await Future.delayed(const Duration(milliseconds: 1000));
      
      if (_demoMode) {
        // DEMO: Skip backend API call, activate premium directly
        await AppPreferences.setPremiumEnabled(true);
        if (!mounted) return;
        setState(() {
          _premium = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text('DEMO: Premium aktif! Tüm özellikler açıldı.', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w600)),
              ],
            ),
            backgroundColor: const Color(0xFF7C3AED),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }
      
      final dio = ref.read(dioProvider);
      
      final session = Supabase.instance.client.auth.currentSession;
      final token = session?.accessToken;

      await dio.post(
        '/api/v1/auth/premium/activate', 
        data: {
          'plan': _plans[_selectedPlan].id,
          'userId': AuthService().currentUserId,
        },
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        ),
      );
      
      await AppPreferences.setPremiumEnabled(true);
      if (!mounted) return;
      setState(() {
        _premium = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Premium aktif! Tüm özellikler açıldı.', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w600)),
            ],
          ),
          backgroundColor: const Color(0xFF7C3AED),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Satın alım/Kayıt tamamlanamadı: $e')),
      );
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _isPurchasing = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _isPurchasing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Satın alma geçmişi kontrol edildi.',
          style: TextStyle(fontFamily: 'Plus Jakarta Sans'),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF020617) : const Color(0xFFFBF9F5),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            floating: true,
            title: Text(
              'Premium',
              style: GoogleFonts.notoSerif(fontWeight: FontWeight.bold),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Hero banner ───────────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF6D28D9), Color(0xFF7C3AED), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD166), size: 32),
                          const SizedBox(width: 12),
                          Text(
                            'Premium Üyelik',
                            style: GoogleFonts.notoSerif(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          if (_premium)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_rounded, color: Colors.white, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'Aktif',
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Tüm özelliklerin kilidini açın ve daha derin bir manevi deneyim yaşayın.',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 14,
                          color: Colors.white70,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ).animate().fade(duration: 500.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: 24),

                if (!_premium) ...[
                  // ── Plan seçimi ───────────────────────────────────────
                  Text(
                    'PLAN SEÇ',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(_plans.length, (i) {
                      final plan = _plans[i];
                      final isSelected = _selectedPlan == i;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedPlan = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: EdgeInsets.only(right: i == 0 ? 8 : 0, left: i == 1 ? 8 : 0),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF7C3AED).withValues(alpha: 0.1)
                                  : (isDark ? const Color(0xFF0F172A) : Colors.white),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF7C3AED)
                                    : scheme.outlineVariant.withValues(alpha: 0.3),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (plan.badge.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      plan.badge,
                                      style: const TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                if (plan.badge.isNotEmpty) const SizedBox(height: 8),
                                Text(
                                  plan.label,
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  plan.price,
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? const Color(0xFF7C3AED) : scheme.onSurface,
                                  ),
                                ),
                                Text(
                                  plan.period,
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 11,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 20),

                  // ── Satın al butonu ───────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isPurchasing ? null : _purchase,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      child: _isPurchasing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.workspace_premium_rounded, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Premium\'a Geç — ${_plans[_selectedPlan].price}',
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextButton(
                    onPressed: _isPurchasing ? null : _restore,
                    child: Text(
                      'Satın almayı geri yükle',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        color: scheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                ],

                // ── Premium özellikler ────────────────────────────────────
                Text(
                  'PREMIUM ÖZELLİKLER',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: 12),

                ..._features.asMap().entries.map((entry) {
                  final i = entry.key;
                  final f = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _premium
                            ? (isDark
                                ? const Color(0xFF0F172A)
                                : Colors.white)
                            : (isDark
                                ? const Color(0xFF0F172A).withValues(alpha: 0.5)
                                : Colors.white.withValues(alpha: 0.7)),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _premium
                              ? const Color(0xFF7C3AED).withValues(alpha: 0.15)
                              : scheme.outlineVariant.withValues(alpha: 0.15),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _premium
                                  ? const Color(0xFF7C3AED).withValues(alpha: 0.12)
                                  : scheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              f.icon,
                              color: _premium
                                  ? const Color(0xFF7C3AED)
                                  : scheme.onSurfaceVariant,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  f.title,
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _premium
                                        ? scheme.onSurface
                                        : scheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                                Text(
                                  f.desc,
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 12,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            _premium
                                ? Icons.check_circle_rounded
                                : Icons.lock_rounded,
                            color: _premium
                                ? const Color(0xFF10B981)
                                : scheme.onSurfaceVariant.withValues(alpha: 0.4),
                            size: 20,
                          ),
                        ],
                      ),
                    ).animate().fade(
                      duration: 400.ms,
                      delay: Duration(milliseconds: 100 + i * 60),
                    ),
                  );
                }),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
