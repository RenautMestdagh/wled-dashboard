import 'package:flutter/material.dart';
import '../models/preset.dart';

class PresetCard extends StatelessWidget {
  final Preset preset;
  final VoidCallback onApply;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final GlobalKey _moreButtonKey = GlobalKey();

  PresetCard({
    super.key,
    required this.preset,
    required this.onApply,
    required this.onEdit,
    required this.onDelete,
  });

  Future<void> _showOptionsMenu(BuildContext context) async {
    final renderBox = _moreButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    const menuWidth = 180.0;

    final result = await showMenu<String>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      position: RelativeRect.fromLTRB(
        offset.dx - menuWidth + renderBox.size.width,
        offset.dy + renderBox.size.height,
        offset.dx + renderBox.size.width,
        offset.dy,
      ),
      items: [
        const PopupMenuItem(
          value: 'edit',
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16),
            leading: Icon(Icons.edit, size: 22),
            title: Text('Edit Preset'),
            dense: true,
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16),
            leading: Icon(Icons.delete, size: 22, color: Colors.red),
            title: Text('Delete Preset', style: TextStyle(color: Colors.red)),
            dense: true,
          ),
        ),
      ],
      elevation: 4,
    );

    if (result == 'edit') {
      onEdit();
    } else if (result == 'delete') {
      onDelete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 0.5,
      // Reduced elevation for subtlety
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: theme.dividerColor.withAlpha(77), width: 1), // Subtle border
      ),
      color: theme.cardColor.withAlpha(179),
      // Subtle background
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        preset.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    key: _moreButtonKey,
                    icon: const Icon(Icons.more_vert, size: 20),
                    onPressed: () => _showOptionsMenu(context),
                    tooltip: 'More options',
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${preset.instanceCount} ${preset.instanceCount == 1 ? 'instance' : 'instances'}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  // Apply button moved to bottom right
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: OutlinedButton.icon(
                      onPressed: onApply,
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text('Apply'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        textStyle: const TextStyle(fontSize: 12),
                        side: BorderSide(color: theme.colorScheme.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
