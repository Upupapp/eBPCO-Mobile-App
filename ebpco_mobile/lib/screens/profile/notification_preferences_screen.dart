import 'package:flutter/material.dart';

import '../../core/api/citizen_api.dart';
import '../../core/api/problem.dart';
import '../../domain/models.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  final _api = CitizenApi.instance;
  NotificationPreferences? _prefs;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await _api.getNotificationPreferences();
      if (!mounted) return;
      setState(() => _prefs = prefs);
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() => _error = e.citizenMessage);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(String category, bool value) async {
    final current = _prefs;
    if (current == null) return;
    final updated = NotificationPreferences(
      categories: {...current.categories, category: value},
      quietHours: current.quietHours,
    );
    setState(() => _prefs = updated);
    await _save(updated);
  }

  Future<void> _save(NotificationPreferences prefs) async {
    setState(() => _saving = true);
    try {
      final result = await _api.replaceNotificationPreferences(prefs);
      if (!mounted) return;
      setState(() => _prefs = result);
    } on ApiError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.citizenMessage)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = _prefs;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
        actions: [if (_saving) const Padding(padding: EdgeInsets.only(right: 16), child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))))],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : prefs == null
                ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error ?? 'Could not load preferences.', style: AppTypography.error)))
                : ListView(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    children: [
                      Text('Choose which updates you want to be notified about.', style: AppTypography.body),
                      const SizedBox(height: AppSpacing.lg),
                      for (final category in notificationCategories)
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(notificationCategoryLabels[category] ?? category, style: AppTypography.bodyMedium),
                          value: prefs.categories[category] ?? true,
                          onChanged: (v) => _toggle(category, v),
                        ),
                    ],
                  ),
      ),
    );
  }
}
