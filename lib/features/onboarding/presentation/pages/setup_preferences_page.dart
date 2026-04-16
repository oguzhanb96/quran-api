import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_language.dart';
import '../../../../core/settings/app_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../prayer_times/presentation/viewmodels/prayer_times_viewmodel.dart';

class SetupPreferencesPage extends ConsumerStatefulWidget {
  const SetupPreferencesPage({super.key});

  @override
  ConsumerState<SetupPreferencesPage> createState() =>
      _SetupPreferencesPageState();
}

class _SetupPreferencesPageState extends ConsumerState<SetupPreferencesPage> {
  static const _prayers = [
    'imsak',
    'gunes',
    'ogle',
    'ikindi',
    'aksam',
    'yatsi',
  ];

  final _cityController = TextEditingController();
  final Map<String, bool> _onTime = {for (final p in _prayers) p: true};
  final Map<String, bool> _before = {for (final p in _prayers) p: true};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCity();
  }

  Future<void> _loadSavedCity() async {
    final saved = await AppPreferences.getSelectedCity();
    if (saved != null && saved.isNotEmpty && mounted) {
      _cityController.text = saved;
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: AppTheme.gradientBackground),
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                title: Text(
                  AppText.of(context, 'setupTitle'),
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8F6F1),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            AppText.of(context, 'setupLocation'),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _cityController,
            decoration: InputDecoration(
              labelText: AppText.of(context, 'cityName'),
              hintText: 'Örn: Istanbul, Paris, Tokyo, Makkah',
              border: const OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
            enabled: !_isSaving,
          ),
          const SizedBox(height: 20),
          Text(
            AppText.of(context, 'setupNotifications'),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: Text(AppText.of(context, 'setupPrayerTime'))),
              Text(AppText.of(context, 'setupOnTime')),
              const SizedBox(width: 26),
              Text(AppText.of(context, 'setupBefore')),
            ],
          ),
          const SizedBox(height: 8),
          ..._prayers.map(
            (prayer) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(AppText.of(context, 'prayer_$prayer')),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: _onTime[prayer] ?? true,
                    onChanged: _isSaving
                        ? null
                        : (value) =>
                            setState(() => _onTime[prayer] = value),
                  ),
                  const SizedBox(width: 14),
                  Switch(
                    value: _before[prayer] ?? true,
                    onChanged: _isSaving
                        ? null
                        : (value) =>
                            setState(() => _before[prayer] = value),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: _isSaving ? null : _onSave,
            child: _isSaving
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(AppText.of(context, 'setupDone')),
          ),
        ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onSave() async {
    final city = _cityController.text.trim();
    if (city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppText.of(context, 'cityName'))),
      );
      return;
    }
    setState(() => _isSaving = true);

    final ok = await ref
        .read(prayerTimesProvider.notifier)
        .setManualCity(city);
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppText.of(context, 'cityNotFound'))),
      );
      return;
    }
    await AppPreferences.saveToggles(onTime: _onTime, before: _before);
    await AppPreferences.setOnboardingDone(true);
    if (!mounted) return;
    context.go('/home');
  }
}
