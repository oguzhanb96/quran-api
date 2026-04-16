import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ZakatCalculatorPage extends StatefulWidget {
  const ZakatCalculatorPage({super.key});

  @override
  State<ZakatCalculatorPage> createState() => _ZakatCalculatorPageState();
}

class _ZakatCalculatorPageState extends State<ZakatCalculatorPage> {
  final _gold = TextEditingController(text: '0');
  final _cash = TextEditingController(text: '0');
  final _trade = TextEditingController(text: '0');
  final _goldPrice = TextEditingController(text: '4000');
  double _result = 0;

  @override
  void dispose() {
    _gold.dispose();
    _cash.dispose();
    _trade.dispose();
    _goldPrice.dispose();
    super.dispose();
  }

  double _value(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;

  void _calculate() {
    final total = _value(_gold) * _value(_goldPrice) + _value(_cash) + _value(_trade);
    setState(() => _result = total * 0.025);
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
              'Zekât Hesaplayıcı',
              style: GoogleFonts.notoSerif(fontWeight: FontWeight.bold),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Bilgi kartı
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        scheme.primary.withValues(alpha: 0.15),
                        scheme.primary.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: scheme.primary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Zekât oranı %2,5\'tir. Nisap miktarını aşan mallar için hesaplanır.',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 13,
                            color: scheme.onSurface,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                _InputCard(
                  isDark: isDark,
                  children: [
                    _buildField('Altın (gram)', _gold, Icons.circle_rounded, const Color(0xFFD97706)),
                    const SizedBox(height: 14),
                    _buildField('Altın gram fiyatı (₺)', _goldPrice, Icons.attach_money_rounded, const Color(0xFFD97706)),
                    const SizedBox(height: 14),
                    _buildField('Nakit para (₺)', _cash, Icons.account_balance_wallet_rounded, const Color(0xFF064E3B)),
                    const SizedBox(height: 14),
                    _buildField('Ticaret malı (₺)', _trade, Icons.store_rounded, const Color(0xFF0369A1)),
                  ],
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _calculate,
                    icon: const Icon(Icons.calculate_rounded),
                    label: const Text(
                      'Hesapla',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),

                if (_result > 0) ...[
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF064E3B), Color(0xFF065F46)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF064E3B).withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Text(
                          'ÖNERİLEN ZEKÂT',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: Color(0xFF6EE7B7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₺${_result.toStringAsFixed(2)}',
                          style: GoogleFonts.notoSerif(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        color: scheme.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          color: scheme.onSurfaceVariant,
        ),
        prefixIcon: Icon(icon, color: color, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.02),
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  const _InputCard({required this.isDark, required this.children});
  final bool isDark;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(children: children),
    );
  }
}
