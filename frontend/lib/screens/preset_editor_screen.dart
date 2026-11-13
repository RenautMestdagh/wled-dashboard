import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../data/api_client.dart';
import '../data/models.dart';
import '../data/store.dart';
import '../l10n/app_localizations.dart';
import '../widgets/feedback.dart';
import '../widgets/readable_width.dart';
import '../widgets/scope.dart';

Future<void> openPresetEditor(BuildContext context, [Preset? preset]) =>
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => PresetEditorScreen(preset: preset)));

enum _Mode { wledPreset, currentState, savedState }

/// What the preset will do on one device while it is being edited.
class _Choice {
  _Mode mode = _Mode.currentState;
  int? number;
  Json? savedState;
}

class PresetEditorScreen extends StatefulWidget {
  const PresetEditorScreen({super.key, this.preset});

  final Preset? preset;

  @override
  State<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends State<PresetEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.preset?.name);

  /// By device id, only for the devices in the preset.
  final _choices = <int, _Choice>{};
  final _devicePresets = <int, Future<List<DevicePreset>>>{};
  bool _loading = false;
  ApiException? _loadError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.preset != null) unawaited(_load());
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final detail = await Scope.read<Store>(context).api.preset(widget.preset!.id);
      for (final MapEntry(key: id, value: target) in detail.targets.entries) {
        _choices[id] = switch (target) {
          WledPreset(:final number) =>
            _Choice()
              ..mode = _Mode.wledPreset
              ..number = number,
          SavedState(:final state) =>
            _Choice()
              ..mode = _Mode.savedState
              ..savedState = state,
        };
      }
    } on ApiException catch (e) {
      _loadError = e;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<List<DevicePreset>> _presetsOf(int id) =>
      _devicePresets.putIfAbsent(id, () => Scope.read<Store>(context).api.devicePresets(id));

  Future<void> _save() async {
    final s = S.of(context);
    if (!_formKey.currentState!.validate()) return;
    if (_choices.values.any((choice) => choice.mode == _Mode.wledPreset && choice.number == null)) {
      showMessage(context, s.choosePreset);
      return;
    }

    setState(() => _saving = true);
    final store = context.store;
    try {
      final targets = <int, DeviceTarget>{
        for (final MapEntry(key: id, value: choice) in _choices.entries)
          id: switch (choice.mode) {
            _Mode.wledPreset => WledPreset(choice.number!),
            _Mode.savedState => SavedState(choice.savedState!),
            _Mode.currentState => SavedState(await store.api.deviceState(id)),
          },
      };
      await store.savePreset(widget.preset?.id, _name.text.trim(), targets);
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final s = S.of(context);
    final store = context.store;
    final confirmed = await confirm(
      context,
      title: s.deletePresetTitle,
      message: s.deletePresetMessage(widget.preset!.name),
      action: s.delete,
    );
    if (!confirmed) return;
    try {
      await store.deletePreset(widget.preset!.id);
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final instances = context.store.instances;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.preset == null ? s.newPreset : s.editPreset),
        actions: [
          if (widget.preset != null)
            IconButton(tooltip: s.delete, icon: const Icon(Icons.delete_outline), onPressed: _delete),
          TextButton(onPressed: _saving || _loading || _loadError != null ? null : _save, child: Text(s.save)),
        ],
      ),
      body: SafeArea(
        child: switch ((_loading, _loadError)) {
          (true, _) => const Center(child: CircularProgressIndicator()),
          (_, final error?) => MessageView(
            icon: Icons.cloud_off,
            title: s.loadFailed,
            message: errorText(s, error),
            action: FilledButton.tonal(onPressed: _load, child: Text(s.retry)),
          ),
          _ => ReadableWidth(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_saving) const LinearProgressIndicator(),
                  TextFormField(
                    controller: _name,
                    decoration: InputDecoration(labelText: s.name),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (value) => value == null || value.trim().isEmpty ? s.nameRequired : null,
                  ),
                  const SizedBox(height: 24),
                  Text(s.devices, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (instances.isEmpty) Text(s.noDevicesMessage),
                  for (final instance in instances) ...[_deviceCard(instance), const SizedBox(height: 8)],
                ],
              ),
            ),
          ),
        },
      ),
    );
  }

  Widget _deviceCard(Instance instance) {
    final s = S.of(context);
    final choice = _choices[instance.id];

    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: Text(instance.label),
            value: choice != null,
            onChanged: (included) => setState(() {
              if (included) {
                _choices[instance.id] = _Choice();
              } else {
                _choices.remove(instance.id);
              }
            }),
          ),
          if (choice != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<_Mode>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(value: _Mode.wledPreset, label: Text(s.wledPreset)),
                      ButtonSegment(value: _Mode.currentState, label: Text(s.currentState)),
                      if (choice.savedState != null) ButtonSegment(value: _Mode.savedState, label: Text(s.savedState)),
                    ],
                    selected: {choice.mode},
                    onSelectionChanged: (selected) => setState(() => choice.mode = selected.single),
                  ),
                  const SizedBox(height: 12),
                  switch (choice.mode) {
                    _Mode.wledPreset => _devicePresetField(instance.id, choice),
                    _Mode.currentState => Text(s.currentStateHelp),
                    _Mode.savedState => Text(s.savedStateHelp),
                  },
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _devicePresetField(int id, _Choice choice) {
    final s = S.of(context);
    return FutureBuilder(
      future: _presetsOf(id),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Text(s.errorDevice, style: TextStyle(color: Theme.of(context).colorScheme.error));
        final presets = snapshot.data;
        if (presets == null) return const LinearProgressIndicator();
        if (presets.isEmpty) return Text(s.noDevicePresets);
        return DropdownButtonFormField<int>(
          initialValue: presets.any((preset) => preset.number == choice.number) ? choice.number : null,
          decoration: InputDecoration(labelText: s.wledPreset),
          isExpanded: true,
          items: [for (final preset in presets) DropdownMenuItem(value: preset.number, child: Text(preset.name))],
          onChanged: (number) => setState(() => choice.number = number),
        );
      },
    );
  }
}
