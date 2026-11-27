import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../core/auth_service.dart';
import '../core/profile_service.dart';
import '../widgets/animated_background.dart';
import '../widgets/glass_widgets.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _old = TextEditingController();
  final _new = TextEditingController();
  final _new2 = TextEditingController();
  bool _hide = true;
  bool _loading = false;

  @override
  void dispose() {
    _old.dispose();
    _new.dispose();
    _new2.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final ok = context.tr('passwordChanged');
    setState(() => _loading = true);
    try {
      await ProfileService.changePassword(
        oldPass: _old.text,
        newPass: _new.text,
      );
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(ok)));
    } catch (e) {
      String key;
      if (e is FirebaseAuthException &&
          (e.code == 'wrong-password' || e.code == 'invalid-credential')) {
        key = 'errOldPass';
      } else if (e is FirebaseAuthException &&
          e.code == 'requires-recent-login') {
        key = 'errRecentLogin';
      } else {
        key = AuthService.errorKey(e);
      }
      if (!mounted) return;
      _snack(context.tr(key));
      setState(() => _loading = false);
    }
  }

  Widget _eye() {
    return IconButton(
      icon: Icon(
        _hide ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: AppColors.textSoft,
      ),
      onPressed: () => setState(() => _hide = !_hide),
    );
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
                        context.tr('changePassword'),
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const Icon(Icons.lock_reset_rounded,
                        color: AppColors.goldLight),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: GlassCard(
                        child: Form(
                          key: _form,
                          child: Column(
                            children: [
                              GlassField(
                                controller: _old,
                                label: context.tr('oldPassword'),
                                icon: Icons.lock_outline_rounded,
                                obscure: _hide,
                                suffix: _eye(),
                                action: TextInputAction.next,
                                validator: (v) => (v == null || v.isEmpty)
                                    ? context.tr('errRequired')
                                    : null,
                              ),
                              const SizedBox(height: 14),
                              GlassField(
                                controller: _new,
                                label: context.tr('newPassword'),
                                icon: Icons.lock_rounded,
                                obscure: _hide,
                                action: TextInputAction.next,
                                validator: (v) {
                                  if (v == null || v.length < 6) {
                                    return context.tr('errPassShort');
                                  }
                                  if (v == _old.text) {
                                    return context.tr('errSamePass');
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              GlassField(
                                controller: _new2,
                                label: context.tr('confirmNewPassword'),
                                icon: Icons.lock_reset_rounded,
                                obscure: _hide,
                                action: TextInputAction.done,
                                validator: (v) => v != _new.text
                                    ? context.tr('errPassMatch')
                                    : null,
                              ),
                              const SizedBox(height: 20),
                              GoldButton(
                                text: context.tr('changePassword'),
                                loading: _loading,
                                onTap: _submit,
                              ),
                            ],
                          ),
                        ),
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