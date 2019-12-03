import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings with ChangeNotifier {
  bool _dark = true;

  bool get dark => _dark;
  set dark(bool value) {
    _dark = value;
    notifyListeners();

    SharedPreferences.getInstance().then(
      (prefs) {
        prefs.setBool('dark', value);
      }
    );
  }

  Settings() {
    SharedPreferences.getInstance().then(
      (prefs) {
        bool value = prefs.getBool('dark') ?? true;
        _dark = value;
        notifyListeners();
      }
    );
  }
}
