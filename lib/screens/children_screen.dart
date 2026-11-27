import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../core/children_service.dart';
import '../widgets/animated_background.dart';
import '../widgets/glass_widgets.dart';

String _fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// اسم الفئة حسب العمر
String categoryLabel(BuildContext c, String cat) {
  switch (cat) {
    case 'A':
      return c.tr('catA');
    case 'B':
      return c.tr('catB');
    case 'C':
      return c.tr('catC');
    default:
      return c.tr('catNone');
  }
}

class ChildrenScreen extends StatelessWidget {
  const ChildrenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

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
                        context.tr('myChildren'),
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const Icon(Icons.child_care_rounded,
                        color: AppColors.goldLight),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<List<Child>>(
                  stream: ChildrenService.myChildren(uid),
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return Center(
                        child: Text('${snap.error}',
                            textDirection: TextDirection.ltr),
                      );
                    }
                    if (!snap.hasData) {
                      return const Center(
                        child:
                        CircularProgressIndicator(color: AppColors.gold),
                      );
                    }
                    final list = snap.data!;
                    if (list.isEmpty) {
                      return Center(
                        child: Text(
                          context.tr('noChildren'),
                          style: const TextStyle(color: AppColors.textSoft),
                        ),
                      );
                    }
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      children: [
                        for (final c in list)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ChildCard(child: c),
                          ),
                      ],
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: GoldButton(
                  text: context.tr('addChild'),
                  onTap: () => showChildForm(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  final Child child;
  const _ChildCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final inRange = child.category != '-';
    final catColor = inRange ? AppColors.goldLight : AppColors.danger;
    final girl = child.gender == 'female';

    return GlassCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor:
            (girl ? AppColors.women : AppColors.kids).withValues(alpha: 0.3),
            child: Icon(
              girl ? Icons.girl_rounded : Icons.boy_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child.name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  '${child.age} ${context.tr('yearsUnit')}',
                  style: const TextStyle(
                      fontSize: 12.5, color: AppColors.textSoft),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    categoryLabel(context, child.category),
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: catColor),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.textSoft),
            onPressed: () => showChildForm(context, child: child),
          ),
        ],
      ),
    );
  }
}

/// نموذج إضافة / تعديل طفل
Future<void> showChildForm(BuildContext context, {Child? child}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.navy,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _ChildForm(child: child),
  );
}

class _ChildForm extends StatefulWidget {
  final Child? child;
  const _ChildForm({this.child});

  @override
  State<_ChildForm> createState() => _ChildFormState();
}

class _ChildFormState extends State<_ChildForm> {
  late final TextEditingController _name =
  TextEditingController(text: widget.child?.name ?? '');
  late DateTime? _birth = widget.child?.birthDate;
  late String? _gender = widget.child?.gender;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _birth ?? DateTime(now.year - 8, 1, 1),
      firstDate: DateTime(now.year - 25),
      lastDate: now,
    );
    if (d != null) setState(() => _birth = d);
  }

  Future<void> _save() async {
    if (_name.text.trim().length < 2) {
      setState(() => _error = context.tr('errChildName'));
      return;
    }
    if (_birth == null) {
      setState(() => _error = context.tr('errBirth'));
      return;
    }
    if (_gender == null) {
      setState(() => _error = context.tr('errGender'));
      return;
    }
    final navigator = Navigator.of(context);
    final fail = context.tr('errGeneric');
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.child == null) {
        await ChildrenService.add(
          name: _name.text,
          birthDate: _birth!,
          gender: _gender!,
        );
      } else {
        await ChildrenService.update(
          widget.child!.id,
          name: _name.text,
          birthDate: _birth!,
          gender: _gender!,
        );
      }
      navigator.pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = fail;
        });
      }
    }
  }

  Widget _genderChip(String value, String label, IconData icon) {
    final sel = _gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: sel ? AppColors.gold.withValues(alpha: 0.18) : AppColors.glass,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: sel ? AppColors.gold : AppColors.glassBorder,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 20,
                  color: sel ? AppColors.gold : AppColors.textSoft),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: sel ? AppColors.goldLight : AppColors.textSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cat = _birth == null ? null : categoryOf(ageOf(_birth!));

    return SafeArea(
      child: SingleChildScrollView(
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
              context.tr(widget.child == null ? 'addChild' : 'editChild'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            GlassField(
              controller: _name,
              label: context.tr('childName'),
              icon: Icons.child_care_rounded,
            ),
            const SizedBox(height: 14),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _pickDate,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.glass,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cake_outlined,
                        color: AppColors.textSoft, size: 22),
                    const SizedBox(width: 12),
                    Text(
                      _birth == null
                          ? '${context.tr('birthDate')} - ${context.tr('pickDate')}'
                          : _fmtDate(_birth!),
                      style: TextStyle(
                        color: _birth == null
                            ? AppColors.textSoft
                            : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (cat != null) ...[
              const SizedBox(height: 8),
              Text(
                '${ageOf(_birth!)} ${context.tr('yearsUnit')} • ${categoryLabel(context, cat)}',
                style: TextStyle(
                  fontSize: 12.5,
                  color: cat == '-' ? AppColors.danger : AppColors.goldLight,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                _genderChip('male', context.tr('male'), Icons.boy_rounded),
                const SizedBox(width: 12),
                _genderChip('female', context.tr('female'), Icons.girl_rounded),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],
            const SizedBox(height: 18),
            GoldButton(
              text: context.tr('save'),
              loading: _loading,
              onTap: _save,
            ),
          ],
        ),
      ),
    );
  }
}