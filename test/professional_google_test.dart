import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reson/app/reson_app.dart';
import 'package:reson/features/cards/domain/professional_profile.dart';
import 'package:reson/features/cards/presentation/professional_summary.dart';
import 'auth_flow_test.dart' as support;
import 'verification_cards_test.dart' as verified;

void main() {
  test(
    'Professional data round-trips and missing legacy fields stay empty',
    () {
      expect(ProfessionalProfile.fromMap(null).isEmpty, isTrue);
      const profile = ProfessionalProfile(
        sector: 'Salud',
        specialty: 'Fisioterapia',
        workMode: 'Presencial',
        projects: [
          CareerEntry(title: 'Clínica accesible', organization: 'Comunidad'),
        ],
        certifications: [
          CareerEntry(title: 'Especialidad', organization: 'Instituto'),
        ],
        location: 'México',
        linkedin: 'https://www.linkedin.com/in/example',
        skills: 'Dart, UX',
        experience: [
          CareerEntry(
            title: 'Ingeniero',
            organization: 'Estudio',
            period: '2020–2024',
            details: 'Aplicaciones móviles',
          ),
        ],
        education: [
          CareerEntry(title: 'Ingeniería', organization: 'Universidad'),
        ],
      );
      expect(
        ProfessionalProfile.fromMap(profile.toMap()).toMap(),
        profile.toMap(),
      );
    },
  );
  testWidgets(
    'Google bypasses password validation and opens the verified session',
    (tester) async {
      final auth = support.TestAuthRepository()..verified = true;
      addTearDown(auth.dispose);
      final container = await support.launch(tester, repository: auth);
      container.read(routerProvider).go('/register');
      await tester.pumpAndSettle();
      final google = find.byKey(const Key('googleSignIn'));
      await tester.ensureVisible(google);
      await tester.tap(google);
      await tester.pumpAndSettle();
      expect(auth.googleCalls, 1);
      expect(auth.registeredName, isNull);
      expect(find.text('Mis tarjetas'), findsOneWidget);
    },
  );
  testWidgets('Closing the Google popup unlocks the form without an error', (
    tester,
  ) async {
    final auth = support.TestAuthRepository()
      ..errorCode = 'popup-closed-by-user';
    addTearDown(auth.dispose);
    final container = await support.launch(tester, repository: auth);
    container.read(routerProvider).go('/login');
    await tester.pumpAndSettle();
    final google = find.byKey(const Key('googleSignIn'));
    await tester.ensureVisible(google);
    await tester.tap(google);
    await tester.pumpAndSettle();
    expect(auth.googleCalls, 1);
    expect(tester.widget<OutlinedButton>(google).onPressed, isNotNull);
    expect(find.textContaining('Ocurrió'), findsNothing);
  });
  testWidgets(
    'Experience and education save, remain editable and appear in the profile',
    (tester) async {
      final auth = verified.session();
      addTearDown(auth.dispose);
      final cards = support.TestCardsRepository();
      final container = await support.launch(
        tester,
        repository: auth,
        cardsRepository: cards,
      );
      container.read(routerProvider).go('/cards/new');
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('card_label')), 'Mi perfil');
      await tester.enterText(
        find.byKey(const Key('professional_skills')),
        'Flutter, Diseño',
      );
      final addWork = find.byKey(const Key('add_experience'));
      await tester.ensureVisible(addWork);
      await tester.tap(addWork);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Puesto'),
        'Ingeniero',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Empresa').last,
        'Estudio Norte',
      );
      final addSchool = find.byKey(const Key('add_education'));
      await tester.ensureVisible(addSchool);
      await tester.tap(addSchool);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Título o formación'),
        'Ingeniería',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Institución'),
        'Universidad',
      );
      await tester.enterText(
        find.byKey(const Key('professional_sector')),
        'Construcción',
      );
      await tester.enterText(
        find.byKey(const Key('professional_specialty')),
        'Carpintería y restauración',
      );
      await tester.enterText(
        find.byKey(const Key('professional_workMode')),
        'Presencial',
      );
      await tester.ensureVisible(find.byKey(const Key('add_projects')));
      await tester.tap(find.byKey(const Key('add_projects')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(
          TextFormField,
          'Nombre del proyecto o certificación',
        ),
        'Restauración de un taller',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Empresa, cliente o entidad'),
        'Taller Norte',
      );
      final save = find.byKey(const Key('saveCard'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(cards.cards.single.professional.sector, 'Construcción');
      expect(
        cards.cards.single.professional.projects.single.title,
        'Restauración de un taller',
      );
      expect(
        cards.cards.single.professional.experience.single.title,
        'Ingeniero',
      );
      expect(
        cards.cards.single.professional.education.single.organization,
        'Universidad',
      );
      final summary = find.byType(ProfessionalSummary);
      expect(summary, findsOneWidget);
      await tester.ensureVisible(find.text('Perfil profesional'));
      await tester.tap(find.text('Perfil profesional'));
      await tester.pumpAndSettle();
      expect(find.text('Universidad'), findsOneWidget);
      container.read(routerProvider).go('/cards/${cards.cards.single.id}/edit');
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, 'Ingeniero'), findsOneWidget);
    },
  );
}
