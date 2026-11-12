import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers.dart';
import 'packs_screen.dart' show formatPackWeight;

class PackDetailScreen extends ConsumerWidget {
  const PackDetailScreen({
    super.key,
    required this.packId,
    required this.packName,
  });

  final int packId;
  final String packName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contents = ref.watch(packContentsProvider(packId));

    return Scaffold(
      appBar: AppBar(title: Text(packName)),
      body: contents.when(
        data: (entries) {
          final totalWeight = entries.fold<int>(
            0,
            (total, entry) => total +
                (entry.item.weightGrams ?? 0) * entry.packItem.quantityCarried,
          );
          if (entries.isEmpty) {
            return const Center(child: Text('Aucun objet dans ce sac'));
          }
          return Column(
            children: [
              ListTile(
                title: const Text('Poids total'),
                trailing: Text(
                  formatPackWeight(totalWeight),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) => _PackItemTile(
                    entry: entries[index],
                    onDecrement: () => _changeQuantity(
                      ref,
                      entries[index],
                      entries[index].packItem.quantityCarried - 1,
                    ),
                    onIncrement: () => _changeQuantity(
                      ref,
                      entries[index],
                      entries[index].packItem.quantityCarried + 1,
                    ),
                    onRemove: () => _removePackItem(ref, entries[index]),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur : $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => _AddPackItemsSheet(packId: packId),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter des objets'),
      ),
    );
  }
}

class _PackItemTile extends StatelessWidget {
  const _PackItemTile({
    required this.entry,
    required this.onDecrement,
    required this.onIncrement,
    required this.onRemove,
  });

  final PackItemEntry entry;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final brand = entry.item.brand;
    final itemName = brand == null || brand.isEmpty
        ? entry.item.name
        : '$brand ${entry.item.name}';
    final weight = entry.item.weightGrams == null
        ? 'Poids inconnu'
        : formatPackWeight(
            entry.item.weightGrams! * entry.packItem.quantityCarried,
          );

    return ListTile(
      title: Text(itemName),
      subtitle: Text(weight),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Diminuer la quantité',
            onPressed: onDecrement,
            icon: const Icon(Icons.remove),
          ),
          Text('${entry.packItem.quantityCarried}'),
          IconButton(
            tooltip: 'Augmenter la quantité',
            onPressed: onIncrement,
            icon: const Icon(Icons.add),
          ),
          IconButton(
            tooltip: 'Retirer du sac',
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

class _AddPackItemsSheet extends ConsumerStatefulWidget {
  const _AddPackItemsSheet({required this.packId});

  final int packId;

  @override
  ConsumerState<_AddPackItemsSheet> createState() => _AddPackItemsSheetState();
}

class _AddPackItemsSheetState extends ConsumerState<_AddPackItemsSheet> {
  final _selectedIds = <int>{};
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(itemsProvider);
    final contents = ref.watch(packContentsProvider(widget.packId));
    final height = MediaQuery.sizeOf(context).height * 0.75;

    return SafeArea(
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ajouter des objets',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: items.when(
                  data: (availableItems) => contents.when(
                    data: (currentEntries) {
                      final currentIds = currentEntries
                          .map((entry) => entry.item.id)
                          .toSet();
                      final choices = availableItems
                          .where((item) => !currentIds.contains(item.id))
                          .toList();
                      if (choices.isEmpty) {
                        return const Center(
                          child: Text('Aucun autre objet disponible'),
                        );
                      }
                      return ListView.builder(
                        itemCount: choices.length,
                        itemBuilder: (context, index) {
                          final item = choices[index];
                          final title = item.brand == null || item.brand!.isEmpty
                              ? item.name
                              : '${item.brand} ${item.name}';
                          return CheckboxListTile(
                            value: _selectedIds.contains(item.id),
                            title: Text(title),
                            subtitle: Text(
                              item.weightGrams == null
                                  ? 'Poids inconnu'
                                  : formatPackWeight(item.weightGrams!),
                            ),
                            onChanged: (selected) => setState(() {
                              if (selected == true) {
                                _selectedIds.add(item.id);
                              } else {
                                _selectedIds.remove(item.id);
                              }
                            }),
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (error, _) => Center(child: Text('Erreur : $error')),
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(child: Text('Erreur : $error')),
                ),
              ),
              FilledButton(
                onPressed: _selectedIds.isEmpty || _isSaving ? null : _save,
                child: Text(
                  _isSaving ? 'Ajout...' : 'Ajouter (${_selectedIds.length})',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final database = ref.read(databaseProvider);
    await database.batch((batch) {
      batch.insertAll(
        database.packItems,
        [
          for (final itemId in _selectedIds)
            PackItemsCompanion.insert(packId: widget.packId, itemId: itemId),
        ],
      );
    });
    if (mounted) Navigator.pop(context);
  }
}

Future<void> _changeQuantity(
  WidgetRef ref,
  PackItemEntry entry,
  int quantity,
) async {
  final database = ref.read(databaseProvider);
  if (quantity < 1) {
    await _removePackItem(ref, entry);
    return;
  }
  await (database.update(database.packItems)
        ..where((row) => row.id.equals(entry.packItem.id)))
      .write(PackItemsCompanion(quantityCarried: Value(quantity)));
}

Future<void> _removePackItem(WidgetRef ref, PackItemEntry entry) async {
  final database = ref.read(databaseProvider);
  await (database.delete(database.packItems)
        ..where((row) => row.id.equals(entry.packItem.id)))
      .go();
}