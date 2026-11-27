import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../core/auth_service.dart';
import '../core/schedule_service.dart';
import '../widgets/animated_background.dart';
import '../widgets/glass_widgets.dart';

bool _isAr(BuildContext c) => Localizations.localeOf(c).languageCode == 'ar';

/// الوقت الحالي في السعودية (UTC+3) بالدقائق من منتصف الليل
int _academyNowMin() {
  final t = DateTime.now().toUtc().add(const Duration(hours: 3));
  return t.hour * 60 + t.minute;
}

String _fmtMin(BuildContext c, int m) {
  final ar = _isAr(c);
  if (m >= 1440) return c.tr('midnight');
  final h24 = (m ~/ 60) % 24;
  final min = m % 60;
  final suffix = h24 >= 12 ? (ar ? 'م' : 'PM') : (ar ? 'ص' : 'AM');
  var h = h24 % 12;
  if (h == 0) h = 12;
  return '$h:${min.toString().padLeft(2, '0')} $suffix';
}

String _range(BuildContext c, ScheduleItem i) {
  final a = _fmtMin(c, i.startMin);
  final b = _fmtMin(c, i.endMin);
  return _isAr(c) ? '${c.tr('timeFrom')} $a ${c.tr('timeTo')} $b' : '$a - $b';
}

class ScheduleScreen extends StatefulWidget {
  /// 0 = الجدول ، 1 = المدربون
  final int initialView;
  const ScheduleScreen({super.key, this.initialView = 0});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late int _view = widget.initialView;
  String _club = 'men';
  bool _seeding = false;

  Future<void> _seed() async {
    setState(() => _seeding = true);
    try {
      await ScheduleService.seed();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
    if (mounted) setState(() => _seeding = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
                child: Row(
                  children: [
                    const BackButton(),
                    Expanded(
                      child: Text(
                        context.tr('scheduleTitle'),
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const Icon(Icons.calendar_month_rounded,
                        color: AppColors.goldLight),
                  ],
                ),
              ),
              // تبديل: الجدول | المدربون
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.glass,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Row(
                  children: [
                    _seg(context.tr('viewSchedule'), 0),
                    _seg(context.tr('viewTrainers'), 1),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _clubChip('men', context.tr('clubMenShort')),
                    const SizedBox(width: 8),
                    _clubChip('women', context.tr('clubWomenShort')),
                    const SizedBox(width: 8),
                    _clubChip('kids', context.tr('clubKidsShort')),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: StreamBuilder<List<ScheduleItem>>(
                  stream: ScheduleService.byClub(_club),
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text('${snap.error}',
                              textDirection: TextDirection.ltr,
                              textAlign: TextAlign.center),
                        ),
                      );
                    }
                    if (!snap.hasData) {
                      return const Center(
                        child:
                        CircularProgressIndicator(color: AppColors.gold),
                      );
                    }
                    final items = snap.data!;
                    if (items.isEmpty) return _empty();
                    return _view == 0
                        ? _scheduleView(items)
                        : _trainersView(items);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _seg(String label, int i) {
    final sel = _view == i;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _view = i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: sel ? AppGradients.gold : null,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: sel ? AppColors.navyDeep : AppColors.textSoft,
            ),
          ),
        ),
      ),
    );
  }

  Widget _clubChip(String id, String label) {
    final sel = _club == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _club = id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: sel ? AppColors.gold.withValues(alpha: 0.18) : null,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: sel ? AppColors.gold : AppColors.glassBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: sel ? AppColors.goldLight : AppColors.textSoft,
            ),
          ),
        ),
      ),
    );
  }

  Widget _empty() {
    final user = FirebaseAuth.instance.currentUser;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: user == null ? null : AuthService.profileStream(user.uid),
          builder: (context, s) {
            final isAdmin = s.data?.data()?['role'] == 'admin';
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.tr('noSchedule'),
                    style: const TextStyle(color: AppColors.textSoft)),
                if (isAdmin) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 260,
                    child: GoldButton(
                      text: context.tr('seedScheduleBtn'),
                      loading: _seeding,
                      onTap: _seed,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _openBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        context.tr('openNow'),
        style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: AppColors.success),
      ),
    );
  }

  // ---------- الجدول (حسب القسم) ----------
  Widget _scheduleView(List<ScheduleItem> items) {
    final ar = _isAr(context);
    final now = _academyNowMin();
    final groups = <String, List<ScheduleItem>>{};
    for (final i in items) {
      groups.putIfAbsent(i.sectionKey, () => []).add(i);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        for (final e in groups.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.value.first.section(ar),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.goldLight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final i in e.value)
                    if (i.isFacility)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline_rounded,
                                size: 18, color: AppColors.success),
                            const SizedBox(width: 8),
                            Text(i.group(ar)),
                          ],
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (i.group(ar).isNotEmpty)
                              Text(
                                i.group(ar),
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.textSoft),
                              ),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    i.trainer(ar),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                                if (i.openAt(now)) ...[
                                  _openBadge(),
                                  const SizedBox(width: 8),
                                ],
                                Text(
                                  _range(context, i),
                                  style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.textSoft),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ),
        Text(
          context.tr('scheduleNote'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppColors.textSoft),
        ),
      ],
    );
  }

  // ---------- المدربون ----------
  Widget _trainersView(List<ScheduleItem> items) {
    final ar = _isAr(context);
    final now = _academyNowMin();
    final byTrainer = <String, List<ScheduleItem>>{};
    for (final i in items) {
      if (i.isFacility) continue;
      byTrainer.putIfAbsent(i.trainer(ar), () => []).add(i);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        for (final e in byTrainer.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor:
                        AppColors.gold.withValues(alpha: 0.2),
                        child: Text(
                          e.key.isEmpty ? '?' : e.key.characters.first,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.goldLight),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          e.key,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (e.value.any((i) => i.openAt(now))) _openBadge(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final i in e.value)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.circle,
                              size: 7, color: AppColors.goldLight),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              i.group(ar).isEmpty
                                  ? i.section(ar)
                                  : '${i.section(ar)} • ${i.group(ar)}',
                              style: const TextStyle(fontSize: 13.5),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _range(context, i),
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSoft),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        Text(
          context.tr('scheduleNote'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppColors.textSoft),
        ),
      ],
    );
  }
}