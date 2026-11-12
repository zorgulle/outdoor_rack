import 'package:drift/drift.dart';

/// Source du poids : mesuré / fabricant / estimé
enum WeightSource { measured, manufacturer, estimated }

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 60)();
  IntColumn get parentId => integer().nullable().references(Categories, #id)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

class Items extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 120)();
  TextColumn get brand => text().nullable()();
  TextColumn get barcode => text().nullable()();
  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();
  IntColumn get weightGrams => integer().nullable()();
  IntColumn get weightSource =>
      intEnum<WeightSource>().withDefault(const Constant(2))(); // estimated
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  TextColumn get notes => text().nullable()();
  TextColumn get photoPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class Packs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 120)();
  TextColumn get season => text().nullable()();
  TextColumn get tripType => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class PackItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get packId =>
      integer().references(Packs, #id, onDelete: KeyAction.cascade)();
  IntColumn get itemId =>
      integer().references(Items, #id, onDelete: KeyAction.cascade)();
  IntColumn get quantityCarried => integer().withDefault(const Constant(1))();
  BoolColumn get isChecked => boolean().withDefault(const Constant(false))();
}

class Objets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get marque => text().nullable()();
  TextColumn get modele => text()();
  IntColumn get poidsGrammes => integer()();
}