// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';

import 'package:outdoorrack/app.dart';
import 'package:outdoorrack/core/database/app_database.dart';
import 'package:outdoorrack/core/providers.dart';
import 'package:outdoorrack/features/packs/packs_screen.dart';

void main() {
  testWidgets('adding an item updates the inventory', (tester) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: const App(),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Ajouter'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Acme');
    await tester.enterText(find.byType(TextFormField).at(1), 'Tente');
    await tester.enterText(find.byType(TextFormField).at(2), '1250');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Acme Tente'), findsOneWidget);

    await tester.longPress(find.text('Acme Tente'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), 'Abri');
    await tester.tap(find.text('Modifier'));
    await tester.pumpAndSettle();
    expect(find.text('Acme Abri'), findsOneWidget);

    await tester.drag(find.text('Acme Abri'), const Offset(-250, 0));
    await tester.pumpAndSettle();
    expect(find.text('Supprimer cet objet ?'), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(find.text('Acme Abri'), findsOneWidget);

    await tester.drag(find.text('Acme Abri'), const Offset(-250, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();
    expect(find.text('Acme Abri'), findsNothing);
  });

  testWidgets('a pack shows the weight of its items', (tester) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await database.into(database.items).insert(
          ItemsCompanion.insert(name: 'Tente', weightGrams: const Value(1250)),
        );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: const MaterialApp(home: PacksScreen()),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Nouveau sac'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Week-end');
    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ajouter des objets'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile).first);
    await tester.tap(find.text('Ajouter (1)'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Augmenter la quantité'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('2 kg 500 g'), findsNWidgets(2));

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Week-end'), findsOneWidget);
    expect(find.text('Poids total : 2 kg 500 g'), findsOneWidget);
  });
}
