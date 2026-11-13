import 'package:material_ui/material_ui.dart';

import '../data/api_client.dart';
import '../l10n/app_localizations.dart';
import '../widgets/feedback.dart';
import '../widgets/readable_width.dart';

class ReorderScreen<T> extends StatefulWidget {
  const ReorderScreen({super.key, required this.title, required this.items, required this.label, required this.onSave});

  final String title;
  final List<T> items;
  final String Function(T item) label;
  final Future<void> Function(List<T> ordered) onSave;

  @override
  State<ReorderScreen<T>> createState() => _ReorderScreenState<T>();
}

class _ReorderScreenState<T> extends State<ReorderScreen<T>> {
  late final _items = [...widget.items];
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onSave(_items);
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [TextButton(onPressed: _saving ? null : _save, child: Text(s.save))],
      ),
      body: SafeArea(
        child: ReadableWidth(
          child: ReorderableListView(
            padding: const EdgeInsets.all(16),
            onReorderItem: (from, to) => setState(() => _items.insert(to, _items.removeAt(from))),
            children: [
              for (final item in _items)
                Card(
                  key: ObjectKey(item),
                  child: ListTile(title: Text(widget.label(item))),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
