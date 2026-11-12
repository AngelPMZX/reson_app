import 'package:reson/features/profile/personal_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reson/app/reson_app.dart';
import 'package:reson/core/theme/reson_theme.dart';
import 'package:reson/core/firebase/firebase_bootstrap.dart';
import 'package:reson/features/auth/domain/auth_repository.dart';
import 'package:reson/features/cards/domain/digital_card.dart';
import 'package:reson/features/cards/application/cards_providers.dart';

class TestAuthRepository implements AuthRepository {
  int googleCalls = 0;
  @override
  Future<void> signInGoogle() async {
    googleCalls++;
    await signIn('google@example.com', '');
  }

  final _events = StreamController<AuthIdentity?>.broadcast();
  AuthIdentity? current;
  String? errorCode;
  int signInCalls = 0;
  int resetCalls = 0;
  String? resetLanguage;
  String? registeredName;
  bool verified = false;
  int verificationCalls = 0;
  Completer<void>? pending;
  @override
  Stream<AuthIdentity?> watchSession() async* {
    yield current;
    yield* _events.stream;
  }

  @override
  Future<void> signIn(String email, String password) async {
    signInCalls++;
    if (pending != null) await pending!.future;
    if (errorCode != null) throw AuthFailure(errorCode!);
    current = AuthIdentity(
      uid: 'test-user',
      email: email,
      emailVerified: verified,
    );
    _events.add(current);
  }

  @override
  Future<void> register(String name, String email, String password) async {
    registeredName = name;
    await signIn(email, password);
  }

  @override
  Future<void> resetPassword(String email, String language) async {
    resetCalls++;
    resetLanguage = language;
  }

  @override
  Future<void> signOut() async {
    current = null;
    _events.add(null);
  }

  @override
  Future<void> sendVerification(String language) async {
    verificationCalls++;
  }

  @override
  Future<void> refreshUser() async {
    final user = current;
    if (user == null) return;
    current = AuthIdentity(
      uid: user.uid,
      email: user.email,
      name: user.name,
      emailVerified: verified,
    );
    _events.add(current);
  }

  Future<void> dispose() => _events.close();
}

class TestCardsRepository implements CardsRepository {
  final events = StreamController<List<DigitalCard>>.broadcast();
  final selections = StreamController<String?>.broadcast();
  final List<DigitalCard> cards = [];
  String? active;
  bool failSave = false;
  int watchCalls = 0;
  @override
  String newId() =>
      'abcdefghijklmnop${cards.length.toString().padLeft(4, '0')}';
  @override
  Stream<List<DigitalCard>> watchCards() async* {
    watchCalls++;
    yield [...cards];
    yield* events.stream;
  }

  @override
  Stream<String?> watchActiveCardId() async* {
    yield active;
    yield* selections.stream;
  }

  @override
  Future<void> save(DigitalCard card) async {
    if (failSave) throw StateError('Unavailable');
    cards.removeWhere((existing) => existing.id == card.id);
    cards.add(card);
    active ??= card.id;
    events.add([...cards]);
    selections.add(active);
  }

  @override
  Future<void> select(String id) async {
    active = id;
    selections.add(id);
  }

  Future<void> dispose() async {
    await events.close();
    await selections.close();
  }
}

Future<ProviderContainer> launch(
  WidgetTester tester, {
  AuthRepository? repository,
  Size size = const Size(1200, 1000),
  String locale = 'es',
  double textScale = 1,
  TestCardsRepository? cardsRepository,
  PersonalProfileRepository? personalRepository,
}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final cards = cardsRepository ?? TestCardsRepository();
  addTearDown(cards.dispose);
  final container = ProviderContainer(
    overrides: [
      personalProfileRepositoryProvider.overrideWithValue(personalRepository),
      authRepositoryProvider.overrideWith((ref) async => repository),
      cardsRepositoryProvider.overrideWith((ref) async => cards),
    ],
  );
  container.read(localeProvider.notifier).set(Locale(locale));
  addTearDown(container.dispose);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: const ResonApp(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> submit(WidgetTester tester) async {
  final button = find.byKey(const Key('authSubmit'));
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [320.0, 390.0, 900.0, 1440.0]) {
    for (final locale in ['es', 'en']) {
      testWidgets('All public routes fit at $width in $locale', (tester) async {
        final container = await launch(
          tester,
          size: Size(width, 850),
          locale: locale,
        );
        for (final route in ['/', '/login', '/register', '/reset-password']) {
          container.read(routerProvider).go(route);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: route);
        }
      });
    }
  }

  testWidgets(
    'Unconfigured Firebase disables submission and explains availability',
    (tester) async {
      final container = await launch(tester);
      container.read(routerProvider).go('/login');
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('authSubmit')))
            .onPressed,
        isNull,
      );
      expect(find.textContaining('Estamos preparando'), findsOneWidget);
    },
  );

  testWidgets(
    'Registration validates required fields and confirmation before calling backend',
    (tester) async {
      final repo = TestAuthRepository();
      addTearDown(repo.dispose);
      final container = await launch(tester, repository: repo);
      container.read(routerProvider).go('/register');
      await tester.pumpAndSettle();
      await submit(tester);
      expect(repo.registeredName, isNull);
      expect(find.text('Completa este campo.'), findsNWidgets(4));
      await tester.enterText(find.byKey(const Key('name')), 'Alex');
      await tester.enterText(
        find.byKey(const Key('email')),
        'alex@example.com',
      );
      await tester.enterText(find.byKey(const Key('password')), 'password123');
      await tester.enterText(
        find.byKey(const Key('confirmPassword')),
        'different',
      );
      await submit(tester);
      expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
      expect(repo.registeredName, isNull);
      await tester.enterText(
        find.byKey(const Key('confirmPassword')),
        'password123',
      );
      await submit(tester);
      expect(repo.registeredName, 'Alex');
      expect(find.byKey(const Key('checkVerification')), findsOneWidget);
      expect(repo.verificationCalls, 1);
    },
  );

  testWidgets(
    'Login errors are localized and sign out clears protected route',
    (tester) async {
      final repo = TestAuthRepository()
        ..errorCode = 'invalid-credential'
        ..verified = true;
      addTearDown(repo.dispose);
      final container = await launch(tester, repository: repo);
      container.read(routerProvider).go('/login');
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('email')),
        'alex@example.com',
      );
      await tester.enterText(find.byKey(const Key('password')), 'password123');
      await submit(tester);
      expect(
        find.textContaining('Revisa tu correo y contraseña'),
        findsOneWidget,
      );
      repo.errorCode = null;
      await submit(tester);
      expect(find.text('Mis tarjetas'), findsOneWidget);
      // Signing out lives in Settings now: it is a preference about the app,
      // not a field of the profile form it used to hang off.
      container.read(routerProvider).go('/settings');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Cerrar sesión'));
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('email')), findsOneWidget);
      container.read(routerProvider).go('/home');
      await tester.pumpAndSettle();
      expect(find.text('Mis tarjetas'), findsNothing);
    },
  );

  testWidgets('Recovery uses locale and does not expose account existence', (
    tester,
  ) async {
    final repo = TestAuthRepository();
    addTearDown(repo.dispose);
    final container = await launch(tester, repository: repo);
    container.read(routerProvider).go('/reset-password');
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('email')), 'alex@example.com');
    await submit(tester);
    expect(repo.resetCalls, 1);
    expect(repo.resetLanguage, 'es');
    expect(find.textContaining('Si existe una cuenta'), findsOneWidget);
  });

  testWidgets('Existing session skips intro', (tester) async {
    final repo = TestAuthRepository()
      ..current = const AuthIdentity(
        uid: 'existing',
        email: 'alex@example.com',
        emailVerified: true,
      );
    addTearDown(repo.dispose);
    await launch(tester, repository: repo);
    expect(find.text('Mis tarjetas'), findsOneWidget);
  });
}
