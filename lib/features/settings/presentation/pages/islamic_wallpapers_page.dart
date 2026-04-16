import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

class IslamicWallpapersPage extends StatelessWidget {
  const IslamicWallpapersPage({super.key});

  static const _wallpapers = <({String url, String title})>[
    (url: 'https://images.unsplash.com/photo-1542810634-71277d95dcbb?w=1200', title: 'Cami Mimarisi'),
    (url: 'https://images.unsplash.com/photo-1524499982521-1ffd58dd89ea?w=1200', title: 'Gece Manzarası'),
    (url: 'https://images.unsplash.com/photo-1609599006353-e629aaabfeae?w=1200', title: 'Kur\'an Sayfası'),
    (url: 'https://images.unsplash.com/photo-1564769662533-4f00a87b4056?w=1200', title: 'Mescid-i Haram'),
    (url: 'https://images.unsplash.com/photo-1519817914152-22d216bb9170?w=1200', title: 'Hilal'),
    (url: 'https://images.unsplash.com/photo-1591604129939-f1efa4d9f7fa?w=1200', title: 'Tesbih'),
  ];

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
              'İslami Duvar Kağıtları',
              style: GoogleFonts.notoSerif(fontWeight: FontWeight.bold),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.65,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final w = _wallpapers[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: w.url,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: isDark
                                ? const Color(0xFF0F172A)
                                : Colors.grey.shade200,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: isDark
                                ? const Color(0xFF0F172A)
                                : Colors.grey.shade200,
                            child: Icon(
                              Icons.image_not_supported_rounded,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.7),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    w.title,
                                    style: const TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => SharePlus.instance
                                      .share(ShareParams(text: w.url)),
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.share_rounded,
                                      color: Colors.white,
                                      size: 16,
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
                },
                childCount: _wallpapers.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
