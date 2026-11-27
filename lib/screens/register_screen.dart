import 'package:flutter/material.dart';

import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../core/auth_service.dart';
import '../widgets/animated_background.dart';
import '../widgets/glass_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();
  String? _gender; // male | female
  bool _loading = false;
  bool _hide = true;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _pass.dispose();
    _pass2.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_gender == null) {
      _snack(context.tr('errGender'));
      return;
    }
    setState(() => _loading = true);
    try {
      await AuthService.register(
        name: _name.text,
        email: _email.text,
        phone: _phone.text,
        gender: _gender!,
        password: _pass.text,
        lang: Localizations.localeOf(context).languageCode,
      );
      if (!mounted) return;
      // نرجع لأول شاشة، وAuthGate هيفتح الترحيب
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (!mounted) return;
      _snack(context.tr(AuthService.errorKey(e)));
    }
    if (mounted) setState(() => _loading = false);
  }

  Widget _genderChip(String value, String label, IconData icon) {
    final selected = _gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.gold.withValues(alpha: 0.18)
                : AppColors.glass,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.gold : AppColors.glassBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 20,
                  color: selected ? AppColors.gold : AppColors.textSoft),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.goldLight : AppColors.textSoft,
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
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      children: [
                        Image.asset('assets/images/jsa_logo.png', width: 90),
                        const SizedBox(height: 12),
                        Text(
                          context.tr('registerTitle'),
                          style: const TextStyle(
                              fontSize: 26, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.tr('registerSub'),
                          style: const TextStyle(color: AppColors.textSoft),
                        ),
                        const SizedBox(height: 20),
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
                                    final d = (v ?? '')
                                        .replaceAll(RegExp(r'[\s\-+]'), '');
                                    return RegExp(r'^\d{9,15}$').hasMatch(d)
                                        ? null
                                        : context.tr('errPhone');
                                  },
                                ),
                                const SizedBox(height: 14),
                                GlassField(
                                  controller: _email,
                                  label: context.tr('email'),
                                  icon: Icons.mail_outline_rounded,
                                  keyboard: TextInputType.emailAddress,
                                  action: TextInputAction.next,
                                  validator: (v) {
                                    final t = (v ?? '').trim();
                                    if (!t.contains('@') || !t.contains('.')) {
                                      return context.tr('errEmail');
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    _genderChip('male', context.tr('male'),
                                        Icons.male_rounded),
                                    const SizedBox(width: 12),
                                    _genderChip('female', context.tr('female'),
                                        Icons.female_rounded),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                GlassField(
                                  controller: _pass,
                                  label: context.tr('password'),
                                  icon: Icons.lock_outline_rounded,
                                  obscure: _hide,
                                  action: TextInputAction.next,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _hide
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppColors.textSoft,
                                    ),
                                    onPressed: () =>
                                        setState(() => _hide = !_hide),
                                  ),
                                  validator: (v) =>
                                  (v == null || v.length < 6)
                                      ? context.tr('errPassShort')
                                      : null,
                                ),
                                const SizedBox(height: 14),
                                GlassField(
                                  controller: _pass2,
                                  label: context.tr('confirmPassword'),
                                  icon: Icons.lock_reset_rounded,
                                  obscure: _hide,
                                  action: TextInputAction.done,
                                  validator: (v) => v != _pass.text
                                      ? context.tr('errPassMatch')
                                      : null,
                                ),
                                const SizedBox(height: 20),
                                GoldButton(
                                  text: context.tr('registerBtn'),
                                  loading: _loading,
                                  onTap: _submit,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              context.tr('haveAccount'),
                              style:
                              const TextStyle(color: AppColors.textSoft),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                context.tr('loginLink'),
                                style: const TextStyle(
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const PositionedDirectional(
                top: 4,
                start: 4,
                child: BackButton(),
              ),
              const PositionedDirectional(
                top: 8,
                end: 12,
                child: LangToggleButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}