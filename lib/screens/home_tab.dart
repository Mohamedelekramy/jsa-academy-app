import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../core/clubs.dart';
import '../core/links.dart';
import '../widgets/club_card.dart';
import '../widgets/soon.dart';
import 'club_screen.dart';
import 'schedule_screen.dart';
import 'subscriptions_tab.dart';
import 'events_screen.dart';

class HomeTab extends StatelessWidget {
  final ValueChanged<int> onSwitchTab;
  const HomeTab({super.key, required this.onSwitchTab});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        // الشريط العلوي
        Row(
          children: [
            _RoundIcon(
              icon: Icons.person_outline_rounded,
              onTap: () => onSwitchTab(3),
            ),
            const Spacer(),
            _RoundIcon(
              icon: Icons.notifications_none_rounded,
              badge: true,
              onTap: () => showSoon(context),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Center(child: Image.asset('assets/images/jsa_logo.png', width: 110)),
        const SizedBox(height: 14),

        // صورة المبنى (اختيارية)
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            'assets/images/building.jpg',
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),

        const SizedBox(height: 14),
        Text(
          context.tr('welcome'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          context.tr('tagline'),
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSoft),
        ),
        const SizedBox(height: 18),


        // كروت الأندية
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.05,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final club in allClubs)
              ClubCard(
                club: club,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ClubScreen(club: club)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),

        // أزرار سريعة
        Row(
          children: [
            _Quick(
              icon: Icons.person_rounded,
              label: context.tr('quickTrainers'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ScheduleScreen(initialView: 1),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _Quick(
              icon: Icons.calendar_month_rounded,
              label: context.tr('quickSchedule'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ScheduleScreen(initialView: 0),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _Quick(
              icon: Icons.credit_card_rounded,
              label: context.tr('mySubsTab'),
              onTap: () {
                SubscriptionsTab.show(1);
                onSwitchTab(1);
              },
            ),
            const SizedBox(width: 10),
            _Quick(
              icon: Icons.event_available_rounded,
              label: context.tr('quickBook'),
              onTap: () {
                SubscriptionsTab.show(0);
                onSwitchTab(1);
              },
            ),
          ],
        ),
        const SizedBox(height: 14),

        // بانر الفعاليات
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const EventsScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  AppColors.gold.withValues(alpha: 0.22),
                  AppColors.glass,
                ],
              ),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events_rounded,
                    size: 36, color: AppColors.gold),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    context.tr('eventsBanner'),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ),

        // أيقونات التواصل والموقع
        const SizedBox(height: 26),
        Text(
          context.tr('followUs'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppColors.textSoft),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SocialIcon(
              icon: FontAwesomeIcons.instagram,
              url: Links.instagram,
              tooltip: 'Instagram',
            ),
            const SizedBox(width: 14),
            _SocialIcon(
              icon: FontAwesomeIcons.facebook,
              url: Links.facebook,
              tooltip: 'Facebook',
            ),
            const SizedBox(width: 14),
            _SocialIcon(
              icon: FontAwesomeIcons.snapchat,
              url: Links.snapchat,
              tooltip: 'Snapchat',
            ),
            const SizedBox(width: 14),
            _SocialIcon(
              icon: FontAwesomeIcons.locationDot,
              url: Links.map,
              tooltip: context.tr('ourLocation'),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final FaIconData icon;
  final String url;
  final String tooltip;
  const _SocialIcon({
    required this.icon,
    required this.url,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => openUrl(url),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.glass,
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Center(
            child: FaIcon(icon, size: 20, color: AppColors.goldLight),
          ),
        ),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool badge;
  const _RoundIcon({
    required this.icon,
    required this.onTap,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.glass,
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            if (badge)
              PositionedDirectional(
                top: 10,
                end: 11,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Quick extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Quick({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          height: 88,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.glass,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.goldLight, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11.5, height: 1.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}