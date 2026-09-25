import 'package:shared_preferences/shared_preferences.dart';

/// Local-only "Remind me" flag. Nothing is pushed.
class LocalReminderStore {
  LocalReminderStore._();

  static String _key(String id) => 'teresa_catalog_reminder_$id';

  static Future<bool> read(String id) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key(id)) ?? false;
  }

  static Future<void> write(String id, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(id), value);
  }
}
