import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../core/auth_service.dart';
import '../core/children_service.dart';
import '../core/plans_service.dart';
import '../widgets/glass_widgets.dart';
import 'children_screen.dart';
import '../core/freeze_service.dart';

bool _isAr(BuildContext c) => Localizations.localeOf(c).languageCode == 'ar';

String _fmtPrice(num p) {
  if (p == p.roundToDouble()) return p.toInt().toString();
  return p
      .toStringAsFixed(2)
      .replaceAll(RegExp(r'0+$'), '')
      .replaceAll(RegExp(r'\.$'), '');
}

String _durationLabel(BuildContext c, int n) {
  if (n == 1) return c.tr('oneMonth');
  if (n == 2) return c.tr('twoMonths');
  return '$n ${n <= 10 ? c.tr('unitMonths') : c.tr('unitMonth')}';
}

String _planLabel(BuildContext c, Plan p) {
  switch (p.kind) {
    case 'sessions':
      return '${p.sessions} ${c.tr('unitSession')} • ${_durationLabel(c, p.months)}';
    case 'service':
      return p.title(_isAr(c));
    default:
      return _durationLabel(c, p.months);
  }
}

String _fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class SubscriptionsTab extends StatefulWidget {
  const SubscriptionsTab({super.key});

  /// بيتحكم في الشاشة اللي تفتح: 0 = الباقات ، 1 = اشتراكاتي
  static final ValueNotifier<int> requestedView = ValueNotifier<int>(0);

  static void show(int view) {
    requestedView.value = -1; // عشان الإشعار يوصل حتى لو نفس القيمة
    requestedView.value = view;
  }

  @override
  State<SubscriptionsTab> createState() => _SubscriptionsTabState();
}

class _SubscriptionsTabState extends State<SubscriptionsTab> {
  int _view = 0; // 0 = الباقات ، 1 = اشتراكاتي
  String _club = 'men';
  bool _seeding = false;
  @override
  void initState() {
    super.initState();
    SubscriptionsTab.requestedView.addListener(_onRequestedView);
  }

  void _onRequestedView() {
    final v = SubscriptionsTab.requestedView.value;
    if (v >= 0 && mounted) setState(() => _view = v);
  }

  @override
  void dispose() {
    SubscriptionsTab.requestedView.removeListener(_onRequestedView);
    super.dispose();
  }

  Future<void> _seed() async {
    setState(() => _seeding = true);
    try {
      await PlansService.seed();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.tr('seedDone'))));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    }
    if (mounted) setState(() => _seeding = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              context.tr('tabSubs'),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        // تبديل: الباقات | اشتراكاتي
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
              _seg(context.tr('plansTab'), 0),
              _seg(context.tr('mySubsTab'), 1),
            ],
          ),
        ),
        Expanded(child: _view == 0 ? _plansView() : _mineView()),
      ],
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

  // ---------- الباقات ----------
  Widget _plansView() {
    return Column(
      children: [
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
          child: StreamBuilder<List<Plan>>(
            stream: PlansService.plansStream(_club),
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
                  child: CircularProgressIndicator(color: AppColors.gold),
                );
              }
              final plans = snap.data!.where((p) => p.active).toList();
              if (plans.isEmpty) return _emptyPlans();

              final groups = <String, List<Plan>>{};
              for (final p in plans) {
                groups.putIfAbsent(p.groupKey, () => []).add(p);
              }
              final ar = _isAr(context);
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
                              e.value.first.group(ar),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.goldLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            for (final p in e.value) _planRow(p),
                          ],
                        ),
                      ),
                    ),
                  Text(
                    context.tr('vatIncluded'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSoft),
                  ),
                ],
              );
            },
          ),
        ),
      ],
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

  Widget _planRow(Plan p) {
    final ar = _isAr(context);
    final note = p.note(ar);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _openConfirm(p),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_planLabel(context, p),
                      style: const TextStyle(fontSize: 14.5)),
                  if (note.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        note,
                        style: const TextStyle(
                            fontSize: 11.5, color: AppColors.success),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${_fmtPrice(p.price)} ${context.tr('sar')}',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 13, color: AppColors.textSoft),
          ],
        ),
      ),
    );
  }

  Widget _emptyPlans() {
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
                Text(context.tr('noPlans'),
                    style: const TextStyle(color: AppColors.textSoft)),
                if (isAdmin) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 260,
                    child: GoldButton(
                      text: context.tr('seedBtn'),
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

  void _openConfirm(Plan p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.navy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ConfirmSheet(plan: p, label: _planLabel(context, p)),
    );
  }

  // ---------- اشتراكاتي ----------
  // ---------- اشتراكاتي ----------
  Widget _mineView() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();
    return StreamBuilder<List<MySub>>(
      stream: FreezeService.mine(user.uid),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Text('${snap.error}', textDirection: TextDirection.ltr),
          );
        }
        if (!snap.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.gold),
          );
        }
        if (snap.data!.isEmpty) {
          return Center(
            child: Text(context.tr('noSubs'),
                style: const TextStyle(color: AppColors.textSoft)),
          );
        }
        final subs = [...snap.data!]..sort((a, b) =>
            (b.sub.createdAt ?? DateTime.now())
                .compareTo(a.sub.createdAt ?? DateTime.now()));
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            for (final m in subs)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SubCard(
                  my: m,
                  onRenew: () => setState(() => _view = 0),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// عدد الأيام (بالتاريخ فقط) بين النهاردة وتاريخ الانتهاء
int _daysLeft(DateTime end) {
  final n = DateTime.now();
  final a = DateTime.utc(n.year, n.month, n.day);
  final b = DateTime.utc(end.year, end.month, end.day);
  return b.difference(a).inDays;
}

/// تأكيد وتنفيذ التجميد (مرة واحدة، أسبوع)
Future<void> _confirmFreeze(BuildContext context, MySub m) async {
  final messenger = ScaffoldMessenger.of(context);
  final done = context.tr('fzDone');
  final err = context.tr('fzError');
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.navy,
      title: Text(ctx.tr('fzFreeze')),
      content: Text(ctx.tr('fzAsk')),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(ctx.tr('fzCancel')),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(ctx.tr('fzConfirm'),
              style: const TextStyle(color: AppColors.gold)),
        ),
      ],
    ),
  );
  if (ok != true) return;
  try {
    await FreezeService.freeze(m);
    messenger.showSnackBar(SnackBar(content: Text(done)));
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(err)));
  }
}

// ---------- كارت اشتراك ----------
class _SubCard extends StatelessWidget {
  final MySub my;
  final VoidCallback onRenew;
  const _SubCard({required this.my, required this.onRenew});

  Sub get sub => my.sub;

  @override
  Widget build(BuildContext context) {
    final ar = _isAr(context);
    final title = sub.kind == 'service'
        ? (ar ? sub.titleAr : sub.titleEn)
        : (ar ? sub.groupAr : sub.groupEn);

    String detail;
    if (sub.kind == 'sessions') {
      detail =
      '${sub.sessions} ${context.tr('unitSession')} • ${_durationLabel(context, sub.months)}';
    } else if (sub.kind == 'service') {
      detail = '';
    } else {
      detail = _durationLabel(context, sub.months);
    }

    final statusMap = <String, (String, Color)>{
      'pending': ('statusPending', AppColors.gold),
      'active': ('statusActive', AppColors.success),
      'expired': ('statusExpired', AppColors.danger),
      'frozen': ('statusFrozen', AppColors.kids),
      'cancelled': ('statusCancelled', AppColors.textSoft),
    };
    final eff = sub.effectiveStatus;
    final key = (my.isFrozen && eff == 'active') ? 'frozen' : eff;
    final st = statusMap[key] ?? statusMap['pending']!;

    final isActive = eff == 'active' && sub.endDate != null;
    final left = sub.endDate == null ? 0 : _daysLeft(sub.endDate!);
    final soon = isActive && left <= 7;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: st.$2.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  context.tr(st.$1),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: st.$2,
                  ),
                ),
              ),
            ],
          ),
          if (sub.childName.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.child_care_rounded,
                    size: 18, color: AppColors.goldLight),
                const SizedBox(width: 6),
                Text(
                  sub.childName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.goldLight),
                ),
              ],
            ),
          ],
          if (detail.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(detail, style: const TextStyle(color: AppColors.textSoft)),
          ],
          const SizedBox(height: 6),
          Text(
            '${_fmtPrice(sub.price)} ${context.tr('sar')}',
            style: const TextStyle(
                fontWeight: FontWeight.w800, color: AppColors.gold),
          ),
          if (sub.endDate != null) ...[
            const SizedBox(height: 6),
            Text(
              '${context.tr('endsOn')}: ${_fmtDate(sub.endDate!)}',
              style: const TextStyle(fontSize: 12.5),
            ),
          ],
          if (isActive) ...[
            const SizedBox(height: 4),
            Text(
              left <= 0
                  ? context.tr('fzLastDay')
                  : context.tr('fzDaysLeft').replaceAll('{n}', '$left'),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: soon ? AppColors.gold : AppColors.success,
              ),
            ),
          ],
          if (my.isFrozen) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.ac_unit_rounded,
                    size: 15, color: AppColors.kids),
                const SizedBox(width: 6),
                Text(
                  '${context.tr('fzFrozenUntil')} ${_fmtDate(my.frozenUntil!)}',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.kids),
                ),
              ],
            ),
          ],
          if (sub.kind == 'sessions' && sub.status == 'active') ...[
            const SizedBox(height: 4),
            Text(
              '${context.tr('sessionsLeft')}: ${sub.sessionsLeft}',
              style: const TextStyle(fontSize: 12.5),
            ),
          ],
          if (my.canFreeze || soon || eff == 'expired') ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (my.canFreeze)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.goldLight,
                      side: const BorderSide(color: AppColors.goldLight),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => _confirmFreeze(context, my),
                    icon: const Icon(Icons.ac_unit_rounded, size: 16),
                    label: Text(context.tr('fzFreeze')),
                  ),
                if ((soon && !my.isFrozen) || eff == 'expired')
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.navyDeep,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: onRenew,
                    child: Text(context.tr('fzRenew')),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
// ---------- شاشة تأكيد الاشتراك ----------
class _ConfirmSheet extends StatefulWidget {
  final Plan plan;
  final String label;
  const _ConfirmSheet({required this.plan, required this.label});

  @override
  State<_ConfirmSheet> createState() => _ConfirmSheetState();
}

class _ConfirmSheetState extends State<_ConfirmSheet> {
  bool _loading = false;
  Child? _child;
  String _pay = 'cash';

  bool get _isKids => widget.plan.clubId == 'kids';

  Future<void> _confirm() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final sent = context.tr('requestSent');
    final fail = context.tr('errGeneric');
    setState(() => _loading = true);
    try {
      final name = FirebaseAuth.instance.currentUser?.displayName ?? '';
      if (_isKids) {
        await ChildrenService.requestKidsSubscription(
          plan: widget.plan,
          child: _child!,
          parentName: name,
          paymentMethod: _pay,
        );
      } else {
        await PlansService.requestSubscription(
          plan: widget.plan,
          memberName: name,
          paymentMethod: _pay,
        );
      }
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(sent)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(fail)));
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _payChip(String id, String label, {bool enabled = true}) {
    final sel = _pay == id;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: GestureDetector(
        onTap: enabled ? () => setState(() => _pay = id) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: sel ? AppColors.gold.withValues(alpha: 0.18) : AppColors.glass,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: sel ? AppColors.gold : AppColors.glassBorder,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: sel ? AppColors.goldLight : Colors.white,
                ),
              ),
              if (!enabled)
                Text(
                  context.tr('soon'),
                  style: const TextStyle(
                      fontSize: 10.5, color: AppColors.textSoft),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _paymentPicker() {
    final ar = _isAr(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('payMethod'),
          style: const TextStyle(fontSize: 12.5, color: AppColors.textSoft),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _payChip('cash', context.tr('payCash')),
            _payChip('pos', context.tr('payPos')),
            _payChip('applepay', 'Apple Pay', enabled: false),
            _payChip('tamara', ar ? 'تمارا' : 'Tamara', enabled: false),
          ],
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _childPicker() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return StreamBuilder<List<Child>>(
      stream: ChildrenService.myChildren(uid),
      builder: (context, snap) {
        final list = snap.data ?? const <Child>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('chooseChild'),
              style: const TextStyle(fontSize: 12.5, color: AppColors.textSoft),
            ),
            const SizedBox(height: 8),
            if (list.isEmpty)
              Text(
                context.tr('noChildren'),
                style: const TextStyle(color: AppColors.gold),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in list)
                    GestureDetector(
                      onTap: () => setState(() => _child = c),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: _child?.id == c.id
                              ? AppColors.gold.withValues(alpha: 0.18)
                              : AppColors.glass,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _child?.id == c.id
                                ? AppColors.gold
                                : AppColors.glassBorder,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: _child?.id == c.id
                                    ? AppColors.goldLight
                                    : Colors.white,
                              ),
                            ),
                            Text(
                              '${c.age} ${context.tr('yearsUnit')} • ${c.category == '-' ? '' : c.category}',
                              style: const TextStyle(
                                  fontSize: 11.5, color: AppColors.textSoft),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => showChildForm(context),
              icon: const Icon(Icons.add_rounded, color: AppColors.goldLight),
              label: Text(
                context.tr('addChild'),
                style: const TextStyle(color: AppColors.goldLight),
              ),
            ),
            if (_child != null && _child!.category == '-')
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  context.tr('childOutOfRange'),
                  style:
                  const TextStyle(fontSize: 12.5, color: AppColors.danger),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.plan;
    final ar = _isAr(context);
    final group = p.kind == 'service' ? '' : p.group(ar);
    final canConfirm = !_isKids || _child != null;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('confirmTitle'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            if (group.isNotEmpty)
              Text(group,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.goldLight)),
            const SizedBox(height: 4),
            Text(widget.label, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 10),
            Text(
              '${_fmtPrice(p.price)} ${context.tr('sar')}',
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.gold),
            ),
            Text(context.tr('vatIncluded'),
                style:
                const TextStyle(fontSize: 12, color: AppColors.textSoft)),
            const SizedBox(height: 14),
            if (_isKids) _childPicker(),
            _paymentPicker(),
            Text(context.tr('payNote'), style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 6),
            Text(context.tr('policyNote'),
                style:
                const TextStyle(fontSize: 12.5, color: AppColors.textSoft)),
            const SizedBox(height: 18),
            Opacity(
              opacity: canConfirm ? 1 : 0.5,
              child: GoldButton(
                text: context.tr('confirmBtn'),
                loading: _loading,
                onTap: canConfirm ? _confirm : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
