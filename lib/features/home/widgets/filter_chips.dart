import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:everypay/core/constants/category_defaults.dart';
import 'package:everypay/domain/entities/payment_method.dart';
import 'package:everypay/features/home/providers/expense_list_provider.dart';
import 'package:everypay/shared/providers/repository_providers.dart';
import 'package:everypay/shared/widgets/payment_method_avatar.dart';

class FilterChips extends ConsumerWidget {
  const FilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final methodsAsync = ref.watch(allPaymentMethodsProvider);
    final filter = ref.watch(expenseFilterProvider);

    final methods = switch (methodsAsync) {
      AsyncData(:final value) => value,
      _ => <PaymentMethod>[],
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row 1: Category chips
        SizedBox(
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
                error: (_, _) => [],
              ),
            ],
          ),
        ),

        // Row 2: Payment method chips — only shown when ≥1 method exists
        if (methods.isNotEmpty)
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                children: [
                  // "All" chip for payment methods
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      avatar: const Icon(Icons.credit_card, size: 14),
                      label: const Text('All', style: TextStyle(fontSize: 12)),
                      selected: filter.paymentMethodId == null,
                      onSelected: (_) {
                        ref
                            .read(expenseFilterProvider.notifier)
                            .setFilter(
                              filter.copyWith(clearPaymentMethod: true),
                            );
                      },
                    ),
                  ),
                  ...methods.map((method) {
                    final label = method.last4Digits != null
                        ? '${method.name.length > 12 ? method.name.substring(0, 12) : method.name}  ••${method.last4Digits}'
                        : (method.name.length > 14
                              ? method.name.substring(0, 14)
                              : method.name);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        avatar: ExcludeSemantics(
                          child: PaymentMethodAvatar(
                            paymentMethod: method,
                            size: 16,
                          ),
                        ),
                        label: Text(
                          label,
                          style: const TextStyle(fontSize: 12),
                        ),
                        selected: filter.paymentMethodId == method.id,
                        onSelected: (_) {
                          if (filter.paymentMethodId == method.id) {
                            ref
                                .read(expenseFilterProvider.notifier)
                                .setFilter(
                                  filter.copyWith(clearPaymentMethod: true),
                                );
                          } else {
                            ref
                                .read(expenseFilterProvider.notifier)
                                .setFilter(
                                  filter.copyWith(paymentMethodId: method.id),
                                );
                          }
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
