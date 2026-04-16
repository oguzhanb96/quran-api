import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/localization/app_language.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/settings/app_preferences.dart';

class NotificationSchedulePage extends StatefulWidget {
  const NotificationSchedulePage({super.key});

  @override
  State<NotificationSchedulePage> createState() =>
      _NotificationSchedulePageState();
}

class _NotificationSchedulePageState extends State<NotificationSchedulePage> {
  static const _prayers = <String>[
    'imsak',
    'gunes',
    'ogle',
    'ikindi',
    'aksam',
    'yatsi',
  ];

  static const _cities = <String>[
    'Istanbul',
    'Ankara',
    'Izmir',
    'Konya',
    'Bursa',
    'Adana',
    'Gaziantep',
    'Diyarbakir',
    'Makkah',
    'Medina',
    'Riyadh',
    'Cairo',
    'Jakarta',
    'Kuala Lumpur',
    'Karachi',
    'Doha',
    'Dubai',
  ];

  List<String> get _cityOptions => [..._cities, 'Diğer (Manuel)'];
  String get _dropdownValue =>
      _cities.contains(_city) ? _city : 'Diğer (Manuel)';

  final TextEditingController _inputController = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  String _city = 'Istanbul';
  Map<String, bool> _onTime = {for (final p in _prayers) p: true};
  Map<String, bool> _before = {for (final p in _prayers) p: true};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final city = await AppPreferences.getSelectedCity();
    final onTime = await AppPreferences.loadOnTimeToggles();
    final before = await AppPreferences.loadBeforeToggles();

    if (!mounted) return;

    setState(() {
      _city = city ?? 'Istanbul';
      _inputController.text = _cities.contains(_city) ? '' : _city;
      _onTime = onTime;
      _before = before;
      _loading = false;
    });
  }

  void _setOnTime(String prayerKey, bool value) {
    setState(() {
      _onTime = {..._onTime, prayerKey: value};
    });
  }

  void _setBefore(String prayerKey, bool value) {
    setState(() {
      _before = {..._before, prayerKey: value};
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final notificationTitle = AppText.of(context, 'notification');
    final prayerLabels = <String, String>{
      for (final prayer in _prayers)
        prayer: AppText.of(context, 'prayer_$prayer'),
    };
    final scheduleSavedText = AppText.of(context, 'scheduleSaved');
    final messenger = ScaffoldMessenger.of(context);

    await AppPreferences.setSelectedCity(_city);
    await AppPreferences.saveToggles(onTime: _onTime, before: _before);
    await NotificationService().requestPermissions();
    await NotificationService().cancelAll();
    final now = DateTime.now();
    var notificationId = 1000;
    for (final prayer in _prayers) {
      if (_onTime[prayer] ?? false) {
        await NotificationService().schedulePrayerNotification(
          id: notificationId++,
          title: notificationTitle,
          body: '${prayerLabels[prayer] ?? prayer} vakti',
          scheduledDate: now.add(Duration(minutes: notificationId % 60 + 1)),
        );
      }
    }

    if (!mounted) return;
    setState(() => _saving = false);

    messenger.showSnackBar(SnackBar(content: Text(scheduleSavedText)));
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    if (_loading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF020617) : const Color(0xFFFBF9F5),
        body: const Center(child: CircularProgressIndicator()),
      );
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
            title: Text(
              AppText.of(context, 'scheduleTitle'),
              style: GoogleFonts.notoSerif(fontWeight: FontWeight.bold),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
          Text(
            AppText.of(context, 'setupLocation'),
            style: GoogleFonts.notoSerif(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: ValueKey(_dropdownValue),
            initialValue: _dropdownValue,
            items: _cityOptions
                .map((city) => DropdownMenuItem(value: city, child: Text(city)))
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                if (value != 'Diğer (Manuel)') {
                  _city = value;
                } else {
                  _city = _inputController.text.isNotEmpty
                      ? _inputController.text
                      : 'Diğer (Manuel)';
                }
              });
            },
          ),
          if (_dropdownValue == 'Diğer (Manuel)') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _inputController,
              decoration: InputDecoration(
                labelText: AppText.of(context, 'cityName'),
                hintText: AppText.of(context, 'setupCityHint'),
                border: const OutlineInputBorder(),
              ),
              onChanged: (val) {
                _city = val.trim();
              },
            ),
          ],
          const SizedBox(height: 18),
          Divider(color: scheme.outlineVariant),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  AppText.of(context, 'setupPrayerTime'),
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              Text(
                AppText.of(context, 'setupOnTime'),
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                AppText.of(context, 'setupBefore'),
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._prayers.map(
            (p) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      AppText.of(context, 'prayer_$p'),
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  Switch(
                    value: _onTime[p] ?? true,
                    onChanged: _saving ? null : (value) => _setOnTime(p, value),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: _before[p] ?? true,
                    onChanged: _saving ? null : (value) => _setBefore(p, value),
                  ),
                ],
              ),
            ),
          ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      AppText.of(context, 'setupDone'),
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
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
