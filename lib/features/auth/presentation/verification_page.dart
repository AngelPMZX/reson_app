import '../../../core/theme/reson_palette.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/firebase/firebase_bootstrap.dart';
import '../../../core/theme/reson_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'auth_errors.dart';
import 'brand_widgets.dart';

class VerificationPage extends ConsumerStatefulWidget {
  const VerificationPage({super.key});
  @override
  ConsumerState<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends ConsumerState<VerificationPage> {
  bool _started = false;
  bool _busy = false;
  bool _sent = false;
  bool _stillPending = false;
  int _remaining = 0;
  Timer? _timer;
  Object? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _send();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _send() async {
    if (_busy || _remaining > 0) return;
    final repository = ref.read(authRepositoryProvider).asData?.value;
    if (repository == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await repository.sendVerification(
        Localizations.localeOf(context).languageCode,
      );
      if (!mounted) return;
      setState(() {
        _sent = true;
        _remaining = 60;
      });
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted || _remaining <= 1) {
          timer.cancel();
          if (mounted) setState(() => _remaining = 0);
        } else {
          setState(() => _remaining--);
        }
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _check({bool logout = false}) async {
    if (_busy) return;
    final repository = ref.read(authRepositoryProvider).asData?.value;
    if (repository == null) return;
    setState(() {
      _busy = true;
      _error = null;
      _stillPending = false;
    });
    try {
      if (logout) {
        await repository.signOut();
      } else {
        await repository.refreshUser();
        if (mounted) setState(() => _stillPending = true);
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
    final user = ref.watch(authSessionProvider).asData?.value;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResonLogo(
                    dark: Theme.of(context).brightness == Brightness.dark,
                  ),
                  const SizedBox(height: 64),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: ResonPalette.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      Icons.mark_email_unread_outlined,
                      size: 38,
                      color: ResonTheme.violet,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    s.verifyTitle,
                    style: const TextStyle(
                      fontSize: 34,
                      height: 1.15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    s.verifyBody,
                    style: const TextStyle(
                      color: ResonTheme.muted,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SelectableText(
                    user?.email ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 24),
                  if (_sent) FeedbackMessage(text: s.verificationSent),
                  if (_stillPending)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: FeedbackMessage(text: s.verifyPending),
                    ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: FeedbackMessage(
                        text: authErrorMessage(_error!, s),
                        error: true,
                      ),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const Key('checkVerification'),
                      onPressed: _busy ? null : _check,
                      child: Text(s.refreshVerification),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      key: const Key('resendVerification'),
                      onPressed: _busy || _remaining > 0 ? null : _send,
                      child: Text(
                        _remaining > 0
                            ? '${s.resendEmail} ($_remaining s)'
                            : s.resendEmail,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    s.verifySpam,
                    style: const TextStyle(
                      color: ResonTheme.muted,
                      fontSize: 12,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton.icon(
                    onPressed: _busy ? null : () => _check(logout: true),
                    icon: const Icon(Icons.logout, size: 18),
                    label: Text(s.logout),
                  ),
                  if (_busy) const LinearProgressIndicator(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
