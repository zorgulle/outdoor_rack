import '../../core/database/app_database.dart';

class CategoryTreeEntry {
  const CategoryTreeEntry({
    required this.category,
    required this.depth,
    required this.path,
  });

  final Category category;
  final int depth;
  final String path;
}

List<CategoryTreeEntry> flattenCategoryTree(List<Category> categories) {
  final childrenByParent = <int?, List<Category>>{};
  for (final category in categories) {
    childrenByParent.putIfAbsent(category.parentId, () => []).add(category);
  }
  for (final children in childrenByParent.values) {
    children.sort((a, b) {
      final order = a.sortOrder.compareTo(b.sortOrder);
      return order != 0 ? order : a.name.compareTo(b.name);
    });
  }

  final entries = <CategoryTreeEntry>[];
  void visit(int? parentId, int depth, String parentPath, Set<int> visited) {
    for (final category in childrenByParent[parentId] ?? const <Category>[]) {
      if (!visited.add(category.id)) continue;
      final path = parentPath.isEmpty
          ? category.name
          : '$parentPath / ${category.name}';
      entries.add(
        CategoryTreeEntry(category: category, depth: depth, path: path),
      );
      visit(category.id, depth + 1, path, visited);
    }
  }

  visit(null, 0, '', <int>{});
  return entries;
}

Set<int> categoryAndDescendantIds(List<Category> categories, int categoryId) {
  final childrenByParent = <int?, List<Category>>{};
  for (final category in categories) {
    childrenByParent.putIfAbsent(category.parentId, () => []).add(category);
  }

  final result = <int>{};
  void visit(int id) {
    if (!result.add(id)) return;
    for (final child in childrenByParent[id] ?? const <Category>[]) {
      visit(child.id);
    }
  }

  visit(categoryId);
  return result;
}