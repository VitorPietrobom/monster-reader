import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  PreferencesService._();
  static final instance = PreferencesService._();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  int get wpm => _prefs.getInt('wpm') ?? 250;
  double get fontSize => _prefs.getDouble('fontSize') ?? 48.0;
  String? get lastTextKey => _prefs.getString('lastTextKey');
  int? get lastWordIndex {
    final v = _prefs.getInt('lastWordIndex');
    return (v == null || v == 0) ? null : v;
  }

  Future<void> saveWpm(int v) => _prefs.setInt('wpm', v);
  Future<void> saveFontSize(double v) => _prefs.setDouble('fontSize', v);

  Future<void> saveBookmark(String key, int index) async {
    await _prefs.setString('lastTextKey', key);
    await _prefs.setInt('lastWordIndex', index);
  }
}
