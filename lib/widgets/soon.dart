import 'package:flutter/material.dart';

import '../core/app_strings.dart';

/// رسالة "قريباً"
void showSoon(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(context.tr('soon'))));
}