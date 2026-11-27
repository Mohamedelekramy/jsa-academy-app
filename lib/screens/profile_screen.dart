import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../core/profile_service.dart';
import '../widgets/animated_background.dart';
import '../widgets/glass_widgets.dart';
import '../widgets/user_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  String? _photo; // Base64
  bool _photoChanged = false;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await ProfileService.load();
      _name.text = (d['name'] ?? '') as String;
      _phone.text = (d['phone'] ?? '') as String;
      _address.text = (d['address'] ?? '') as String;
      _photo = d['photoB64'] as String?;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pick() async {
    final tooBig = context.tr('photoTooBig');
    final fail = context.tr('errGeneric');
    try {
      final x = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 70,
      );
      if (x == null) return;
      final bytes = await x.readAsBytes();
      if (bytes.length > 200 * 1024) {
        _snack(tooBig);
        return;
      }
      setState(() {
        _photo = base64Encode(bytes);
        _photoChanged = true;
      });
    } catch (_) {
      _snack(fail);
    }
  }

  void _removePhoto() {
    setState(() {
      _photo = null;
      _photoChanged = true;
    });
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final ok = context.tr('profileSaved');
    final fail = context.tr('errGeneric');
    setState(() => _saving = true);
    try {
      await ProfileService.update(
        name: _name.text,
        phone: _phone.text,
        address: _address.text,
        photoB64: _photo,
        photoChanged: _photoChanged,
      );
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(ok)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(fail)));
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

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
                        context.tr('profileTitle'),
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(
                  child:
                  CircularProgressIndicator(color: AppColors.gold),
                )
                    : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(
                        children: [
                          // الصورة الشخصية
                          GestureDetector(
                            onTap: _pick,
                            child: Stack(
                              children: [
                                UserAvatar(photoB64: _photo, radius: 56),
                                PositionedDirectional(
                                  bottom: 0,
                                  end: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      gradient: AppGradients.gold,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      size: 18,
                                      color: AppColors.navyDeep,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: _pick,
                                child: Text(
                                  context.tr('changePhoto'),
                                  style: const TextStyle(
                                      color: AppColors.goldLight),
                                ),
                              ),
                              if (_photo != null)
                                TextButton(
                                  onPressed: _removePhoto,
                                  child: Text(
                                    context.tr('removePhoto'),
                                    style: const TextStyle(
                                        color: AppColors.danger),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          GlassCard(
                            child: Form(
                              key: _form,
                              child: Column(
                                children: [
                                  GlassField(
                                    controller: _name,
                                    label: context.tr('fullName'),
                                    icon: Icons.person_outline_rounded,
                                    action: TextInputAction.next,
                                    validator: (v) =>
                                    (v == null || v.trim().length < 3)
                                        ? context.tr('errRequired')
                                        : null,
                                  ),
                                  const SizedBox(height: 14),
                                  GlassField(
                                    controller: _phone,
                                    label: context.tr('phone'),
                                    icon: Icons.phone_outlined,
                                    keyboard: TextInputType.phone,
                                    action: TextInputAction.next,
                                    validator: (v) {
                                      final d = (v ?? '').replaceAll(
                                          RegExp(r'[\s\-+]'), '');
                                      return RegExp(r'^\d{9,15}$')
                                          .hasMatch(d)
                                          ? null
                                          : context.tr('errPhone');
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _address,
                                    maxLines: 2,
                                    decoration: InputDecoration(
                                      labelText: context.tr('address'),
                                      labelStyle: const TextStyle(
                                          color: AppColors.textSoft),
                                      prefixIcon: const Icon(
                                          Icons.location_on_outlined,
                                          color: AppColors.textSoft),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    initialValue: email,
                                    enabled: false,
                                    textDirection: TextDirection.ltr,
                                    decoration: InputDecoration(
                                      labelText: context.tr('email'),
                                      labelStyle: const TextStyle(
                                          color: AppColors.textSoft),
                                      prefixIcon: const Icon(
                                          Icons.mail_outline_rounded,
                                          color: AppColors.textSoft),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  GoldButton(
                                    text: context.tr('save'),
                                    loading: _saving,
                                    onTap: _save,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}