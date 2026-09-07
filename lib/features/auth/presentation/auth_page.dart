import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/firebase/firebase_bootstrap.dart';
import '../../../core/theme/reson_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'auth_errors.dart';
import 'brand_widgets.dart';

enum AuthMode { login, register, reset }

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key, required this.mode});
  final AuthMode mode;
  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  bool _sent = false;
  Object? _error;

  bool get _register => widget.mode == AuthMode.register;
  bool get _reset => widget.mode == AuthMode.reset;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    final repository = ref.read(authRepositoryProvider).asData?.value;
    if (repository == null) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
      _sent = false;
    });
    final language = Localizations.localeOf(context).languageCode;
    try {
      if (_reset) {
        await repository.resetPassword(_email.text, language);
      } else if (_register) {
        await repository.register(_name.text, _email.text, _password.text);
      } else {
        await repository.signIn(_email.text, _password.text);
      }
      if (!mounted) return;
      if (_reset) {
        setState(() => _sent = true);
      } else {
        TextInput.finishAutofillContext();
        context.go('/home');
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final availability = ref.watch(authRepositoryProvider);
    final ready = availability.asData?.value != null;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, bounds) {
            final wide = bounds.maxWidth >= 900;
            final form = Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: AutofillGroup(
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!wide) ...[
                          ResonLogo(
                            dark:
                                Theme.of(context).brightness == Brightness.dark,
                          ),
                          const SizedBox(height: 30),
                        ],
                        TextButton.icon(
                          onPressed: _busy
                              ? null
                              : () => context.go(_reset ? '/login' : '/'),
                          icon: const Icon(Icons.arrow_back, size: 16),
                          label: Text(s.back),
                          style: TextButton.styleFrom(
                            foregroundColor: ResonTheme.muted,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _reset
                              ? s.resetTitle
                              : _register
                              ? s.registerTitle
                              : s.loginTitle,
                          style: const TextStyle(
                            fontSize: 37,
                            fontWeight: FontWeight.w600,
                            height: 1.12,
                            letterSpacing: -1.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _reset
                              ? s.resetBody
                              : _register
                              ? s.registerBody
                              : s.loginBody,
                          style: const TextStyle(
                            color: ResonTheme.muted,
                            fontSize: 14,
                            height: 1.7,
                          ),
                        ),
                        const SizedBox(height: 28),
                        if (!ready && !availability.isLoading) ...[
                          FeedbackMessage(
                            text: availability.hasError
                                ? s.authNetwork
                                : s.setupNotice,
                            error: availability.hasError,
                          ),
                          if (availability.hasError)
                            TextButton(
                              onPressed: () =>
                                  ref.invalidate(authRepositoryProvider),
                              child: Text(s.retry),
                            ),
                          const SizedBox(height: 20),
                        ],
                        if (_register) ...[
                          _label(s.name),
                          TextFormField(
                            key: const Key('name'),
                            controller: _name,
                            enabled: !_busy,
                            textCapitalization: TextCapitalization.words,
                            autofillHints: const [AutofillHints.name],
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              hintText: s.nameHint,
                              prefixIcon: const Icon(
                                Icons.person_outline_rounded,
                                size: 20,
                              ),
                            ),
                            validator: (value) => (value ?? '').trim().isEmpty
                                ? s.required
                                : value!.trim().length > 80
                                ? s.nameTooLong
                                : null,
                          ),
                          const SizedBox(height: 18),
                        ],
                        _label(s.email),
                        TextFormField(
                          key: const Key('email'),
                          controller: _email,
                          enabled: !_busy,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          autofillHints: const [AutofillHints.email],
                          textInputAction: _reset
                              ? TextInputAction.done
                              : TextInputAction.next,
                          onFieldSubmitted: _reset ? (_) => _submit() : null,
                          decoration: InputDecoration(
                            hintText: s.emailHint,
                            prefixIcon: const Icon(
                              Icons.alternate_email_rounded,
                              size: 20,
                            ),
                          ),
                          validator: (value) => (value ?? '').trim().isEmpty
                              ? s.required
                              : !RegExp(
                                  r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                ).hasMatch(value!.trim())
                              ? s.invalidEmail
                              : null,
                        ),
                        if (!_reset) ...[
                          const SizedBox(height: 18),
                          _label(s.password),
                          TextFormField(
                            key: const Key('password'),
                            controller: _password,
                            enabled: !_busy,
                            obscureText: _obscure,
                            autocorrect: false,
                            enableSuggestions: false,
                            autofillHints: [
                              _register
                                  ? AutofillHints.newPassword
                                  : AutofillHints.password,
                            ],
                            textInputAction: _register
                                ? TextInputAction.next
                                : TextInputAction.done,
                            onFieldSubmitted: _register
                                ? null
                                : (_) => _submit(),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                size: 20,
                              ),
                              helperText: _register ? s.passwordHelp : null,
                              suffixIcon: IconButton(
                                tooltip: _obscure
                                    ? s.showPassword
                                    : s.hidePassword,
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                ),
                              ),
                            ),
                            validator: (value) => (value ?? '').isEmpty
                                ? s.required
                                : _register && value!.length < 8
                                ? s.shortPassword
                                : null,
                          ),
                          if (_register) ...[
                            const SizedBox(height: 18),
                            _label(s.confirmPassword),
                            TextFormField(
                              key: const Key('confirmPassword'),
                              controller: _confirm,
                              enabled: !_busy,
                              obscureText: _obscure,
                              autocorrect: false,
                              enableSuggestions: false,
                              autofillHints: const [AutofillHints.newPassword],
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              decoration: const InputDecoration(
                                prefixIcon: Icon(
                                  Icons.lock_outline_rounded,
                                  size: 20,
                                ),
                              ),
                              validator: (value) => (value ?? '').isEmpty
                                  ? s.required
                                  : value != _password.text
                                  ? s.passwordMismatch
                                  : null,
                            ),
                          ] else
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _busy
                                    ? null
                                    : () => context.go('/reset-password'),
                                child: Text(
                                  s.forgot,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                        ],
                        const SizedBox(height: 24),
                        if (_error != null) ...[
                          FeedbackMessage(
                            text: authErrorMessage(_error!, s),
                            error: true,
                          ),
                          const SizedBox(height: 18),
                        ],
                        if (_sent) ...[
                          FeedbackMessage(text: s.resetSuccess),
                          const SizedBox(height: 18),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            key: const Key('authSubmit'),
                            onPressed: _busy || !ready || _sent
                                ? null
                                : _submit,
                            child: _busy || availability.isLoading
                                ? SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      semanticsLabel: s.loading,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          _reset
                                              ? s.reset
                                              : _register
                                              ? s.register
                                              : s.login,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: _reset
                              ? TextButton(
                                  onPressed: _busy
                                      ? null
                                      : () => context.go('/login'),
                                  child: Text(s.backLogin),
                                )
                              : Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      _register
                                          ? s.alreadyAccount
                                          : s.noAccount,
                                      style: const TextStyle(
                                        color: ResonTheme.muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _busy
                                          ? null
                                          : () => context.go(
                                              _register
                                                  ? '/login'
                                                  : '/register',
                                            ),
                                      child: Text(
                                        _register ? s.login : s.register,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.lock_outline_rounded,
                              size: 12,
                              color: ResonTheme.muted,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                s.secureNote,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: ResonTheme.muted,
                                  fontSize: 10,
                                  height: 1.5,
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
            );
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (wide)
                  Expanded(
                    child: BrandBackground(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(48),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const ResonLogo(),
                              const SizedBox(height: 56),
                              Text(
                                s.authSideTitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 38,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -1.2,
                                  height: 1.18,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                s.authSideBody,
                                style: const TextStyle(
                                  color: Color(0xFFB9B0C7),
                                  fontSize: 14,
                                  height: 1.7,
                                ),
                              ),
                              const SizedBox(height: 26),
                              const Center(
                                child: IdentityPreview(compact: true),
                              ),
                              const SizedBox(height: 40),
                              Text(
                                s.publisher,
                                style: const TextStyle(
                                  color: Color(0xFFA69BB5),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: wide ? 48 : 24,
                      vertical: 32,
                    ),
                    child: form,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );
}
