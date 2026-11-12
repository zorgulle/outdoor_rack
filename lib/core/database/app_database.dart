import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Categories, Items, Packs, PackItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Constructeur pour les tests (base en mémoire)
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedCategories();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(categories, categories.parentId);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  Future<void> _seedCategories() async {
    const defaults = [
      'Abri',
      'Couchage',
      'Sac à dos',
      'Vêtements',
      'Cuisine',
      'Électronique',
      'Hygiène',
      'Sécurité',
      'Autre',
    ];
    await batch((b) {
      b.insertAll(
        categories,
        [
          for (var i = 0; i < defaults.length; i++)
            CategoriesCompanion.insert(name: defaults[i], sortOrder: Value(i)),
        ],
      );
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'sacalege.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}