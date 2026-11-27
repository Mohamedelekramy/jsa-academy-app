import 'package:flutter/material.dart';

import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../core/booking_service.dart';
import '../core/links.dart';
import '../widgets/animated_background.dart';
import 'bookings_tab.dart';

class StaffBookingsScreen extends StatefulWidget {
  const StaffBookingsScreen({super.key});

  @override
  State<StaffBookingsScreen> createState() => _StaffBookingsScreenState();
}

class _StaffBookingsScreenState extends State<StaffBookingsScreen> {
  String _filter = 'pending';

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _set(Booking b, String status, {String? trainer}) async {
    final err = context.tr('bkError');
    try {
      await BookingService.setStatus(b.id, status, trainerName: trainer);
    } catch (_) {
      _snack(err);
    }
  }

  Future<void> _confirm(Booking b) async {
    final ctrl = TextEditingController(text: b.trainerName);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.navy,
        title: Text(ctx.tr('bkConfirm')),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(labelText: ctx.tr('bkTrainerName')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(ctx.tr('bkClose')),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text),
            child: Text(ctx.tr('bkSave'),
                style: const TextStyle(color: AppColors.gold)),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (name == null) return;
    await _set(b, 'confirmed', trainer: name);
  }

  Widget _filterChip(String key, String label) {
    final sel = _filter == key;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: sel ? AppColors.navyDeep : Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      selected: sel,
      selectedColor: AppColors.gold,
      backgroundColor: AppColors.glass,
      side: const BorderSide(color: AppColors.glassBorder),
      showCheckmark: false,
      onSelected: (_) => setState(() => _filter = key),
    );
  }

  List<Widget> _actions(Booking b) {
    final list = <Widget>[];
    if (b.phone.isNotEmpty) {
      list.add(IconButton(
        visualDensity: VisualDensity.compact,
        icon: const Icon(Icons.call_rounded, color: AppColors.goldLight),
        onPressed: () => openUrl('tel:${b.phone}'),
      ));
    }
    if (b.status == 'pending') {
      list.add(FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: Colors.white,
        ),
        onPressed: () => _confirm(b),
        child: Text(context.tr('bkConfirm')),
      ));
      list.add(OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          side: const BorderSide(color: AppColors.danger),
        ),
        onPressed: () => _set(b, 'rejected'),
        child: Text(context.tr('bkReject')),
      ));
    } else if (b.status == 'confirmed') {
      list.add(FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.navyDeep,
        ),
        onPressed: () => _set(b, 'done'),
        child: Text(context.tr('bkDone')),
      ));
      list.add(OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          side: const BorderSide(color: AppColors.danger),
        ),
        onPressed: () => _set(b, 'cancelled'),
        child: Text(context.tr('bkCancelBooking')),
      ));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
                child: Row(
                  children: [
                    const BackButton(),
                    Expanded(
                      child: Text(
                        context.tr('bkStaffTitle'),
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _filterChip('pending', context.tr('bkFPending')),
                    const SizedBox(width: 8),
                    _filterChip('confirmed', context.tr('bkFConfirmed')),
                    const SizedBox(width: 8),
                    _filterChip('all', context.tr('bkFAll')),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: StreamBuilder<List<Booking>>(
                  stream: BookingService.all(),
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return Center(child: Text(context.tr('bkError')));
                    }
                    if (!snap.hasData) {
                      return const Center(
                        child:
                        CircularProgressIndicator(color: AppColors.gold),
                      );
                    }
                    var list = snap.data!;
                    if (_filter != 'all') {
                      list =
                          list.where((b) => b.status == _filter).toList();
                    } else {
                      list = list.reversed.toList();
                    }
                    if (list.isEmpty) {
                      return Center(
                        child: Text(
                          context.tr('bkNothing'),
                          style: const TextStyle(color: AppColors.textSoft),
                        ),
                      );
                    }
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      children: [
                        for (final b in list)
                          BookingCard(
                            b: b,
                            showMember: true,
                            actions: _actions(b),
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
}