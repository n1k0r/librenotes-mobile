import 'package:flutter/widgets.dart';
import 'package:librenotes/providers/storage.dart';
import 'package:librenotes/services/api.dart' as api;
import 'package:librenotes/services/cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Sync with ChangeNotifier {
  static final Sync _instance = Sync._init();

  String _server;
  String _token;
  DateTime _lastSync;

  bool get authorized => _token != null;
  String get server => _server;
  DateTime get lastSync => _lastSync;

  factory Sync() => _instance;

  Sync._init() {
    SharedPreferences.getInstance().then(
      (prefs) {
        _server = prefs.getString('server');
        _token = prefs.getString('token');

        var rawLastSync = prefs.getString('last_sync');
        if (rawLastSync != null) {
          _lastSync = DateTime.parse(rawLastSync);
        }

        notifyListeners();
      }
    );
  }

  Future<bool> auth(String server, String username, String password) async {
    String token = await api.auth(server, username, password);
    if (token == null) {
      return false;
    }

    _server = server;
    _token = token;

    SharedPreferences.getInstance().then(
      (prefs) {
        prefs.setString('server', server);
        prefs.setString('token', token);
      }
    );

    sync();

    notifyListeners();
    return true;
  }

  Future<bool> logout() async {
    _server = null;
    _token = null;
    _lastSync = null;

    SharedPreferences.getInstance().then(
      (prefs) {
        prefs.remove('server');
        prefs.remove('token');
        prefs.remove('last_sync');
      }
    );

    Cache().clear();

    notifyListeners();
    return true;
  }

  Future<bool> sync() async {
    if (!authorized) {
      return false;
    }

    var cache = Cache();
    final localData = await cache.getSyncData(_lastSync);

    var remoteData = await api.sync(server, _token, localData);
    if (remoteData == null) {
      return false;
    }

    await cache.applyData(remoteData);
    Storage().reload();

    _lastSync = DateTime.now();
    SharedPreferences.getInstance().then(
      (prefs) {
        prefs.setString('last_sync', _lastSync.toIso8601String());
      }
    );

    notifyListeners();
    return true;
  }
}
