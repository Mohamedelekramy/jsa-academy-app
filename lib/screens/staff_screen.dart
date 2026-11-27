import 'package:flutter/material.dart';
import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../core/staff_service.dart';
import '../widgets/animated_background.dart';
import '../widgets/glass_widgets.dart';

bool _isAr(BuildContext c) => Localizations.localeOf(c).languageCode == 'ar';

String _fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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

String _clubLabel(BuildContext c, String id) {
  const map = {
    'men': 'clubMenShort',
    'women': 'clubWomenShort',
    'kids': 'clubKidsShort',
  };
  return c.tr(map[id] ?? 'clubMenShort');
}
String _payLabel(BuildContext c, String m) {
  switch (m) {
    case 'pos':
      return c.tr('payPos');
    case 'transfer':
      return c.tr('payTransfer');
    case 'applepay':
      return 'Apple Pay';
    case 'tamara':
      return _isAr(c) ? 'تمارا' : 'Tamara';
    default:
      return c.tr('payCash');
  }
}

/// اسم الباقة + مدتها
String _subLabel(BuildContext c, StaffSub s) {
  final ar = _isAr(c);
  if (s.kind == 'service') return ar ? s.titleAr : s.titleEn;
  final group = ar ? s.groupAr : s.groupEn;
  if (s.kind == 'sessions') {
    return '$group • ${s.sessions} ${c.tr('unitSession')}';
  }
  return '$group • ${_durationLabel(c, s.months)}';
}

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  int _tab = 0; // 0 = بانتظار التفعيل ، 1 = الفعّالة
  String _q = '';

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
                        context.tr('staffPanel'),
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const Icon(Icons.admin_panel_settings_rounded,
                        color: AppColors.goldLight),
                  ],
                ),
              ),
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
                    _seg(context.tr('tabPending'), 0),
                    _seg(context.tr('tabActive'), 1),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  onChanged: (v) => setState(() => _q = v.trim()),
                  decoration: InputDecoration(
                    hintText: context.tr('searchMember'),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.textSoft),
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<List<StaffSub>>(
                  stream: StaffService.byStatus(_tab == 0 ? 'pending' : 'active'),
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
                    var list = snap.data!
                        .where((s) => s.memberName
                        .toLowerCase()
                        .contains(_q.toLowerCase()))
                        .toList();

                    if (_tab == 0) {
                      // الأحدث أولاً
                      list.sort((a, b) => (b.createdAt ?? DateTime.now())
                          .compareTo(a.createdAt ?? DateTime.now()));
                    } else {
                      // الأقرب انتهاءً أولاً
                      list.sort((a, b) {
                        final ea = a.endDate ?? DateTime(2100);
                        final eb = b.endDate ?? DateTime(2100);
                        return ea.compareTo(eb);
                      });
                    }

                    if (list.isEmpty) {
                      return Center(
                        child: Text(
                          context.tr(_tab == 0 ? 'noPending' : 'noActive'),
                          style: const TextStyle(color: AppColors.textSoft),
                        ),
                      );
                    }
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      children: [
                        for (final s in list)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _tab == 0
                                ? _PendingCard(sub: s)
                                : _ActiveCard(sub: s),
                          ),
                      ],
                    );
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
    final sel = _tab == i;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = i),
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
}

/// رقم جوال العضو (بيتجاب مرة واحدة)
class _PhoneText extends StatefulWidget {
  final String uid;
  const _PhoneText({required this.uid});

  @override
  State<_PhoneText> createState() => _PhoneTextState();
}

class _PhoneTextState extends State<_PhoneText> {
  late final Future<String> _f = StaffService.phoneOf(widget.uid);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _f,
      builder: (context, snap) {
        final phone = snap.data ?? '';
        if (phone.isEmpty) return const SizedBox.shrink();
        return Text(
          phone,
          textDirection: TextDirection.ltr,
          style: const TextStyle(fontSize: 12.5, color: AppColors.textSoft),
        );
      },
    );
  }
}

class _ClubChip extends StatelessWidget {
  final String clubId;
  const _ClubChip({required this.clubId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _clubLabel(context, clubId),
        style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppColors.goldLight),
      ),
    );
  }
}

// ---------- طلب بانتظار التفعيل ----------
class _PendingCard extends StatelessWidget {
  final StaffSub sub;
  const _PendingCard({required this.sub});

  Future<void> _reject(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final done = context.tr('rejected');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.navy,
        content: Text(ctx.tr('rejectConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.tr('cancelBtn')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.tr('yes'),
                style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await StaffService.reject(sub.id);
    messenger.showSnackBar(SnackBar(content: Text(done)));
  }

  void _activate(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.navy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ActivateSheet(sub: sub),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  sub.memberName.isEmpty ? '—' : sub.memberName,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              _ClubChip(clubId: sub.clubId),
            ],
          ),
          _PhoneText(uid: sub.uid),
          const SizedBox(height: 8),
          Text(_subLabel(context, sub)),
          const SizedBox(height: 4),
          Text(
            '${_fmtPrice(sub.price)} ${context.tr('sar')}',
            style: const TextStyle(
                fontWeight: FontWeight.w800, color: AppColors.gold),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${context.tr('payMethod')}: ${_payLabel(context, sub.paymentMethod)}',
              style: const TextStyle(fontSize: 12.5),
            ),
          ),
          if (sub.createdAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${context.tr('requestedOn')}: ${_fmtDate(sub.createdAt!)}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSoft),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _reject(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26)),
                  ),
                  child: Text(context.tr('rejectBtn')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: GoldButton(
                  text: context.tr('activateBtn'),
                  onTap: () => _activate(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------- اشتراك فعّال ----------
class _ActiveCard extends StatelessWidget {
  final StaffSub sub;
  const _ActiveCard({required this.sub});

  @override
  Widget build(BuildContext context) {
    final end = sub.endDate;
    int? left;
    if (end != null) {
      left = end.difference(DateTime.now()).inDays;
    }
    Color color = AppColors.success;
    if (left != null && left < 0) {
      color = AppColors.danger;
    } else if (left != null && left <= 7) {
      color = AppColors.gold;
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  sub.memberName.isEmpty ? '—' : sub.memberName,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              if (sub.isFrozen) ...[
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.kids.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.ac_unit_rounded,
                          size: 14, color: AppColors.kids),
                      const SizedBox(width: 4),
                      Text(
                        context.tr('fzFrozen'),
                        style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.kids),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
              ],
              _ClubChip(clubId: sub.clubId),
            ],
          ),
          _PhoneText(uid: sub.uid),
          const SizedBox(height: 8),
          Text(_subLabel(context, sub)),
          if (end != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${context.tr('endsOn')}: ${_fmtDate(end)}',
                  style: const TextStyle(fontSize: 13),
                ),
                const Spacer(),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    left! < 0
                        ? context.tr('statusExpired')
                        : '${context.tr('daysLeft')} $left ${context.tr('dayUnit')}',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color),
                  ),
                ),
              ],
            ),
          ],
          // معلومات التجميد
          if (sub.isFrozen && sub.frozenUntil != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.ac_unit_rounded,
                    size: 15, color: AppColors.kids),
                const SizedBox(width: 6),
                Text(
                  '${context.tr('fzFrozenUntil')} ${_fmtDate(sub.frozenUntil!)}',
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.kids),
                ),
              ],
            ),
          ],
          if (sub.freezeUsed && sub.frozenFrom != null) ...[
            const SizedBox(height: 4),
            Text(
              '${context.tr('fzUsedOn')} ${_fmtDate(sub.frozenFrom!)}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSoft),
            ),
          ],
        ],
      ),
    );
  }
}
// ---------- شاشة تفعيل الاشتراك ----------
class _ActivateSheet extends StatefulWidget {
  final StaffSub sub;
  const _ActivateSheet({required this.sub});

  @override
  State<_ActivateSheet> createState() => _ActivateSheetState();
}

class _ActivateSheetState extends State<_ActivateSheet> {
  DateTime _start = DateTime.now();
  late String _method =
  const ['cash', 'pos', 'transfer'].contains(widget.sub.paymentMethod)
      ? widget.sub.paymentMethod
      : 'cash';
  bool _loading = false;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _start = d);
  }

  Future<void> _confirm() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final ok = context.tr('activated');
    final fail = context.tr('errGeneric');
    setState(() => _loading = true);
    try {
      await StaffService.activate(widget.sub, _start, _method);
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(ok)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(fail)));
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _methodChip(String id, String label) {
    final sel = _method == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _method = id),
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
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: sel ? AppColors.goldLight : AppColors.textSoft,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.sub;
    DateTime? end;
    if (s.kind != 'service') {
      end = StaffService.addMonths(
          DateTime(_start.year, _start.month, _start.day), s.months);
    }

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('activateTitle'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(
              s.memberName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(_subLabel(context, s)),
            const SizedBox(height: 4),
            Text(
              '${_fmtPrice(s.price)} ${context.tr('sar')}',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.gold),
            ),
            const SizedBox(height: 16),
            Text(context.tr('startDate'),
                style:
                const TextStyle(fontSize: 12.5, color: AppColors.textSoft)),
            const SizedBox(height: 6),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _pickDate,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.glass,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded,
                        color: AppColors.goldLight, size: 20),
                    const SizedBox(width: 10),
                    Text(_fmtDate(_start)),
                    if (end != null) ...[
                      const Spacer(),
                      Text(
                        '${context.tr('endsOn')}: ${_fmtDate(end)}',
                        style: const TextStyle(
                            fontSize: 12.5, color: AppColors.textSoft),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(context.tr('payMethod'),
                style:
                const TextStyle(fontSize: 12.5, color: AppColors.textSoft)),
            const SizedBox(height: 6),
            Row(
              children: [
                _methodChip('cash', context.tr('payCash')),
                const SizedBox(width: 8),
                _methodChip('pos', context.tr('payPos')),
                const SizedBox(width: 8),
                _methodChip('transfer', context.tr('payTransfer')),
              ],
            ),
            const SizedBox(height: 20),
            GoldButton(
              text: context.tr('activateBtn'),
              loading: _loading,
              onTap: _confirm,
            ),
          ],
        ),
      ),
    );
  }
}