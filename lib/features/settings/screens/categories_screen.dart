import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:everypay/core/constants/category_defaults.dart';
import 'package:everypay/core/utils/id_generator.dart';
import 'package:everypay/domain/entities/category.dart';
import 'package:everypay/shared/providers/repository_providers.dart';
import 'package:everypay/shared/widgets/confirm_dialog.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(
      StreamProvider<List<Category>>(
        (ref) => ref.watch(categoryRepositoryProvider).watchCategories(),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategoryDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: categoriesAsync.when(
        data: (categories) => ListView.builder(
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: categoryColor(cat.colour).withAlpha(30),
                child: Icon(
                  categoryIcon(cat.icon),
                  color: categoryColor(cat.colour),
                  size: 20,
                ),
              ),
              title: Text(cat.name),
              trailing: cat.isDefault
                  ? const Chip(label: Text('Default'))
                  : IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        final confirmed = await showConfirmDialog(
                          context,
                          title: 'Delete Category',
                          content: 'Delete "${cat.name}"?',
                        );
                        if (confirmed) {
                          await ref
                              .read(categoryRepositoryProvider)
                              .deleteCategory(cat.id);
                        }
                      },
                    ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _showAddCategoryDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final nameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Category'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Category name',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      final now = DateTime.now();
      await ref
          .read(categoryRepositoryProvider)
          .upsertCategory(
            Category(
              id: generateId(),
              name: result.trim(),
              icon: 'category',
              colour: '#546E7A',
              sortOrder: 100,
              createdAt: now,
              updatedAt: now,
            ),
          );
    }
  }
}
