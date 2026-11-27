import 'package:flutter/material.dart';

import '../core/app_strings.dart';
import '../core/app_theme.dart';

class ComingSoonTab extends StatelessWidget {
  final IconData icon;
  final String titleKey;
  const ComingSoonTab({super.key, required this.icon, required this.titleKey});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: AppColors.goldLight),
          const SizedBox(height: 16),
          Text(
            context.tr(titleKey),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            context.tr('soonSub'),
            style: const TextStyle(color: AppColors.textSoft),
          ),
        ],
      ),
    );
  }
}