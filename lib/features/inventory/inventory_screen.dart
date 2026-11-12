import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../categories/category_management_screen.dart';
import 'ajout_objet_sheet.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(itemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon matériel'),
        actions: [
          IconButton(
            tooltip: 'Gérer les catégories',
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => const CategoryManagementScreen(),
              ),
            ),
            icon: const Icon(Icons.account_tree_outlined),
          ),
        ],
      ),
      body: items.when(
        data: (list) => ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final item = list[i];
            final title = item.brand?.isNotEmpty == true
                ? '${item.brand} ${item.name}'
                : item.name;
            return Dismissible(
              key: ValueKey(item.id),
              direction: DismissDirection.endToStart,
              dismissThresholds: const {
                DismissDirection.endToStart: 0.2,
              },
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                color: Theme.of(context).colorScheme.errorContainer,
                child: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
              confirmDismiss: (_) => showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Supprimer cet objet ?'),
                  content: Text('« $title » sera supprimé de l’inventaire.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Annuler'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('Supprimer'),
                    ),
                  ],
                ),
              ),
              onDismissed: (_) {
                final database = ref.read(databaseProvider);
                (database.delete(database.items)
                      ..where((row) => row.id.equals(item.id)))
                    .go();
              },
              child: ListTile(
                leading: const Icon(Icons.backpack_outlined),
                title: Text(title),
                onLongPress: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => AjoutObjetSheet(item: item),
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => const AjoutObjetSheet(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
    );
  }
}