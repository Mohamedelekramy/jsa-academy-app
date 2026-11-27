import 'package:flutter/material.dart';

import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../core/booking_service.dart';
import '../widgets/glass_widgets.dart';

// ---------- أدوات مشتركة ----------
Color bookingStatusColor(String s) {
  switch (s) {
    case 'confirmed':
      return AppColors.success;
    case 'rejected':
    case 'cancelled':
      return AppColors.danger;
    case 'done':
      return AppColors.textSoft;
    default:
      return AppColors.gold;
  }
}

String formatBookingTime(BuildContext context, String t) {
  final h = int.tryParse(t.split(':').first) ?? 0;
  final h12 = h % 12 == 0 ? 12 : h % 12;
  final suffix = context.tr(h >= 12 ? 'bkPm' : 'bkAm');
  return '$h12:00 $suffix';
}

const _daysAr = [
  'الاثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
  'الأحد',
];
const _daysEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String weekdayName(BuildContext context, DateTime d) {
  final ar = Localizations.localeOf(context).languageCode == 'ar';
  return (ar ? _daysAr : _daysEn)[d.weekday - 1];
}

Future<bool> _ask(BuildContext context, String msg) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.navy,
      content: Text(msg),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(ctx.tr('bkNo')),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(ctx.tr('bkYes'),
              style: const TextStyle(color: AppColors.gold)),
        ),
      ],
    ),
  );
  return r ?? false;
}

/// بطاقة حجز (للعضو وللموظف)
class BookingCard extends StatelessWidget {
  final Booking b;
  final bool showMember;
  final List<Widget> actions;
  const BookingCard({
    super.key,
    required this.b,
    this.showMember = false,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final color = bookingStatusColor(b.status);
    final d = b.day;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('bkSvc_${b.service}'),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    context.tr('bkSt_${b.status}'),
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.event_rounded,
                    size: 16, color: AppColors.goldLight),
                const SizedBox(width: 6),
                Text('${weekdayName(context, d)}  ${b.date}'),
                const SizedBox(width: 14),
                const Icon(Icons.schedule_rounded,
                    size: 16, color: AppColors.goldLight),
                const SizedBox(width: 6),
                Text(formatBookingTime(context, b.time)),
              ],
            ),
            if (showMember && b.memberName.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.person_rounded,
                      size: 16, color: AppColors.textSoft),
                  const SizedBox(width: 6),
                  Expanded(child: Text(b.memberName)),
                ],
              ),
            ],
            if (b.trainerName.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                '${context.tr('bkTrainer')}: ${b.trainerName}',
                style: const TextStyle(color: AppColors.goldLight),
              ),
            ],
            if (b.note.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                '${context.tr('bkNoteLabel')}: ${b.note}',
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.textSoft),
              ),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 4, children: actions),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------- تاب حجوزاتي ----------
class BookingsTab extends StatelessWidget {
  const BookingsTab({super.key});

  Future<void> _cancel(BuildContext context, Booking b) async {
    final msg = context.tr('bkCancelAsk');
    final err = context.tr('bkError');
    final messenger = ScaffoldMessenger.of(context);
    if (!await _ask(context, msg)) return;
    try {
      await BookingService.setStatus(b.id, 'cancelled');
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  context.tr('bkTitle'),
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => showNewBooking(context),
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    gradient: AppGradients.gold,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add_rounded,
                          size: 20, color: AppColors.navyDeep),
                      const SizedBox(width: 4),
                      Text(
                        context.tr('bkNew'),
                        style: const TextStyle(
                            color: AppColors.navyDeep,
                            fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Booking>>(
            stream: BookingService.mine(),
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(child: Text(context.tr('bkError')));
              }
              if (!snap.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                );
              }
              final list = snap.data!;
              if (list.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.event_available_rounded,
                            size: 64, color: AppColors.goldLight),
                        const SizedBox(height: 12),
                        Text(
                          context.tr('bkEmpty'),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.tr('bkEmptyHint'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textSoft),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  for (final b in list)
                    BookingCard(
                      b: b,
                      actions: [
                        if (b.status == 'pending' || b.status == 'confirmed')
                          OutlinedButton(
                            onPressed: () => _cancel(context, b),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              side: const BorderSide(color: AppColors.danger),
                            ),
                            child: Text(context.tr('bkCancelBooking')),
                          ),
                      ],
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------- شيت حجز جديد ----------
Future<void> showNewBooking(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.navy,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _NewBookingSheet(),
  );
}

class _NewBookingSheet extends StatefulWidget {
  const _NewBookingSheet();

  @override
  State<_NewBookingSheet> createState() => _NewBookingSheetState();
}

class _NewBookingSheetState extends State<_NewBookingSheet> {
  static const _hours = [16, 17, 18, 19, 20, 21, 22, 23];

  String _service = bookingServices.first;
  int _day = 0;
  int? _hour;
  final _note = TextEditingController();
  bool _busy = false;

  late final DateTime _today = () {
    final n = academyNow();
    return DateTime(n.year, n.month, n.day);
  }();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  bool _hourAllowed(int h) {
    if (_day != 0) return true;
    return h > academyNow().hour;
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final pick = context.tr('bkPickTime');
    final sent = context.tr('bkSent');
    final err = context.tr('bkError');
    if (_hour == null) {
      messenger.showSnackBar(SnackBar(content: Text(pick)));
      return;
    }
    final date = DateTime(_today.year, _today.month, _today.day + _day);
    setState(() => _busy = true);
    try {
      await BookingService.create(
        service: _service,
        date: dateKey(date),
        time: '${_hour.toString().padLeft(2, '0')}:00',
        note: _note.text,
      );
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(sent)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(err)));
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _chip(String label, bool selected, VoidCallback? onTap) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? AppColors.navyDeep : Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      selected: selected,
      selectedColor: AppColors.gold,
      backgroundColor: AppColors.glass,
      side: const BorderSide(color: AppColors.glassBorder),
      showCheckmark: false,
      onSelected: onTap == null ? null : (_) => onTap(),
    );
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 8),
    child: Text(t,
        style: const TextStyle(
            fontWeight: FontWeight.w800, color: AppColors.goldLight)),
  );

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottom),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Text(
                  context.tr('bkNew'),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              _label(context.tr('bkService')),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in bookingServices)
                    _chip(context.tr('bkSvc_$s'), _service == s,
                            () => setState(() => _service = s)),
                ],
              ),
              _label(context.tr('bkDate')),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 14,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final d =
                    DateTime(_today.year, _today.month, _today.day + i);
                    return _chip(
                      '${weekdayName(context, d)} ${d.day}/${d.month}',
                      _day == i,
                          () => setState(() {
                        _day = i;
                        if (_hour != null && !_hourAllowed(_hour!)) {
                          _hour = null;
                        }
                      }),
                    );
                  },
                ),
              ),
              _label(context.tr('bkTime')),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final h in _hours)
                    _chip(
                      formatBookingTime(context, '$h:00'),
                      _hour == h,
                      _hourAllowed(h) ? () => setState(() => _hour = h) : null,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _note,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: context.tr('bkNote'),
                  labelStyle: const TextStyle(color: AppColors.textSoft),
                ),
              ),
              const SizedBox(height: 18),
              GoldButton(
                text: context.tr('bkSubmit'),
                loading: _busy,
                onTap: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}