import '../di/service_locator.dart';
import 'storage_service.dart';

class AppDateService {
  static const String _keyInstallDate = 'install_date';

  /// Returns the install date, saving it on first call.
  static Future<DateTime> getInstallDate() async {
    final storage = sl<StorageService>();
    final saved = storage.getString(_keyInstallDate);
    if (saved != null) {
      return DateTime.parse(saved).toUtc();
    }
    final now = DateTime.now().toUtc();
    final key =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    await storage.setString(_keyInstallDate, key);
    return DateTime.parse(key).toUtc();
  }

  /// Returns the number of full days since the app was installed.
  static Future<int> getDaysSinceInstall() async {
    final installDate = await getInstallDate();
    final today = DateTime.now().toUtc();
    final diff = DateTime.utc(today.year, today.month, today.day)
        .difference(DateTime.utc(installDate.year, installDate.month, installDate.day));
    return diff.inDays;
  }

  /// Returns today's key as YYYY-MM-DD.
  static String todayKey() {
    final now = DateTime.now().toUtc();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
