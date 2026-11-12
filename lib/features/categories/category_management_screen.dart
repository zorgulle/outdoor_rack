import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers.dart';
import 'category_tree.dart';

class CategoryManagementScreen extends ConsumerWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catégories'),
        actions: [
          IconButton(
            tooltip: 'Ajouter une catégorie',
            onPressed: categoriesAsync.asData == null
                ? null
                : () => _editCategory(
                      context,
                      ref,
                      categoriesAsync.asData!.value,
                      null,
                    ),
            icon: const Icon(Icons.create_new_folder_outlined),
          ),
        ],
      ),
      body: categoriesAsync.when(
        data: (categories) => categories.isEmpty
            ? const Center(child: Text('Aucune catégorie'))
            : _buildCategoryList(context, ref, categories),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur : $error')),
      ),
    );
  }

  Widget _buildCategoryList(
    BuildContext context,
    WidgetRef ref,
    List<Category> categories,
  ) {
    final entries = flattenCategoryTree(categories);
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final siblings = _siblings(categories, entry.category.parentId);
        final siblingIndex = siblings.indexWhere(
          (category) => category.id == entry.category.id,
        );
        return Padding(
          padding: EdgeInsets.only(left: 16.0 + entry.depth * 20, right: 8),
          child: ListTile(
            leading: Icon(
              entry.depth == 0 ? Icons.folder_outlined : Icons.subdirectory_arrow_right,
            ),
            title: Text(entry.category.name),
            trailing: PopupMenuButton<_CategoryAction>(
              tooltip: 'Actions sur ${entry.category.name}',
              onSelected: (action) {
                switch (action) {
                  case _CategoryAction.addChild:
                    _editCategory(
                      context,
                      ref,
                      categories,
                      null,
                      initialParentId: entry.category.id,
                    );
                  case _CategoryAction.edit:
                    _editCategory(context, ref, categories, entry.category);
                  case _CategoryAction.moveUp:
                    _moveCategory(ref, siblings, siblingIndex, -1);
                  case _CategoryAction.moveDown:
                    _moveCategory(ref, siblings, siblingIndex, 1);
                  case _CategoryAction.delete:
                    _deleteCategory(context, ref, categories, entry.category);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: _CategoryAction.addChild,
                  child: Text('Ajouter une sous-catégorie'),
                ),
                const PopupMenuItem(
                  value: _CategoryAction.edit,
                  child: Text('Renommer ou déplacer'),
                ),
                if (siblingIndex > 0)
                  const PopupMenuItem(
                    value: _CategoryAction.moveUp,
                    child: Text('Monter'),
                  ),
                if (siblingIndex >= 0 && siblingIndex < siblings.length - 1)
                  const PopupMenuItem(
                    value: _CategoryAction.moveDown,
                    child: Text('Descendre'),
                  ),
                const PopupMenuItem(
                  value: _CategoryAction.delete,
                  child: Text('Supprimer'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

enum _CategoryAction { addChild, edit, moveUp, moveDown, delete }

class _CategoryDraft {
  const _CategoryDraft(this.name, this.parentId);

  final String name;
  final int? parentId;
}

class _CategoryEditorDialog extends StatefulWidget {
  const _CategoryEditorDialog({
    required this.category,
    required this.categories,
    required this.initialParentId,
  });

  final Category? category;
  final List<CategoryTreeEntry> categories;
  final int? initialParentId;

  @override
  State<_CategoryEditorDialog> createState() => _CategoryEditorDialogState();
}

class _CategoryEditorDialogState extends State<_CategoryEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late int? _parentId = widget.initialParentId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.category == null ? 'Nouvelle catégorie' : 'Catégorie'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nom'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Nom obligatoire'
                  : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: _parentId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Catégorie parente'),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('À la racine'),
                ),
                for (final entry in widget.categories)
                  DropdownMenuItem<int?>(
                    value: entry.category.id,
                    child: Text(entry.path, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (value) => setState(() => _parentId = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              _CategoryDraft(_nameController.text.trim(), _parentId),
            );
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}

Future<void> _editCategory(
  BuildContext context,
  WidgetRef ref,
  List<Category> categories,
  Category? category, {
  int? initialParentId,
}) async {
  final excludedIds = category == null
      ? <int>{}
      : categoryAndDescendantIds(categories, category.id);
  final selectable = flattenCategoryTree(
    categories.where((item) => !excludedIds.contains(item.id)).toList(),
  );
  final draft = await showDialog<_CategoryDraft>(
    context: context,
    builder: (_) => _CategoryEditorDialog(
      category: category,
      categories: selectable,
      initialParentId: category?.parentId ?? initialParentId,
    ),
  );
  if (draft == null) return;

  final database = ref.read(databaseProvider);
  final parentChanged = category != null && category.parentId != draft.parentId;
  final sortOrder = category != null && !parentChanged
      ? category.sortOrder
      : _nextSortOrder(categories, draft.parentId);
  if (category == null) {
    await database.into(database.categories).insert(
          CategoriesCompanion.insert(
            name: draft.name,
            parentId: Value(draft.parentId),
            sortOrder: Value(sortOrder),
          ),
        );
  } else {
    await (database.update(database.categories)
          ..where((item) => item.id.equals(category.id)))
        .write(
      CategoriesCompanion(
        name: Value(draft.name),
        parentId: Value(draft.parentId),
        sortOrder: Value(sortOrder),
      ),
    );
  }
}

List<Category> _siblings(List<Category> categories, int? parentId) {
  final siblings = categories
      .where((category) => category.parentId == parentId)
      .toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  return siblings;
}

int _nextSortOrder(List<Category> categories, int? parentId) {
  final siblings = _siblings(categories, parentId);
  return siblings.isEmpty ? 0 : siblings.last.sortOrder + 1;
}

Future<void> _moveCategory(
  WidgetRef ref,
  List<Category> siblings,
  int oldIndex,
  int offset,
) async {
  final newIndex = oldIndex + offset;
  if (oldIndex < 0 || newIndex < 0 || newIndex >= siblings.length) return;
  final reordered = [...siblings];
  final moved = reordered.removeAt(oldIndex);
  reordered.insert(newIndex, moved);
  final database = ref.read(databaseProvider);
  await database.transaction(() async {
    for (var index = 0; index < reordered.length; index++) {
      await (database.update(database.categories)
            ..where((item) => item.id.equals(reordered[index].id)))
          .write(CategoriesCompanion(sortOrder: Value(index)));
    }
  });
}

Future<void> _deleteCategory(
  BuildContext context,
  WidgetRef ref,
  List<Category> categories,
  Category category,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Supprimer la catégorie ?'),
      content: Text(
        'Les sous-catégories seront remontées d’un niveau et les objets '
        'seront conservés sans catégorie.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Supprimer'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  final database = ref.read(databaseProvider);
  await database.transaction(() async {
    await (database.update(database.items)
          ..where((item) => item.categoryId.equals(category.id)))
        .write(const ItemsCompanion(categoryId: Value(null)));
    await (database.update(database.categories)
          ..where((item) => item.parentId.equals(category.id)))
        .write(CategoriesCompanion(parentId: Value(category.parentId)));
    await (database.delete(database.categories)
          ..where((item) => item.id.equals(category.id)))
        .go();

    final remainingSiblings = [
      ..._siblings(categories, category.parentId)
          .where((item) => item.id != category.id),
      ..._siblings(categories, category.id),
    ];
    for (var index = 0; index < remainingSiblings.length; index++) {
      await (database.update(database.categories)
            ..where((item) => item.id.equals(remainingSiblings[index].id)))
          .write(CategoriesCompanion(sortOrder: Value(index)));
    }
  });
}