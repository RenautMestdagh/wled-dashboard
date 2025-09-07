import 'package:flutter/material.dart';
import 'package:frontend/screens/presets_edit_screen.dart';
import 'package:provider/provider.dart';
import '../models/preset.dart';
import '../services/api_service.dart';
import '../widgets/preset_card.dart';

class PresetsScreen extends StatelessWidget {
  final List<Preset> presets;

  const PresetsScreen({super.key, required this.presets});

  Future<void> _confirmDelete(BuildContext context, Preset preset) async {
    final apiService = Provider.of<ApiService>(context, listen: false);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Preset'),
        content: Text('Are you sure you want to delete "${preset.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await apiService.deletePreset(preset.id);
    }
  }

  void _navigateToEditPreset(BuildContext context, Preset preset) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PresetEditScreen(preset: preset),
      ),
    );
  }

  void _navigateToAddPreset(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PresetEditScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: apiService.fetchPresets,
        child: Stack(
          children: [
            ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: presets.length,
              itemBuilder: (context, index) {
                return PresetCard(
                  preset: presets[index],
                  onApply: () => apiService.applyPreset(presets[index].id),
                  onEdit: () => _navigateToEditPreset(context, presets[index]),
                  onDelete: () => _confirmDelete(context, presets[index]),
                );
              },
            ),
            if(presets.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.collections_bookmark_outlined, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'No presets yet',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create presets to quickly apply configurations to multiple devices',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _navigateToAddPreset(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Create Preset'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              )
          ],
        ),
      ),
      floatingActionButton: presets.isNotEmpty
          ? FloatingActionButton(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        onPressed: () => _navigateToAddPreset(context),
        child: const Icon(Icons.add),
      )
          : null,
    );
  }
}
