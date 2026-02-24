import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:everypay/core/services/export_service.dart';
import 'package:everypay/shared/providers/repository_providers.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  bool _isExporting = false;
  final bool _isImporting = false;

  Future<void> _exportJson() async {
    setState(() => _isExporting = true);
    try {
      final service = ExportService(
        expenseRepo: ref.read(expenseRepositoryProvider),
        categoryRepo: ref.read(categoryRepositoryProvider),
      );
      final json = await service.exportJson();
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
          '${dir.path}/everypay_export_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(json);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'Every-Pay Export',
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportCsv() async {
    setState(() => _isExporting = true);
    try {
      final service = ExportService(
        expenseRepo: ref.read(expenseRepositoryProvider),
        categoryRepo: ref.read(categoryRepositoryProvider),
      );
      final csv = await service.exportCsv();
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
          '${dir.path}/everypay_export_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'Every-Pay Export (CSV)',
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV export failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _importJson() async {
    // In a real app, use file_picker to select file.
    // For now, show a dialog explaining the import process.
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Data'),
        content: const Text(
          'To import data, place a JSON export file in the app\'s '
          'documents directory. A file picker will be available in a '
          'future update.\n\n'
          'Import will merge data with existing records (upsert).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export & Import')),
      body: ListView(
        children: [
          _SectionHeader(title: 'EXPORT'),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('Export as JSON'),
            subtitle: const Text('Full backup with all data'),
            trailing: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
            onTap: _isExporting ? null : _exportJson,
          ),
          ListTile(
            leading: const Icon(Icons.table_chart),
            title: const Text('Export as CSV'),
            subtitle: const Text('Spreadsheet-friendly format'),
            trailing: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
            onTap: _isExporting ? null : _exportCsv,
          ),
          _SectionHeader(title: 'IMPORT'),
          ListTile(
            leading: const Icon(Icons.file_upload),
            title: const Text('Import from JSON'),
            subtitle: const Text('Restore from a previous export'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _isImporting ? null : _importJson,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
