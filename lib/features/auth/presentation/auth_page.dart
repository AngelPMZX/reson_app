import '../../../core/theme/reson_chrome.dart';
import '../../../core/theme/reson_palette.dart';
import 'auth_welcome.dart';
import '../../../core/theme/reson_motion.dart';
import '../../auth/domain/auth_repository.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/reson_surfaces.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/firebase/firebase_bootstrap.dart';
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
        // Session routing restores an incoming shared-card destination.
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _google() async {
    if (_busy) return;
    final repository = ref.read(authRepositoryProvider).asData?.value;
    if (repository == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await repository.signInGoogle();
    } catch (error) {
      if (mounted &&
          !(error is AuthFailure &&
              [
                'popup-closed-by-user',
                'cancelled-popup-request',
              ].contains(error.code))) {
        setState(() => _error = error);
      }
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
                        // On the wide layout the wordmark already shows on
                        // the branded panel, so the form carries only controls.
                        ResonHeader(
                          leading: wide ? const SizedBox.shrink() : null,
                        ),
                        const SizedBox(height: ResonSpace.xxl),
                        if (!wide) ...[
                          if (!_reset) ...[
                            const AuthWelcome(compact: true),
                            const SizedBox(height: ResonSpace.xl),
                          ],
                        ],
                        TextButton.icon(
                          onPressed: _busy
                              ? null
                              : () => context.go(_reset ? '/login' : '/'),
                          icon: const Icon(Icons.arrow_back, size: 16),
                          label: Text(s.back),
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        const SizedBox(height: ResonSpace.md),
                        Text(
                          _reset
                              ? s.resetTitle
                              : _register
                              ? s.registerTitle
                              : s.loginTitle,
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        const SizedBox(height: ResonSpace.md),
                        Text(
                          _reset
                              ? s.resetBody
                              : _register
                              ? s.registerBody
                              : s.loginBody,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                height: 1.7,
                              ),
                        ),
                        const SizedBox(height: ResonSpace.xxl),
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
                          const SizedBox(height: ResonSpace.xl),
                        ],
                        if (!_reset) ...[
                          ResonPress(
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                key: const Key('googleSignIn'),
                                onPressed: ready && !_busy ? _google : null,
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 54),
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerLowest,
                                ),
                                icon: const Icon(Icons.login_rounded, size: 20),
                                label: Text(s.continueGoogle),
                              ),
                            ),
                          ),
                          const SizedBox(height: ResonSpace.lg),
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: ResonSpace.lg,
                                ),
                                child: Text(
                                  s.orEmail,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: ResonSpace.xl),
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
                          const SizedBox(height: ResonSpace.lg),
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
                          const SizedBox(height: ResonSpace.lg),
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
                            const SizedBox(height: ResonSpace.lg),
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
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ),
                        ],
                        const SizedBox(height: ResonSpace.xl),
                        if (_error != null) ...[
                          FeedbackMessage(
                            text: authErrorMessage(_error!, s),
                            error: true,
                          ),
                          const SizedBox(height: ResonSpace.lg),
                        ],
                        if (_sent) ...[
                          FeedbackMessage(text: s.resetSuccess),
                          const SizedBox(height: ResonSpace.lg),
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
                                      const SizedBox(width: ResonSpace.md),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: ResonSpace.xl),
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
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
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
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: ResonSpace.xl),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: ResonSpace.sm),
                            Flexible(
                              child: Text(
                                s.secureNote,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
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
                          padding: const EdgeInsets.all(ResonSpace.huge),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const ResonWordmark(),
                              const SizedBox(height: ResonSpace.huge),
                              Text(
                                s.authPromise,
                                style: Theme.of(context).textTheme.displaySmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      height: 1.18,
                                    ),
                              ),
                              const SizedBox(height: ResonSpace.lg),
                              Text(
                                s.authPromiseBody,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: ResonPalette.paleGrey,
                                      height: 1.7,
                                    ),
                              ),
                              const SizedBox(height: ResonSpace.xl),
                              const Center(child: AuthWelcome()),
                              const SizedBox(height: ResonSpace.huge),
                              Text(
                                s.publisher,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: ResonPalette.paleGrey,
                                      letterSpacing: null,
                                      fontWeight: FontWeight.w400,
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
                      vertical: ResonSpace.xxl,
                    ),
                    child: ResonReveal(child: form),
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
    padding: const EdgeInsets.only(bottom: ResonSpace.sm),
    child: Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
    ),
  );
}
