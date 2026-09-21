import '../features/network/share_card_page.dart';
import '../features/network/receive_card_page.dart';
import '../features/network/network_page.dart';
import '../features/network/chat_page.dart';
import '../features/profile/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/firebase/firebase_bootstrap.dart';
import '../core/theme/reson_theme.dart';
import '../features/cards/presentation/cards_page.dart';
import '../features/cards/presentation/card_editor_page.dart';
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
  String? pendingReceive;
  final refresh = _RouterRefresh();
  ref.listen(authSessionProvider, (_, next) => refresh.refresh());
  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      if (state.uri.path.startsWith('/receive/')) {
        pendingReceive = state.uri.path;
      }
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
      if (pendingReceive != null && path != pendingReceive) {
        final target = pendingReceive!;
        pendingReceive = null;
        return target;
      }
      if (path.startsWith('/receive/')) pendingReceive = null;
      if (path != '/network' &&
          !path.startsWith('/receive/') &&
          !path.startsWith('/chat/') &&
          path != '/home' &&
          path != '/profile' &&
          !path.startsWith('/cards/')) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/network', builder: (_, s) => const NetworkPage()),
      GoRoute(
        path: '/receive/:id',
        builder: (_, s) => ReceiveCardPage(publicId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (_, s) => ChatPage(connectionId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/cards/:id/share',
        builder: (_, s) => ShareCardPage(cardId: s.pathParameters['id']!),
      ),
      GoRoute(path: '/profile', builder: (_, state) => const ProfilePage()),
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
      theme: ResonTheme.forSeed(ResonTheme.brand),
      darkTheme: ResonTheme.forSeed(
        ResonTheme.brand,
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
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
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
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
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
