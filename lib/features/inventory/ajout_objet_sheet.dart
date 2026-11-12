import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;

import '../../core/database/app_database.dart';
import '../../core/providers.dart';
import '../categories/category_tree.dart';

class AjoutObjetSheet extends ConsumerStatefulWidget {
  const AjoutObjetSheet({super.key, this.item});

  final Item? item;

  @override
  ConsumerState<AjoutObjetSheet> createState() => _AjoutObjetSheetState();
}

class _AjoutObjetSheetState extends ConsumerState<AjoutObjetSheet> {
  final _formKey = GlobalKey<FormState>();
  final _marqueCtrl = TextEditingController();
  final _modeleCtrl = TextEditingController();
  final _poidsCtrl = TextEditingController();
  int? _categoryId;

  @override
  void initState() {
    super.initState();
    _marqueCtrl.text = widget.item?.brand ?? '';
    _modeleCtrl.text = widget.item?.name ?? '';
    _poidsCtrl.text = widget.item?.weightGrams?.toString() ?? '';
    _categoryId = widget.item?.categoryId;
  }

  @override
  void dispose() {
    _marqueCtrl.dispose();
    _modeleCtrl.dispose();
    _poidsCtrl.dispose();
    super.dispose();
  }

  Future<void> _valider() async {
    if (!_formKey.currentState!.validate()) return;
    final marque = _marqueCtrl.text.trim();
    final modele = _modeleCtrl.text.trim();
    final poids = int.parse(_poidsCtrl.text.trim());
    final database = ref.read(databaseProvider);
    final companion = ItemsCompanion(
      name: Value(modele),
      brand: Value(marque.isEmpty ? null : marque),
      categoryId: Value(_categoryId),
      weightGrams: Value(poids),
      updatedAt: Value(DateTime.now()),
    );
    final item = widget.item;
    if (item == null) {
      await database.into(database.items).insert(
            ItemsCompanion.insert(
              name: modele,
              brand: Value(marque.isEmpty ? null : marque),
              categoryId: Value(_categoryId),
              weightGrams: Value(poids),
            ),
          );
    } else {
      await (database.update(database.items)
            ..where((row) => row.id.equals(item.id)))
          .write(companion);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.item == null ? 'Ajouter un objet' : 'Modifier l’objet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _marqueCtrl,
                autofocus: widget.item == null,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration:
                    const InputDecoration(labelText: 'Marque (optionnel)'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _modeleCtrl,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Modèle'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obligatoire' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _poidsCtrl,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _valider(),
                decoration: const InputDecoration(labelText: 'Poids (g)'),
                validator: (v) =>
                    (int.tryParse(v?.trim() ?? '') == null)
                        ? 'Nombre entier requis'
                        : null,
              ),
              const SizedBox(height: 14),
              categories.when(
                data: (list) => DropdownButtonFormField<int?>(
                  initialValue: _categoryId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Catégorie'),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Sans catégorie'),
                    ),
                    for (final entry in flattenCategoryTree(list))
                      DropdownMenuItem<int?>(
                        value: entry.category.id,
                        child: Text(
                          entry.path,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() => _categoryId = value),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => Text('Erreur : $error'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _valider,
                child: Text(widget.item == null ? 'Enregistrer' : 'Modifier'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}