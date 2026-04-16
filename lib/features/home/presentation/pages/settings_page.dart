import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF020617) : const Color(0xFFFBF9F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Ayarlar',
          style: GoogleFonts.notoSerif(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: scheme.primary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Genel',
              style: GoogleFonts.notoSerif(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingItem(context, Icons.language, 'Dil', 'Türkçe'),
            _buildSettingItem(context, isDark ? Icons.light_mode : Icons.dark_mode, 'Tema', isDark ? 'Koyu' : 'Açık'),
            _buildSettingItem(context, Icons.notifications, 'Bildirimler', 'Açık'),
            const SizedBox(height: 32),
            Text(
              'Namaz',
              style: GoogleFonts.notoSerif(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingItem(context, Icons.location_on, 'Konum', 'İstanbul, TR'),
            _buildSettingItem(context, Icons.calculate, 'Hesaplama Metodu', 'Diyanet'),
            const SizedBox(height: 32),
            Text(
              'Hakkında',
              style: GoogleFonts.notoSerif(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingItem(context, Icons.info, 'Versiyon', '1.0.0'),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(BuildContext context, IconData icon, String title, String subtitle) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: scheme.primary),
      title: Text(title, style: const TextStyle(fontFamily: 'Plus Jakarta Sans')),
      subtitle: Text(subtitle, style: TextStyle(fontFamily: 'Plus Jakarta Sans', color: scheme.onSurfaceVariant)),
      trailing: Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
      onTap: () {},
    );
  }
}
