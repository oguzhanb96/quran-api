import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/app_language.dart';

class IslamicCalendarPage extends StatefulWidget {
  const IslamicCalendarPage({super.key});

  @override
  State<IslamicCalendarPage> createState() => _IslamicCalendarPageState();
}

class _IslamicCalendarPageState extends State<IslamicCalendarPage>
    with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  late TabController _tabController;
  final Set<String> _remindedEvents = <String>{};

  static const _hijriMonthNames = [
    'Muharrem', 'Safer', 'Rebiülevvel', 'Rebiülahir',
    'Cemaziyelevvel', 'Cemaziyelahir', 'Recep', 'Şaban',
    'Ramazan', 'Şevval', 'Zilkade', 'Zilhicce',
  ];

  static const _events = [
    _IslamicEvent(
      name: 'Ramazan Başlangıcı',
      nameEn: 'Start of Ramadan',
      hijriDate: '1 Ramazan',
      hijriMonth: 9,
      hijriDay: 1,
      icon: Icons.nightlight_round,
      color: Color(0xFF0EA5E9),
      description: 'Mübarek Ramazan ayının başlangıcı. Oruç, teravih ve Kur\'an tilavetiyle geçirilir.',
    ),
    _IslamicEvent(
      name: 'Kadir Gecesi',
      nameEn: 'Night of Power (Laylat al-Qadr)',
      hijriDate: '27 Ramazan',
      hijriMonth: 9,
      hijriDay: 27,
      icon: Icons.star_rounded,
      color: Color(0xFF8B5CF6),
      description: 'Bin aydan hayırlı olan bu gecede Kur\'an indirilmeye başlandı. İbadet ve dua gecesi.',
    ),
    _IslamicEvent(
      name: 'Ramazan Bayramı',
      nameEn: 'Eid al-Fitr',
      hijriDate: '1 Şevval',
      hijriMonth: 10,
      hijriDay: 1,
      icon: Icons.celebration_rounded,
      color: Color(0xFFF59E0B),
      description: 'Ramazan orucunun tamamlanmasının ardından kutlanan bayram. Fitre ve bayram namazı.',
    ),
    _IslamicEvent(
      name: 'Arefe',
      nameEn: 'Day of Arafah',
      hijriDate: '9 Zilhicce',
      hijriMonth: 12,
      hijriDay: 9,
      icon: Icons.terrain_rounded,
      color: Color(0xFF10B981),
      description: 'Hacıların Arafat\'ta vakfe yaptığı mübarek gün. Oruç tutmak büyük sevap.',
    ),
    _IslamicEvent(
      name: 'Kurban Bayramı',
      nameEn: 'Eid al-Adha',
      hijriDate: '10 Zilhicce',
      hijriMonth: 12,
      hijriDay: 10,
      icon: Icons.volunteer_activism_rounded,
      color: Color(0xFFEC4899),
      description: 'Hz. İbrahim\'in sünnetini yaşatan, kurban kesilen ve bayram namazı kılınan mübarek gün.',
    ),
    _IslamicEvent(
      name: 'Regaib Gecesi',
      nameEn: 'Night of Raghaib',
      hijriDate: '1. Cuma (Recep)',
      hijriMonth: 7,
      hijriDay: 1,
      icon: Icons.bedtime_rounded,
      color: Color(0xFF06B6D4),
      description: 'Recep ayının ilk Cuma gecesi. Üç ayların başlangıcı.',
    ),
    _IslamicEvent(
      name: 'Miraç Kandili',
      nameEn: 'Night of Ascension (Isra & Miraj)',
      hijriDate: '27 Recep',
      hijriMonth: 7,
      hijriDay: 27,
      icon: Icons.rocket_launch_rounded,
      color: Color(0xFF7C3AED),
      description: 'Hz. Peygamber\'in göğe yükseldiği ve 5 vakit namazın farz kılındığı mübarek gece.',
    ),
    _IslamicEvent(
      name: 'Berat Kandili',
      nameEn: 'Night of Forgiveness (Laylat al-Bara\'at)',
      hijriDate: '15 Şaban',
      hijriMonth: 8,
      hijriDay: 15,
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFFD97706),
      description: 'Günahların affedildiği, yıllık kaderin belirlendiği mübarek gece.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  ({int year, int month, int day}) _gregorianToHijri(DateTime date) {
    final jd =
        ((1461 * (date.year + 4800 + ((date.month - 14) ~/ 12))) ~/ 4) +
        ((367 * (date.month - 2 - 12 * ((date.month - 14) ~/ 12))) ~/ 12) -
        ((3 * ((date.year + 4900 + ((date.month - 14) ~/ 12)) ~/ 100)) ~/ 4) +
        date.day -
        32075;
    final l = jd - 1948440 + 10632;
    final n = ((l - 1) ~/ 10631);
    final l2 = l - 10631 * n + 354;
    final j =
        (((10985 - l2) ~/ 5316) * ((50 * l2) ~/ 17719)) +
        ((l2 ~/ 5670) * ((43 * l2) ~/ 15238));
    final l3 =
        l2 -
        (((30 - j) ~/ 15) * ((17719 * j) ~/ 50)) -
        ((j ~/ 16) * ((15238 * j) ~/ 43)) +
        29;
    final m = (24 * l3) ~/ 709;
    final d = l3 - (709 * m) ~/ 24;
    final y = 30 * n + j - 30;
    return (year: y, month: m, day: d);
  }

  int _daysUntilEvent(_IslamicEvent event, ({int year, int month, int day}) nowHijri) {
    const monthLengths = <int>[30, 29, 30, 29, 30, 29, 30, 29, 30, 29, 30, 29];

    int dayOfYear(int month, int day) {
      var sum = day;
      for (var i = 0; i < month - 1; i++) {
        sum += monthLengths[i];
      }
      return sum;
    }

    final nowDay = dayOfYear(nowHijri.month, nowHijri.day);
    final targetDay = dayOfYear(event.hijriMonth, event.hijriDay);
    var diff = targetDay - nowDay;
    if (diff < 0) diff += 354;
    return diff;
  }

  @override
  Widget build(BuildContext context) {
    final hijri = _gregorianToHijri(_selectedDate);
    final hijriNow = _gregorianToHijri(DateTime.now());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final localeCode = Localizations.localeOf(context).languageCode;

    // Yaklaşan etkinlikleri sırala
    final sortedEvents = [..._events]..sort(
        (a, b) => _daysUntilEvent(a, hijriNow).compareTo(_daysUntilEvent(b, hijriNow)),
      );
    final nextEvent = sortedEvents.first;
    final daysToNext = _daysUntilEvent(nextEvent, hijriNow);

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
              AppText.of(context, 'islamicCalendar'),
              style: GoogleFonts.notoSerif(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: scheme.primary,
              ),
            ),
            centerTitle: true,
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Bugünün Hicri tarihi ─────────────────────────────────────
                _HijriDateCard(
                  hijri: hijri,
                  gregorianDate: _selectedDate,
                  isDark: isDark,
                  scheme: scheme,
                  localeCode: localeCode,
                  hijriMonthNames: _hijriMonthNames,
                  onPickDate: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(1950),
                      lastDate: DateTime(2100),
                      initialDate: _selectedDate,
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                ).animate().fade(duration: 500.ms).slideY(begin: 0.08, end: 0),

                const SizedBox(height: 16),

                // ── En yakın etkinlik ────────────────────────────────────────
                _NextEventCard(
                  event: nextEvent,
                  daysLeft: daysToNext,
                  isDark: isDark,
                ).animate().fade(duration: 400.ms, delay: 80.ms).slideY(begin: 0.08, end: 0),

                const SizedBox(height: 20),

                // ── Başlık ───────────────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.event_rounded, size: 16, color: Color(0xFF8B5CF6)),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Mübarek Gün ve Geceler',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ).animate().fade(duration: 400.ms, delay: 120.ms),

                const SizedBox(height: 12),

                // ── Etkinlik listesi ─────────────────────────────────────────
                ...sortedEvents.asMap().entries.map((entry) {
                  final i = entry.key;
                  final event = entry.value;
                  final daysLeft = _daysUntilEvent(event, hijriNow);
                  final reminded = _remindedEvents.contains(event.name);
                  return _EventCard(
                    event: event,
                    daysLeft: daysLeft,
                    reminded: reminded,
                    isDark: isDark,
                    localeCode: localeCode,
                    onToggleReminder: () {
                      setState(() {
                        if (reminded) {
                          _remindedEvents.remove(event.name);
                        } else {
                          _remindedEvents.add(event.name);
                        }
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            reminded
                                ? '${event.name}: ${AppText.of(context, "notificationDisabled")}'
                                : '${event.name}: ${AppText.of(context, "reminderSaved")}',
                            style: const TextStyle(fontFamily: 'Plus Jakarta Sans'),
                          ),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          margin: const EdgeInsets.all(16),
                        ),
                      );
                    },
                  ).animate().fade(
                    duration: 400.ms,
                    delay: Duration(milliseconds: 160 + i * 60),
                  ).slideY(begin: 0.06, end: 0);
                }),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _IslamicEvent {
  const _IslamicEvent({
    required this.name,
    required this.nameEn,
    required this.hijriDate,
    required this.hijriMonth,
    required this.hijriDay,
    required this.icon,
    required this.color,
    required this.description,
  });

  final String name;
  final String nameEn;
  final String hijriDate;
  final int hijriMonth;
  final int hijriDay;
  final IconData icon;
  final Color color;
  final String description;
}

// ─────────────────────────────────────────────────────────────────────────────

class _HijriDateCard extends StatelessWidget {
  const _HijriDateCard({
    required this.hijri,
    required this.gregorianDate,
    required this.isDark,
    required this.scheme,
    required this.localeCode,
    required this.hijriMonthNames,
    required this.onPickDate,
  });

  final ({int year, int month, int day}) hijri;
  final DateTime gregorianDate;
  final bool isDark;
  final ColorScheme scheme;
  final String localeCode;
  final List<String> hijriMonthNames;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final monthName = hijriMonthNames[(hijri.month - 1).clamp(0, 11)];
    final gregorianStr = DateFormat('d MMMM y', localeCode).format(gregorianDate);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4338CA)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4338CA).withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: -20,
            child: Icon(
              Icons.calendar_month_rounded,
              size: 100,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.wb_sunny_rounded, size: 13, color: Color(0xFFC4B5FD)),
                    const SizedBox(width: 6),
                    Text(
                      'HİCRİ TAKVİM',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.0,
                        color: Color(0xFFC4B5FD),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: onPickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.date_range_rounded, size: 14, color: Colors.white70),
                            SizedBox(width: 5),
                            Text(
                              'Tarih Seç',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${hijri.day}',
                      style: GoogleFonts.notoSerif(
                        fontSize: 72,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            monthName,
                            style: GoogleFonts.notoSerif(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${hijri.year} H',
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFC4B5FD),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.today_rounded, size: 14, color: Colors.white60),
                      const SizedBox(width: 8),
                      Text(
                        'Miladi: $gregorianStr',
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _NextEventCard extends StatelessWidget {
  const _NextEventCard({
    required this.event,
    required this.daysLeft,
    required this.isDark,
  });

  final _IslamicEvent event;
  final int daysLeft;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: event.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: event.color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: event.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(event.icon, color: event.color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: event.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'SIRADAKI MÜBAREK GÜN',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  event.name,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  event.hijriDate,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    color: event.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: event.color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Text(
                  daysLeft == 0 ? 'Bugün!' : '$daysLeft',
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (daysLeft > 0)
                  const Text(
                    'gün',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 10,
                      color: Colors.white70,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _EventCard extends StatefulWidget {
  const _EventCard({
    required this.event,
    required this.daysLeft,
    required this.reminded,
    required this.isDark,
    required this.localeCode,
    required this.onToggleReminder,
  });

  final _IslamicEvent event;
  final int daysLeft;
  final bool reminded;
  final bool isDark;
  final String localeCode;
  final VoidCallback onToggleReminder;

  @override
  State<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<_EventCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? const Color(0xFF0F172A) : Colors.white;
    final eventName = widget.localeCode == 'tr' ? widget.event.name : widget.event.nameEn;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: widget.daysLeft == 0
                ? widget.event.color.withValues(alpha: 0.5)
                : widget.event.color.withValues(alpha: 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: widget.isDark
                  ? Colors.black.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: widget.event.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.event.icon, color: widget.event.color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eventName,
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.event.hijriDate,
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: widget.event.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _DaysLeftBadge(
                    daysLeft: widget.daysLeft,
                    color: widget.event.color,
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    size: 18,
                    color: widget.event.color.withValues(alpha: 0.6),
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.event.color.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.event.description,
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      color: widget.isDark ? Colors.white60 : const Color(0xFF374151),
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: widget.onToggleReminder,
                    style: FilledButton.styleFrom(
                      backgroundColor: widget.reminded
                          ? const Color(0xFF10B981).withValues(alpha: 0.12)
                          : widget.event.color.withValues(alpha: 0.1),
                      foregroundColor: widget.reminded
                          ? const Color(0xFF10B981)
                          : widget.event.color,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.reminded
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_none_rounded,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.reminded ? 'Hatırlatıcı Aktif' : 'Hatırlatıcı Ekle',
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DaysLeftBadge extends StatelessWidget {
  const _DaysLeftBadge({required this.daysLeft, required this.color});

  final int daysLeft;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (daysLeft == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'Bugün',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$daysLeft gün',
        style: TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
