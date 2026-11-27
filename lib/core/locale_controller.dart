import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// التحكم في لغة التطبيق وحفظها
class LocaleController {
  static final ValueNotifier<Locale> locale =
  ValueNotifier<Locale>(const Locale('ar'));

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString('lang');
      if (code == 'ar' || code == 'en') {
        locale.value = Locale(code!);
      }
    } catch (_) {}
  }

  static Future<void> toggle() async {
    final next = locale.value.languageCode == 'ar'
        ? const Locale('en')
        : const Locale('ar');
    locale.value = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lang', next.languageCode);
    } catch (_) {}
  }
}