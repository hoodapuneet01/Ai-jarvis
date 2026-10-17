import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Voice preferences. Saved on this phone when [prefs] is provided.
class AppSettings extends ChangeNotifier {
  AppSettings({
    SharedPreferences? prefs,
    double speechRate = 0.5,
    bool speakReplies = true,
  })  : _prefs = prefs,
        _speechRate = speechRate,
        _speakReplies = speakReplies;

  static Future<AppSettings> load() async {
    final p = await SharedPreferences.getInstance();
    return AppSettings(
      prefs: p,
      speechRate: p.getDouble('speechRate') ?? 0.5,
      speakReplies: p.getBool('speakReplies') ?? true,
    );
  }

  final SharedPreferences? _prefs;
  double _speechRate;
  bool _speakReplies;

  /// 0.2 (slow) to 1.0 (fast). 0.5 is normal.
  double get speechRate => _speechRate;
  bool get speakReplies => _speakReplies;

  void setSpeechRate(double v) {
    _speechRate = v.clamp(0.2, 1.0).toDouble();
    notifyListeners();
    _prefs?.setDouble('speechRate', _speechRate);
  }

  void setSpeakReplies(bool v) {
    _speakReplies = v;
    notifyListeners();
    _prefs?.setBool('speakReplies', v);
  }
}
