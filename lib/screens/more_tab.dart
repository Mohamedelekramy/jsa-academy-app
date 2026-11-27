import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../core/auth_service.dart';
import '../core/clubs.dart';
import '../core/links.dart';
import '../core/locale_controller.dart';
import '../widgets/glass_widgets.dart';
import '../widgets/soon.dart';
import '../widgets/user_avatar.dart';
import 'change_password_screen.dart';
import 'children_screen.dart';
import 'club_screen.dart';
import 'profile_screen.dart';
import 'schedule_screen.dart';
import 'staff_screen.dart';
import 'staff_bookings_screen.dart';
import 'events_screen.dart';

class MoreTab extends StatelessWidget {
  final ValueChanged<int> onSwitchTab;
  const MoreTab({super.key, required this.onSwitchTab});

  void _openClub(BuildContext context, Club club) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ClubScreen(club: club)),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // بطاقة المستخدم (بتفتح حسابي) + لوحة الموظفين لو الدور يسمح
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: user == null ? null : AuthService.profileStream(user.uid),
          builder: (context, snap) {
            final data = snap.data?.data();
            final name = (data?['name'] as String?) ?? user?.displayName ?? '';
            final role = (data?['role'] as String?) ?? 'member';
            final photo = data?['photoB64'] as String?;
            final roleKey = {
              'trainer': 'roleTrainer',
              'receptionist': 'roleReceptionist',
              'admin': 'roleAdmin',
            }[role] ??
                'roleMember';
            final isFront = role == 'admin' || role == 'receptionist';

            return Column(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => _push(context, const ProfileScreen()),
                  child: GlassCard(
                    child: Row(
                      children: [
                        UserAvatar(photoB64: photo, radius: 28),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user?.email ?? '',
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.textSoft),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  context.tr(roleKey),
                                  style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.goldLight),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.edit_outlined,
                            size: 20, color: AppColors.textSoft),
                      ],
                    ),
                  ),
                ),
                if (isFront) ...[
                  const SizedBox(height: 12),
                  _Item(
                    icon: Icons.admin_panel_settings_rounded,
                    label: context.tr('staffPanel'),
                    selected: true,
                    onTap: () => _push(context, const StaffScreen()),
                  ),
                  const SizedBox(height: 8),
                  _Item(
                    icon: Icons.event_note_rounded,
                    label: context.tr('bkStaffTitle'),
                    selected: true,
                    onTap: () => _push(context, const StaffBookingsScreen()),
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        Text(
          context.tr('menuTitle'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),

        _Item(
          icon: Icons.home_rounded,
          label: context.tr('menuHome'),
          onTap: () => onSwitchTab(0),
        ),
        _Item(
          icon: Icons.child_care_rounded,
          label: context.tr('clubKids'),
          onTap: () => _openClub(context, clubKids),
        ),
        _Item(
          icon: Icons.fitness_center_rounded,
          label: context.tr('clubMen'),
          onTap: () => _openClub(context, clubMen),
        ),
        _Item(
          icon: Icons.female_rounded,
          label: context.tr('clubWomen'),
          onTap: () => _openClub(context, clubWomen),
        ),
        _Item(
          icon: Icons.healing_rounded,
          label: context.tr('clubRehab'),
          onTap: () => _openClub(context, clubRehab),
        ),
        _Item(
          icon: Icons.child_care_rounded,
          label: context.tr('myChildren'),
          onTap: () => _push(context, const ChildrenScreen()),
        ),
        _Item(
          icon: Icons.credit_card_rounded,
          label: context.tr('tabSubs'),
          onTap: () => onSwitchTab(1),
        ),
        _Item(
          icon: Icons.calendar_month_rounded,
          label: context.tr('quickSchedule'),
          onTap: () => _push(context, const ScheduleScreen(initialView: 0)),
        ),
        _Item(
          icon: Icons.emoji_events_rounded,
          label: context.tr('eventsBanner'),
          onTap: () => _push(context, const EventsScreen()),
        ),
        _Item(
          icon: Icons.groups_rounded,
          label: context.tr('quickTrainers'),
          onTap: () => _push(context, const ScheduleScreen(initialView: 1)),
        ),
        _Item(
          icon: Icons.phone_rounded,
          label: context.tr('menuContact'),
          onTap: () => _showContact(context),
        ),
        const SizedBox(height: 10),
        _Item(
          icon: Icons.lock_reset_rounded,
          label: context.tr('changePassword'),
          onTap: () => _push(context, const ChangePasswordScreen()),
        ),
        _Item(
          icon: Icons.language_rounded,
          label: '${context.tr('menuLang')}: ${context.tr('langName')}',
          onTap: LocaleController.toggle,
        ),
        _Item(
          icon: Icons.logout_rounded,
          label: context.tr('logout'),
          danger: true,
          onTap: AuthService.logout,
        ),
      ],
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool danger;
  const _Item({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? AppColors.danger
        : (selected ? AppColors.gold : Colors.white);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.gold.withValues(alpha: 0.12)
                : AppColors.glass,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? AppColors.gold.withValues(alpha: 0.5)
                  : AppColors.glassBorder,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: AppColors.textSoft),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- تواصل معنا (واتساب + اتصال) ----------
void _showContact(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.navy,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      Widget tile(IconData icon, String label, String url) {
        return ListTile(
          leading: Icon(icon, color: AppColors.goldLight),
          title: Text(label),
          onTap: () {
            Navigator.of(ctx).pop();
            openUrl(url);
          },
        );
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ctx.tr('menuContact'),
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              tile(Icons.chat_rounded, ctx.tr('contactWhatsapp'),
                  Links.whatsapp),
              tile(Icons.call_rounded, ctx.tr('contactCall'), Links.phone),
            ],
          ),
        ),
      );
    },
  );
}