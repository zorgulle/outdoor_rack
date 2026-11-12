import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers.dart';
import 'pack_detail_screen.dart';

class PacksScreen extends ConsumerWidget {
  const PacksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packs = ref.watch(packSummariesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mes sacs')),
      body: packs.when(
        data: (list) => list.isEmpty
            ? const Center(child: Text('Aucun sac pour le moment'))
            : ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final summary = list[index];
                  return ListTile(
                    leading: const Icon(Icons.backpack_outlined),
                    title: Text(summary.pack.name),
                    subtitle: Text(
                      'Poids total : ${formatPackWeight(summary.totalWeightGrams)}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openPack(context, summary.pack),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur : $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createPack(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau sac'),
      ),
    );
  }

  Future<void> _createPack(BuildContext context, WidgetRef ref) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _PackNameDialog(),
    );
    if (name == null) return;

    final database = ref.read(databaseProvider);
    final packId = await database.into(database.packs).insert(
          PacksCompanion.insert(name: name),
        );
    if (!context.mounted) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => PackDetailScreen(packId: packId, packName: name),
      ),
    );
  }

  void _openPack(BuildContext context, Pack pack) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => PackDetailScreen(packId: pack.id, packName: pack.name),
      ),
    );
  }
}

String formatPackWeight(int grams) {
  if (grams < 1000) return '$grams g';
  final kilograms = grams ~/ 1000;
  final remainingGrams = grams % 1000;
  return remainingGrams == 0
      ? '$kilograms kg'
      : '$kilograms kg $remainingGrams g';
}

class _PackNameDialog extends StatefulWidget {
  const _PackNameDialog();

  @override
  State<_PackNameDialog> createState() => _PackNameDialogState();
}

class _PackNameDialogState extends State<_PackNameDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nouveau sac'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _submit(),
          decoration: const InputDecoration(labelText: 'Nom du sac'),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Nom obligatoire'
              : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Créer')),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, _nameController.text.trim());
  }
}