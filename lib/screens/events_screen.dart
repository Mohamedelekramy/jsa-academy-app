import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/announcement_service.dart';
import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../core/auth_service.dart';
import '../widgets/animated_background.dart';
import '../widgets/glass_widgets.dart';

Color _typeColor(String t) {
  switch (t) {
    case 'offer':
      return AppColors.success;
    case 'tournament':
      return AppColors.gold;
    default:
      return AppColors.goldLight;
  }
}

IconData _typeIcon(String t) {
  switch (t) {
    case 'offer':
      return Icons.local_offer_rounded;
    case 'tournament':
      return Icons.emoji_events_rounded;
    default:
      return Icons.campaign_rounded;
  }
}

String _typeKey(String t) {
  switch (t) {
    case 'offer':
      return 'evOffer';
    case 'tournament':
      return 'evTournament';
    default:
      return 'evNews';
  }
}

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  String _filter = 'all';

  Future<void> _delete(Announcement a) async {
    final err = context.tr('evError');
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.navy,
        content: Text(ctx.tr('evDeleteAsk')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(ctx.tr('evNo')),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(ctx.tr('evYes'),
                style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AnnouncementService.delete(a.id);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(err)));
    }
  }

  void _form([Announcement? a]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.navy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AnnouncementForm(existing: a),
    );
  }

  Widget _chip(String key, String label) {
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

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: StreamBuilder(
            stream: user == null ? null : AuthService.profileStream(user.uid),
            builder: (context, roleSnap) {
              final role =
                  (roleSnap.data?.data()?['role'] as String?) ?? 'member';
              final canEdit = role == 'admin' || role == 'receptionist';

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
                    child: Row(
                      children: [
                        const BackButton(),
                        Expanded(
                          child: Text(
                            context.tr('evTitle'),
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (canEdit)
                          InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => _form(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: AppGradients.gold,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.add_rounded,
                                      size: 18, color: AppColors.navyDeep),
                                  const SizedBox(width: 4),
                                  Text(
                                    context.tr('evAdd'),
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _chip('all', context.tr('evAll')),
                          const SizedBox(width: 8),
                          for (final t in announcementTypes) ...[
                            _chip(t, context.tr(_typeKey(t))),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: StreamBuilder<List<Announcement>>(
                      stream: AnnouncementService.stream(),
                      builder: (context, snap) {
                        if (snap.hasError) {
                          return Center(child: Text(context.tr('evError')));
                        }
                        if (!snap.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.gold),
                          );
                        }
                        var list = snap.data!;
                        if (_filter != 'all') {
                          list =
                              list.where((a) => a.type == _filter).toList();
                        }
                        if (list.isEmpty) {
                          return Center(
                            child: Text(
                              context.tr('evEmpty'),
                              style:
                              const TextStyle(color: AppColors.textSoft),
                            ),
                          );
                        }
                        return ListView(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          children: [
                            for (final a in list)
                              _AnnouncementCard(
                                a: a,
                                lang: lang,
                                canEdit: canEdit,
                                onEdit: () => _form(a),
                                onDelete: () => _delete(a),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final Announcement a;
  final String lang;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _AnnouncementCard({
    required this.a,
    required this.lang,
    required this.canEdit,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(a.type);
    final d = a.createdAt;
    final date =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_typeIcon(a.type), size: 15, color: color),
                      const SizedBox(width: 5),
                      Text(
                        context.tr(_typeKey(a.type)),
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: color),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(date,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSoft)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              a.title(lang),
              style:
              const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              a.body(lang),
              style: const TextStyle(height: 1.5, color: AppColors.textSoft),
            ),
            if (canEdit) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(context.tr('evEdit')),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.danger),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnnouncementForm extends StatefulWidget {
  final Announcement? existing;
  const _AnnouncementForm({this.existing});

  @override
  State<_AnnouncementForm> createState() => _AnnouncementFormState();
}

class _AnnouncementFormState extends State<_AnnouncementForm> {
  final _form = GlobalKey<FormState>();
  late String _type = widget.existing?.type ?? 'news';
  late final _titleAr = TextEditingController(text: widget.existing?.titleAr);
  late final _titleEn = TextEditingController(text: widget.existing?.titleEn);
  late final _bodyAr = TextEditingController(text: widget.existing?.bodyAr);
  late final _bodyEn = TextEditingController(text: widget.existing?.bodyEn);
  bool _busy = false;

  @override
  void dispose() {
    _titleAr.dispose();
    _titleEn.dispose();
    _bodyAr.dispose();
    _bodyEn.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final err = context.tr('evError');
    setState(() => _busy = true);
    final data = <String, String>{
      'type': _type,
      'titleAr': _titleAr.text.trim(),
      'titleEn': _titleEn.text.trim(),
      'bodyAr': _bodyAr.text.trim(),
      'bodyEn': _bodyEn.text.trim(),
    };
    try {
      if (widget.existing == null) {
        await AnnouncementService.add(data);
      } else {
        await AnnouncementService.update(widget.existing!.id, data);
      }
      navigator.pop();
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(err)));
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _reqTitle(String? v) =>
      (_titleAr.text.trim().isEmpty && _titleEn.text.trim().isEmpty)
          ? context.tr('evNeedOne')
          : null;

  String? _reqBody(String? v) =>
      (_bodyAr.text.trim().isEmpty && _bodyEn.text.trim().isEmpty)
          ? context.tr('evNeedOne')
          : null;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottom),
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Text(
                    context.tr(widget.existing == null
                        ? 'evNewTitle'
                        : 'evEdit'),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 14),
                Text(context.tr('evType'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.goldLight)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final t in announcementTypes)
                      ChoiceChip(
                        label: Text(
                          context.tr(_typeKey(t)),
                          style: TextStyle(
                            color: _type == t
                                ? AppColors.navyDeep
                                : Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        selected: _type == t,
                        selectedColor: AppColors.gold,
                        backgroundColor: AppColors.glass,
                        side:
                        const BorderSide(color: AppColors.glassBorder),
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _type = t),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _titleAr,
                  validator: _reqBody,
                  decoration:
                  InputDecoration(labelText: context.tr('evTitleAr')),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bodyAr,
                  validator: _reqTitle,
                  maxLines: 4,
                  decoration:
                  InputDecoration(labelText: context.tr('evBodyAr')),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleEn,
                  textDirection: TextDirection.ltr,
                  decoration:
                  InputDecoration(labelText: context.tr('evTitleEn')),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bodyEn,
                  textDirection: TextDirection.ltr,
                  maxLines: 4,
                  decoration:
                  InputDecoration(labelText: context.tr('evBodyEn')),
                ),
                const SizedBox(height: 18),
                GoldButton(
                  text: context.tr('evSave'),
                  loading: _busy,
                  onTap: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}