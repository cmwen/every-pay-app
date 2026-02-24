import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:everypay/domain/entities/category.dart';
import 'package:everypay/core/constants/category_defaults.dart';
import 'package:everypay/features/home/providers/expense_list_provider.dart';
import 'package:everypay/shared/providers/repository_providers.dart';

class FilterChips extends ConsumerWidget {
  const FilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(
      StreamProvider<List<Category>>(
        (ref) => ref.watch(categoryRepositoryProvider).watchCategories(),
      ),
    );
    final filter = ref.watch(expenseFilterProvider);

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('All'),
              selected: filter.categoryId == null,
              onSelected: (_) {
                ref
                    .read(expenseFilterProvider.notifier)
                    .setFilter(filter.copyWith(clearCategory: true));
              },
            ),
          ),
          ...categories.when(
            data: (cats) => cats.map((cat) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  avatar: Icon(
                    categoryIcon(cat.icon),
                    size: 16,
                    color: categoryColor(cat.colour),
                  ),
                  label: Text(cat.name),
                  selected: filter.categoryId == cat.id,
                  onSelected: (_) {
                    if (filter.categoryId == cat.id) {
                      ref
                          .read(expenseFilterProvider.notifier)
                          .setFilter(filter.copyWith(clearCategory: true));
                    } else {
                      ref
                          .read(expenseFilterProvider.notifier)
                          .setFilter(filter.copyWith(categoryId: cat.id));
                    }
                  },
                ),
              );
            }),
            loading: () => [],
            error: (_, __) => [],
          ),
        ],
      ),
    );
  }
}
