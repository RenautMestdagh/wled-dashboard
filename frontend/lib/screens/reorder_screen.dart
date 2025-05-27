import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/instance.dart';
import '../models/preset.dart';
import '../services/api_service.dart';

class ReorderScreen extends StatefulWidget {
  final bool isInstances; // Determines if reordering instances or presets
  final List<dynamic> items; // List of WLEDInstance or Preset

  const ReorderScreen({
    super.key,
    required this.isInstances,
    required this.items,
  });

  @override
  State<ReorderScreen> createState() => _ReorderScreenState();
}

class _ReorderScreenState extends State<ReorderScreen> {
  late List<dynamic> _orderedItems;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Create a copy of the items to allow reordering without modifying the original
    _orderedItems = List.from(widget.items);
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _orderedItems.removeAt(oldIndex);
      _orderedItems.insert(newIndex, item);
    });
  }

  Future<void> _saveOrder() async {
    setState(() {
      _isSaving = true;
    });

    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final ids = _orderedItems.map((item) => item.id as int).toList();
      if (widget.isInstances) {
        await apiService.reorderInstances(ids);
        apiService.setSuccessMessage('Instances reordered successfully');
      } else {
        await apiService.reorderPresets(ids);
        apiService.setSuccessMessage('Presets reordered successfully');
      }
    } catch (e) {
      apiService.setErrorMessage('Failed to reorder ${widget.isInstances ? 'instances' : 'presets'}');
    } finally {
      setState(() {
        _isSaving = false;
      });
      // Pop back to previous screen after saving
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Reorder ${widget.isInstances ? 'Instances' : 'Presets'}'),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _saveOrder,
                  child: Text(
                    'Save',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
        ],
      ),
      body: ReorderableListView(
        padding: const EdgeInsets.all(16.0),
        physics: const ClampingScrollPhysics(),
        onReorder: _onReorder,
        children: _orderedItems.asMap().entries.map((entry) {
          final item = entry.value;
          final name = widget.isInstances ? (item as WLEDInstance).name : (item as Preset).name;

          return Card(
            key: ValueKey(item.id),
            elevation: 5,
            margin: const EdgeInsets.symmetric(vertical: 5.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 2),
              child: ListTile(
                trailing: kIsWeb ? null : const Icon(Icons.drag_handle),
                title: Text(
                  name.isNotEmpty ? name : (widget.isInstances ? 'Instance ${item.id}' : 'Preset ${item.id}'),
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
