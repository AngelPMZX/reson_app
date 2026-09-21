import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reson/app/reson_app.dart';
import 'package:reson/features/profile/personal_profile.dart';
import 'package:reson/features/cards/presentation/card_preview.dart';
import 'auth_flow_test.dart' as support;
import 'verification_cards_test.dart' as verified;

class TestProfiles implements PersonalProfileRepository {
  PersonalProfile? current;
  Completer<void>? pending;
  int calls = 0;
  final events = StreamController<PersonalProfile?>.broadcast();
  @override
  Stream<PersonalProfile?> watch() async* {
    yield current;
    yield* events.stream;
  }

  @override
  Future<void> save(PersonalProfile profile) async {
    calls++;
    if (pending != null) await pending!.future;
    current = profile;
    events.add(profile);
  }
}

void main() {
  test('Photo choices and optional details survive serialization', () {
    final old = PersonalProfile.fromMap({'name': 'Alex'});
    expect(old.photoSource, 'google');
    expect(old.photoPath, '');
    final profile = PersonalProfile(
      fields: {
        'name': 'Alex',
        'languages': 'Español, English',
        'services': 'Diseño',
      },
      photoSource: 'upload',
      photoPath: 'users/owner/profile/123',
      availability: 'projects',
    );
    final restored = PersonalProfile.fromMap(profile.toMap());
    expect(restored.value('languages'), 'Español, English');
    expect(restored.availability, 'projects');
    expect(
      restored.newCard(fallbackName: '', fallbackEmail: '').photoPath,
      'users/owner/profile/123',
    );
    final removed = PersonalProfile.fromMap(
      PersonalProfile(photoSource: 'none').toMap(),
    );
    expect(removed.photoSource, 'none');
    expect(removed.newCard(fallbackName: '', fallbackEmail: '').photoPath, '');
  });

  testWidgets(
    'Slow profile save keeps newer edits and prevents duplicate writes',
    (tester) async {
      final auth = verified.session();
      addTearDown(auth.dispose);
      final profiles = TestProfiles()..pending = Completer<void>();
      addTearDown(profiles.events.close);
      final container = await support.launch(
        tester,
        repository: auth,
        personalRepository: profiles,
        size: const Size(390, 1000),
      );
      container.read(routerProvider).go('/profile');
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('profile_name')),
        'Primera versión',
      );
      final save = find.widgetWithText(FilledButton, 'Guardar perfil');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pump();
      await tester.pump(const Duration(seconds: 21));
      await tester.pumpAndSettle();
      expect(find.textContaining('Aún no podemos confirmar'), findsOneWidget);
      expect(tester.widget<FilledButton>(save).onPressed, isNull);
      await tester.enterText(
        find.byKey(const ValueKey('profile_name')),
        'Borrador nuevo',
      );
      profiles.pending!.complete();
      await tester.pumpAndSettle();
      expect(profiles.calls, 1);
      expect(profiles.current!.value('name'), 'Primera versión');
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('profile_name')))
            .controller!
            .text,
        'Borrador nuevo',
      );
      expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
    },
  );

  testWidgets(
    'Profile seeds new cards without changing saved cards or login email',
    (tester) async {
      final auth = verified.session();
      addTearDown(auth.dispose);
      final profiles = TestProfiles();
      addTearDown(profiles.events.close);
      final cards = support.TestCardsRepository();
      final container = await support.launch(
        tester,
        repository: auth,
        cardsRepository: cards,
        personalRepository: profiles,
      );
      expect(find.byTooltip('Cerrar sesión'), findsNothing);
      container.read(routerProvider).go('/profile');
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('profile_name')),
        'Alex Perfil',
      );
      await tester.enterText(
        find.byKey(const ValueKey('profile_role')),
        'Arquitecto',
      );
      await tester.enterText(find.byKey(const ValueKey('profile_email')), '');
      final save = find.text('Guardar perfil');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(profiles.current!.value('role'), 'Arquitecto');
      expect(auth.current!.email, 'owner@example.com');
      container.read(routerProvider).go('/cards/new');
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('card_role')))
            .controller!
            .text,
        'Arquitecto',
      );
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('card_email')))
            .controller!
            .text,
        '',
      );
      await tester.enterText(find.byKey(const Key('card_label')), 'Mi trabajo');
      final button = find.byKey(const Key('saveCard'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(cards.cards.single.role, 'Arquitecto');
      await profiles.save(
        PersonalProfile(fields: {'name': 'Otro nombre', 'role': 'Director'}),
      );
      await tester.pumpAndSettle();
      expect(cards.cards.single.displayName, 'Alex Perfil');
      expect(
        tester.widget<CardPreview>(find.byType(CardPreview)).card.role,
        'Arquitecto',
      );
      container.read(routerProvider).go('/cards/new');
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('card_role')))
            .controller!
            .text,
        'Director',
      );
    },
  );
  testWidgets('Unverified user cannot access personal profile', (tester) async {
    final auth = verified.session(verified: false);
    addTearDown(auth.dispose);
    final container = await support.launch(tester, repository: auth);
    container.read(routerProvider).go('/profile');
    await tester.pumpAndSettle();
    expect(
      container.read(routerProvider).routeInformationProvider.value.uri.path,
      '/verify-email',
    );
    expect(find.byKey(const ValueKey('profile_name')), findsNothing);
  });
}
