import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database/app_database.dart';
import 'package:drift/drift.dart'
  show OrderingTerm, innerJoin, leftOuterJoin;

/// Instance unique de la base, fermée proprement à la destruction.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Liste des catégories (stream réactif) : exemple d'usage pour L2.
final categoriesProvider = StreamProvider<List<Category>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.categories)
        ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
      .watch();
});

/// Liste des objets (stream réactif).
final itemsProvider = StreamProvider<List<Item>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.items)
        ..orderBy([(item) => OrderingTerm.asc(item.name)]))
      .watch();
});

class PackSummary {
  const PackSummary({required this.pack, required this.totalWeightGrams});

  final Pack pack;
  final int totalWeightGrams;
}

class PackItemEntry {
  const PackItemEntry({required this.packItem, required this.item});

  final PackItem packItem;
  final Item item;
}

final packSummariesProvider = StreamProvider<List<PackSummary>>((ref) {
  final db = ref.watch(databaseProvider);
  final query = db.select(db.packs).join([
    leftOuterJoin(db.packItems, db.packItems.packId.equalsExp(db.packs.id)),
    leftOuterJoin(db.items, db.items.id.equalsExp(db.packItems.itemId)),
  ])..orderBy([OrderingTerm.asc(db.packs.name)]);

  return query.watch().map((rows) {
    final summaries = <int, PackSummary>{};
    for (final row in rows) {
      final pack = row.readTable(db.packs);
      final packItem = row.readTableOrNull(db.packItems);
      final item = row.readTableOrNull(db.items);
      final weight =
          (item?.weightGrams ?? 0) * (packItem?.quantityCarried ?? 0);
      final previous = summaries[pack.id]?.totalWeightGrams ?? 0;
      summaries[pack.id] = PackSummary(
        pack: pack,
        totalWeightGrams: previous + weight,
      );
    }
    return summaries.values.toList();
  });
});

final packContentsProvider =
    StreamProvider.family<List<PackItemEntry>, int>((ref, packId) {
  final db = ref.watch(databaseProvider);
  final query = db.select(db.packItems).join([
    innerJoin(db.items, db.items.id.equalsExp(db.packItems.itemId)),
  ])
    ..where(db.packItems.packId.equals(packId))
    ..orderBy([OrderingTerm.asc(db.items.name)]);

  return query.watch().map(
        (rows) => [
          for (final row in rows)
            PackItemEntry(
              packItem: row.readTable(db.packItems),
              item: row.readTable(db.items),
            ),
        ],
      );
});