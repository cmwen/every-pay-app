import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:everypay/core/constants/category_defaults.dart';
import 'package:everypay/data/templates/service_templates.dart';
import 'package:everypay/domain/entities/service_template.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ServiceLibraryScreen extends ConsumerStatefulWidget {
  const ServiceLibraryScreen({super.key});

  @override
  ConsumerState<ServiceLibraryScreen> createState() =>
      _ServiceLibraryScreenState();
}

class _ServiceLibraryScreenState extends ConsumerState<ServiceLibraryScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Group templates by category
    final filtered = serviceTemplates.where((t) {
      if (_searchQuery.isEmpty) return true;
      return t.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (t.provider?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false);
    }).toList();

    final grouped = <String, List<ServiceTemplate>>{};
    for (final t in filtered) {
      grouped.putIfAbsent(t.defaultCategoryId, () => []).add(t);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Choose a Service')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBar(
              hintText: 'Search services...',
              leading: const Icon(Icons.search),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: grouped.isEmpty
                ? const Center(child: Text('No services match your search.'))
                : ListView.builder(
                    itemCount: grouped.length,
                    itemBuilder: (context, index) {
                      final categoryId = grouped.keys.elementAt(index);
                      final templates = grouped[categoryId]!;
                      final category = defaultCategories.firstWhere(
                        (c) => c.id == categoryId,
                        orElse: () => defaultCategories.last,
                      );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              category.name.toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          ...templates.map((template) {
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: categoryColor(
                                  category.colour,
                                ).withAlpha(30),
                                child: Icon(
                                  categoryIcon(category.icon),
                                  color: categoryColor(category.colour),
                                  size: 20,
                                ),
                              ),
                              title: Text(template.name),
                              subtitle: template.provider != null
                                  ? Text(template.provider!)
                                  : null,
                              trailing: Text(
                                template.defaultBillingCycle,
                                style: theme.textTheme.bodySmall,
                              ),
                              onTap: () => _selectTemplate(template),
                            );
                          }),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _selectTemplate(ServiceTemplate template) {
    // Pop back to add expense and pass template data
    context.pop(template);
  }
}
