import 'package:flutter/material.dart';

import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../core/auth_service.dart';
import '../widgets/animated_background.dart';
import '../widgets/glass_widgets.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  bool _hide = true;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService.login(_email.text, _pass.text);
      // AuthGate هيفتح الشاشة الجاية تلقائي
    } catch (e) {
      if (!mounted) return;
      _snack(context.tr(AuthService.errorKey(e)));
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _forgot() async {
    final email = _email.text.trim();
    if (!email.contains('@') || !email.contains('.')) {
      _snack(context.tr('errEmail'));
      return;
    }
    try {
      await AuthService.resetPassword(email);
      if (!mounted) return;
      _snack(context.tr('resetSent'));
    } catch (e) {
      if (!mounted) return;
      _snack(context.tr(AuthService.errorKey(e)));
    }
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
                        Image.asset('assets/images/jsa_logo.png', width: 110),
                        const SizedBox(height: 16),
                        Text(
                          context.tr('loginTitle'),
                          style: const TextStyle(
                              fontSize: 26, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.tr('loginSub'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textSoft),
                        ),
                        const SizedBox(height: 24),
                        GlassCard(
                          child: Form(
                            key: _form,
                            child: Column(
                              children: [
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
                                GlassField(
                                  controller: _pass,
                                  label: context.tr('password'),
                                  icon: Icons.lock_outline_rounded,
                                  obscure: _hide,
                                  action: TextInputAction.done,
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
                                Align(
                                  alignment: AlignmentDirectional.centerEnd,
                                  child: TextButton(
                                    onPressed: _forgot,
                                    child: Text(
                                      context.tr('forgotPassword'),
                                      style: const TextStyle(
                                          color: AppColors.goldLight),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                GoldButton(
                                  text: context.tr('loginBtn'),
                                  loading: _loading,
                                  onTap: _submit,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              context.tr('noAccount'),
                              style:
                              const TextStyle(color: AppColors.textSoft),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              ),
                              child: Text(
                                context.tr('registerLink'),
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