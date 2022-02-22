import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  static SharedPreferences? _preferences;

  static final _storage = FlutterSecureStorage();

  static const _timeago = 'timeago';

  static Future init() async =>
      _preferences = await SharedPreferences.getInstance();

  static Future setTimeOpt(bool opt) async {
    await _preferences?.setBool(_timeago, opt);
  }

  static bool? getTimeOpt() {
    return _preferences?.getBool(_timeago);
  }

  static Future removeTimeOpt() async {
    await _preferences?.remove(_timeago);
  }
}
