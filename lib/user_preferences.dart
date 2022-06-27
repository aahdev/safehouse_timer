import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  static final UserPreferences _instance = UserPreferences._ctor();
  factory UserPreferences() {
    return _instance;
  }

  UserPreferences._ctor();

  SharedPreferences _prefs;

  init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // blackScreen
  get blackScreen {
    return _prefs.getBool('blackScreen') ?? false;
  }

  set blackScreen(bool value) {
    _prefs.setBool('blackScreen', value);
  }

  // vibration
  get vibration {
    return _prefs.getBool('vibration') ?? true;
  }

  set vibration(bool value) {
    _prefs.setBool('vibration', value);
  }

  // notifications
  get notifications {
    return _prefs.getBool('notifications') ?? false;
  }

  set notifications(bool value) {
    _prefs.setBool('notifications', value);
  }

  // stayAwake
  get stayAwake {
    return _prefs.getBool('stayAwake') ?? true;
  }

  set stayAwake(bool value) {
    _prefs.setBool('stayAwake', value);
  }
}
