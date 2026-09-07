import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/firebase/firebase_bootstrap.dart';
import '../core/theme/reson_theme.dart';
import '../features/cards/presentation/cards_page.dart';
import '../features/cards/presentation/card_editor_page.dart';
import '../features/cards/application/cards_providers.dart';
import '../features/cards/presentation/card_preview.dart';
import '../features/auth/presentation/auth_page.dart';
import '../features/auth/presentation/intro_page.dart';
import '../features/auth/presentation/verification_page.dart';
import '../l10n/generated/app_localizations.dart';

class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() => null;
  void set(Locale locale) => state = locale;
}

final localeProvider = NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);

class _RouterRefresh extends ChangeNotifier {
  void refresh() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh();
  ref.listen(authSessionProvider, (_, next) => refresh.refresh());
  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(authSessionProvider);
      final path = state.uri.path;
      if (session.isLoading || session.hasError) {
        return path == '/session' ? null : '/session';
      }
      final user = session.asData?.value;
      if (user == null) {
        if (path == '/session') return '/';
        return ['/', '/login', '/register', '/reset-password'].contains(path)
            ? null
            : '/login';
      }
      if (!user.emailVerified) {
        return path == '/verify-email' ? null : '/verify-email';
      }
      if (path != '/home' && !path.startsWith('/cards/')) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/session', builder: (_, state) => const _SessionPage()),
      GoRoute(
        path: '/verify-email',
        builder: (_, state) => const VerificationPage(),
      ),
      GoRoute(path: '/', builder: (_, state) => const IntroPage()),
      GoRoute(
        path: '/login',
        builder: (_, state) =>
            const AuthPage(key: ValueKey('login'), mode: AuthMode.login),
      ),
      GoRoute(
        path: '/register',
        builder: (_, state) =>
            const AuthPage(key: ValueKey('register'), mode: AuthMode.register),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (_, state) =>
            const AuthPage(key: ValueKey('reset'), mode: AuthMode.reset),
      ),
      GoRoute(path: '/home', builder: (_, state) => const CardsPage()),
      GoRoute(
        path: '/cards/new',
        builder: (_, state) => const CardEditorPage(),
      ),
      GoRoute(
        path: '/cards/:id/edit',
        builder: (_, state) =>
            CardEditorPage(cardId: state.pathParameters['id']),
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

class ResonApp extends ConsumerWidget {
  const ResonApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: ref.watch(localeProvider),
      theme: ResonTheme.forSeed(
        cardColor(ref.watch(activeCardProvider)?.primaryHex ?? '#7860E9'),
      ),
      darkTheme: ResonTheme.forSeed(
        cardColor(ref.watch(activeCardProvider)?.primaryHex ?? '#7860E9'),
        brightness: Brightness.dark,
      ),
      themeMode: ref.watch(appearanceProvider),
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) => Stack(
        children: [
          child ?? const SizedBox.shrink(),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 16,
            right: 76,
            child: Material(
              color: Colors.transparent,
              child: Semantics(
                label: Localizations.localeOf(context).languageCode == 'es'
                    ? 'Cambiar tema'
                    : 'Switch theme',
                child: IconButton(
                  key: const Key('themeToggle'),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFEDE8F6),
                    foregroundColor: const Color(0xFF514267),
                  ),
                  onPressed: () =>
                      ref.read(appearanceProvider.notifier).toggle(),
                  icon: Icon(
                    ref.watch(appearanceProvider) == ThemeMode.dark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 16,
            right: 18,
            child: Semantics(
              label: AppLocalizations.of(context)!.language,
              child: Material(
                color: Colors.transparent,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFEDE8F6),
                    foregroundColor: const Color(0xFF514267),
                    minimumSize: const Size(48, 40),
                  ),
                  onPressed: () {
                    final current = Localizations.localeOf(
                      context,
                    ).languageCode;
                    ref
                        .read(localeProvider.notifier)
                        .set(Locale(current == 'es' ? 'en' : 'es'));
                  },
                  child: Text(
                    Localizations.localeOf(context).languageCode == 'es'
                        ? 'EN'
                        : 'ES',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionPage extends ConsumerWidget {
  const _SessionPage();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final s = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: session.hasError
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(s.authNetwork),
                  TextButton(
                    onPressed: () {
                      ref.invalidate(authRepositoryProvider);
                      ref.invalidate(authSessionProvider);
                    },
                    child: Text(s.retry),
                  ),
                ],
              )
            : CircularProgressIndicator(semanticsLabel: s.loading),
      ),
    );
  }
}
