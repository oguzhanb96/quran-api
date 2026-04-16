import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/settings/app_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const _countries = <String>[
    'Türkiye',
    'Suudi Arabistan',
    'Mısır',
    'Pakistan',
    'Endonezya',
  ];
  static const _cityByCountry = <String, List<String>>{
    'Türkiye': ['İstanbul', 'Ankara', 'İzmir', 'Konya', 'Bursa', 'Adana', 'Gaziantep'],
    'Suudi Arabistan': ['Mekke', 'Medine', 'Riyad', 'Cidde'],
    'Mısır': ['Kahire', 'İskenderiye'],
    'Pakistan': ['Karaçi', 'Lahor', 'İslamabad'],
    'Endonezya': ['Cakarta', 'Bandung', 'Surabaya'],
  };

  String _country = 'Türkiye';
  String _city = 'İstanbul';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    final country = await AppPreferences.getSelectedCountry();
    final city = await AppPreferences.getSelectedCity();
    if (!mounted) return;
    setState(() {
      _country = country ?? _country;
      _city = city ?? _city;
      _loading = false;
    });
  }

  Future<void> _saveLocation() async {
    await AppPreferences.setSelectedCountry(_country);
    await AppPreferences.setSelectedCity(_city);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Konum kaydedildi. Namaz saatleri güncellenecek.',
          style: TextStyle(fontFamily: 'Plus Jakarta Sans'),
        ),
        backgroundColor: const Color(0xFF064E3B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF020617) : const Color(0xFFFBF9F5),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final cityOptions = _cityByCountry[_country] ?? const <String>[];
    if (!cityOptions.contains(_city) && cityOptions.isNotEmpty) {
      _city = cityOptions.first;
    }

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
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: scheme.onSurface),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Profil ve Ayarlar',
              style: GoogleFonts.notoSerif(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
            centerTitle: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Avatar
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              scheme.primary.withValues(alpha: 0.8),
                              scheme.secondary.withValues(alpha: 0.8),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: scheme.primary.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'O',
                            style: GoogleFonts.notoSerif(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Oğuzhan',
                        style: GoogleFonts.notoSerif(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ramazan 1445\'ten beri üye',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Tercihler bölümü
                Text(
                  'TERCİHLER',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),

                _PreferenceCard(
                  icon: Icons.notifications_outlined,
                  iconColor: const Color(0xFF0EA5E9),
                  iconBg: const Color(0xFF0EA5E9).withValues(alpha: 0.12),
                  title: 'Bildirim Tercihleri',
                  subtitle: 'Ezan, günlük içerik ve etkinlik hatırlatmaları',
                  onTap: () => context.push('/notification-preferences'),
                ),
                const SizedBox(height: 10),
                _PreferenceCard(
                  icon: Icons.favorite_outline_rounded,
                  iconColor: const Color(0xFFD97706),
                  iconBg: const Color(0xFFD97706).withValues(alpha: 0.12),
                  title: 'Gelişime Katkı',
                  subtitle: 'Premium üyelik, bağış ve ek özellikler',
                  onTap: () => context.push('/support'),
                ),
                const SizedBox(height: 10),
                _PreferenceCard(
                  icon: Icons.shield_outlined,
                  iconColor: const Color(0xFF1D4ED8),
                  iconBg: const Color(0xFF1D4ED8).withValues(alpha: 0.12),
                  title: 'Gizlilik ve KVKK',
                  subtitle: 'Gizlilik politikası, veri hakları ve onay yönetimi',
                  onTap: () => context.push('/privacy-policy'),
                ),

                const SizedBox(height: 28),

                // Konum bölümü
                Text(
                  'KONUM',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: scheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.location_on_rounded,
                              size: 18,
                              color: scheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Namaz Vakti Konumu',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _countries.contains(_country) ? _country : _countries.first,
                        decoration: InputDecoration(
                          labelText: 'Ülke',
                          labelStyle: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            color: scheme.onSurfaceVariant,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        items: _countries
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(
                                    c,
                                    style: const TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                    ),
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          final nextCities = _cityByCountry[value] ?? const <String>[];
                          setState(() {
                            _country = value;
                            _city = nextCities.isEmpty ? _city : nextCities.first;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: cityOptions.contains(_city) ? _city : (cityOptions.isNotEmpty ? cityOptions.first : null),
                        decoration: InputDecoration(
                          labelText: 'Şehir',
                          labelStyle: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            color: scheme.onSurfaceVariant,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        items: cityOptions
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(
                                    c,
                                    style: const TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                    ),
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _city = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _saveLocation,
                          icon: const Icon(Icons.save_rounded, size: 18),
                          label: const Text(
                            'Konumu Kaydet',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferenceCard extends StatelessWidget {
  const _PreferenceCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF0F172A) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
