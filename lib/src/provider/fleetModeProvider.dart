import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FleetModeProvider extends ChangeNotifier {
  static const _prefsKey = 'fleet_mode';

  final SharedPreferences _prefs;
  String? _mode;

  FleetModeProvider._(this._prefs) {
    _mode = _prefs.getString(_prefsKey);
  }

  /// Initialize and return an instance (call before runApp).
  static Future<FleetModeProvider> init() async {
    final prefs = await SharedPreferences.getInstance();
    return FleetModeProvider._(prefs);
  }

  String? get mode => _mode;

  bool get hasMode => _mode != null && _mode!.isNotEmpty;

  Future<void> setMode(String newMode) async {
    if (newMode == _mode) return;
    _mode = newMode;
    await _prefs.setString(_prefsKey, newMode);
    notifyListeners();
  }

  Future<void> clearMode() async {
    _mode = null;
    await _prefs.remove(_prefsKey);
    notifyListeners();
  }
}
