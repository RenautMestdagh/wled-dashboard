import 'package:material_ui/material_ui.dart';

import '../data/api_client.dart';
import '../data/models.dart';
import '../l10n/app_localizations.dart';
import '../widgets/feedback.dart';
import '../widgets/scope.dart';
import 'preset_editor_screen.dart';

class PresetsView extends StatelessWidget {
  const PresetsView({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final store = context.store;
    if (!store.isConnected) return const NotConnectedView();
    if (store.presets.isEmpty) {
      return loadStateView(context, loading: store.loading, error: store.error, retry: store.refresh) ??
          MessageView(icon: Icons.palette_outlined, title: s.noPresetsTitle, message: s.noPresetsMessage);
    }

    return RefreshIndicator(
      onRefresh: store.refresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        itemCount: store.presets.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) => _PresetCard(preset: store.presets[index]),
      ),
    );
  }
}

class _PresetCard extends StatefulWidget {
  const _PresetCard({required this.preset});

  final Preset preset;

  @override
  State<_PresetCard> createState() => _PresetCardState();
}

class _PresetCardState extends State<_PresetCard> {
  bool _applying = false;

  Future<void> _apply() async {
    final s = S.of(context);
    setState(() => _applying = true);
    try {
      final failed = await context.store.applyPreset(widget.preset.id);
      if (!mounted) return;
      showMessage(
        context,
        failed.isEmpty ? s.presetApplied(widget.preset.name) : s.devicesDidNotAnswer(failed.join(', ')),
      );
    } on ApiException catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 16, right: 8),
        title: Text(widget.preset.name),
        subtitle: Text(s.deviceCount(widget.preset.deviceCount)),
        onTap: () => openPresetEditor(context, widget.preset),
        trailing: FilledButton.tonalIcon(
          onPressed: _applying ? null : _apply,
          icon: _applying
              ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.play_arrow),
          label: Text(s.apply),
        ),
      ),
    );
  }
}
