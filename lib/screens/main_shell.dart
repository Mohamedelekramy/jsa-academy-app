import 'package:flutter/material.dart';
import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../widgets/animated_background.dart';
import 'coming_soon_tab.dart';
import 'home_tab.dart';
import 'more_tab.dart';
import 'subscriptions_tab.dart';
import 'bookings_tab.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _index,
            children: [
              // 0: الأكاديمية
              HomeTab(onSwitchTab: _go),
              // 1: الاشتراكات
              const SubscriptionsTab(),
              // 2: حجوزاتي
              const BookingsTab(),
              // 3: المزيد
              MoreTab(onSwitchTab: _go),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.navyDeep.withValues(alpha: 0.96),
          border: const Border(top: BorderSide(color: AppColors.glassBorder)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                _navItem(Icons.home_rounded, context.tr('tabAcademy'), 0),
                _navItem(Icons.credit_card_rounded, context.tr('tabSubs'), 1),
                _navItem(
                    Icons.calendar_month_rounded, context.tr('tabBookings'), 2),
                _navItem(Icons.more_horiz_rounded, context.tr('tabMore'), 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int i) {
    final selected = _index == i;
    final color = selected ? AppColors.gold : AppColors.textSoft;
    return Expanded(
      child: InkWell(
        onTap: () => _go(i),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: selected ? 28 : 25),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}