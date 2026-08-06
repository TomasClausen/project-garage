import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive_ce.dart';
import '../core/formatters/date_formatter.dart';
import '../core/formatters/distance_formatter.dart';
import '../core/formatters/money_formatter.dart';
import '../models/app_preferences.dart';
import '../services/hive_service.dart';

class AppPreferencesProvider extends ChangeNotifier {
  AppPreferencesProvider({Box<AppPreferences>? box})
    : _box = box ?? Hive.box<AppPreferences>(HiveService.preferencesBox) {
    _preferences = _box.get(AppPreferences.defaultId) ?? const AppPreferences();
    if (!_box.containsKey(AppPreferences.defaultId)) {
      _box.put(AppPreferences.defaultId, _preferences);
    }
    _configure();
  }
  final Box<AppPreferences> _box;
  late AppPreferences _preferences;
  AppPreferences get preferences => _preferences;

  Future<void> save(AppPreferences value) async {
    _preferences = value;
    await _box.put(value.id, value);
    _configure();
    notifyListeners();
  }

  Future<void> refresh() async {
    _preferences = _box.get(AppPreferences.defaultId) ?? const AppPreferences();
    _configure();
    notifyListeners();
  }

  void _configure() {
    MoneyFormatter.configure(
      symbol: _preferences.currencySymbol,
      separator: _preferences.thousandsSeparator,
    );
    DateFormatter.configure(pattern: _preferences.dateFormat);
    DistanceFormatter.configure(unit: _preferences.distanceUnit);
  }
}
